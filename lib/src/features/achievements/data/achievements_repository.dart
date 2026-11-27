import 'dart:convert';
import 'dart:isolate';

import '../model/achievement.dart';
import '../model/achievement_progress.dart';
import '../model/evaluate_achievements.dart';
import '../model/evaluation_input.dart';
import 'achievements_catalog_api.dart';
import 'achievements_catalog_store.dart';
import 'achievements_local_datasource.dart';

class AchievementsRepository {
  AchievementsRepository({
    required this._api,
    required this._store,
    required this._local,
  });

  final AchievementsCatalogApi _api;
  final AchievementsCatalogStore _store;
  final AchievementsLocalDatasource _local;

  /// Network first. If it fails, the last saved catalog is used and fromCache is true.
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

  /// Evaluates the rules in a separate isolate and stores the new unlocks.
  Future<List<AchievementProgress>> evaluate({
    required String uid,
    required List<Achievement> catalog,
    required EvaluationInput input,
  }) async {
    // Only local variables are used inside the closure, so the isolate gets plain data.
    final evaluated =
    await Isolate.run(() => evaluateAchievements(catalog, input));

    final now = DateTime.now().millisecondsSinceEpoch;
    final newUnlocks = {
      for (final progress in evaluated)
        if (progress.unlocked) progress.achievement.id: now,
    };
    await _local.insertUnlocks(uid, newUnlocks);

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

  List<Achievement> _parse(String body) {
    final list = jsonDecode(body) as List<dynamic>;
    return [
      for (final item in list)
        Achievement.fromJson(item as Map<String, dynamic>),
    ];
  }
}