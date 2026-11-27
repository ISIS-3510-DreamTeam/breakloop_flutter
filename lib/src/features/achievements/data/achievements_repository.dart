import 'dart:convert';
import 'dart:isolate';

import 'package:flutter/foundation.dart';

import '../model/achievement.dart';
import '../model/achievement_progress.dart';
import '../model/evaluate_achievements.dart';
import '../model/evaluation_input.dart';
import 'achievements_catalog_api.dart';
import 'achievements_catalog_store.dart';
import 'achievements_local_datasource.dart';
import 'achievements_remote_datasource.dart';

class AchievementsRepository {
  AchievementsRepository({
    required this._api,
    required this._store,
    required this._local,
    required this._remote,
  });

  final AchievementsCatalogApi _api;
  final AchievementsCatalogStore _store;
  final AchievementsLocalDatasource _local;
  final AchievementsRemoteDatasource _remote;

  bool _syncing = false;

  // Network first. If it fails, the last saved catalog is used and fromCache is true.
  Future<({List<Achievement> catalog, bool fromCache})> loadCatalog() async {
    try {
      final body = await _api.fetchCatalogJson();
      await _store.save(body);
      return (catalog: _parse(body), fromCache: false);
    } catch (_) {
      final cached = await _store.read();
      if (cached == null) rethrow;
      return (catalog: _parse(cached), fromCache: true);
    }
  }

  // Evaluates the rules in a separate isolate, stores the new unlocks,
  // uploads the pending ones and merges the cloud copy.
  Future<List<AchievementProgress>> evaluate({
    required String uid,
    required List<Achievement> catalog,
    required EvaluationInput input,
  }) async {
    // Only local variables are used inside the closure, so the isolate gets plain data.
    final evaluated = await Isolate.run(() => evaluateAchievements(catalog, input));

    final now = DateTime.now().millisecondsSinceEpoch;
    final newUnlocks = {
      for (final progress in evaluated)
        if (progress.unlocked) progress.achievement.id: now,
    };
    await _local.insertUnlocks(uid, newUnlocks);

    await syncPending(uid);
    await _pullFromCloud(uid);

    final stored = await _local.getUnlocks(uid);
    return [
      for (final progress in evaluated)
        progress.withUnlockedAt(
          stored[progress.achievement.id] == null
              ? null
              : DateTime.fromMillisecondsSinceEpoch(
              stored[progress.achievement.id]!),
        ),
    ];
  }

  // Uploads the pending unlocks. A failure leaves them pending for the next try.
  Future<void> syncPending(String uid) async {
    if (_syncing) return;
    _syncing = true;
    try {
      final pending = await _local.getPendingUnlocks(uid);
      for (final entry in pending.entries) {
        await _remote.unlock(achievementId: entry.key, unlockedAt: entry.value);
        await _local.markSynced(uid, entry.key);
      }
    } catch (e) {
      debugPrint('[AchievementsRepository] sync postponed: $e');
    } finally {
      _syncing = false;
    }
  }

  // Cloud first. If the cloud delete fails, the local copy is kept and the error reaches the caller.
  // Developer tools only.
  Future<void> deleteUnlocks(String uid) async {
    await _remote.deleteAll();
    await _local.deleteUnlocks(uid);
  }

  Future<void> _pullFromCloud(String uid) async {
    try {
      final remote = await _remote.fetchUnlocks();
      await _local.mergeRemoteUnlocks(uid, remote);
    } catch (e) {
      debugPrint('[AchievementsRepository] pull postponed: $e');
    }
  }

  List<Achievement> _parse(String body) {
    final list = jsonDecode(body) as List<dynamic>;
    return [
      for (final item in list)
        Achievement.fromJson(item as Map<String, dynamic>),
    ];
  }
}