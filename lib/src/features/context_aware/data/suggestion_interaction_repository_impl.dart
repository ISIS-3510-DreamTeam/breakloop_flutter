import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../model/context_snapshot.dart';
import '../model/place_label.dart';
import '../model/recommendation.dart';
import '../model/suggestion_interaction.dart';
import 'suggestion_interaction_remote_data_source.dart';
import 'suggestion_interaction_repository.dart';

//Stores the interactions on the device as a list of JSON strings (local first) and sends them to the backend.
//Same logic as SuggestionInteractionRepositoryImpl in the Kotlin app
class SuggestionInteractionRepositoryImpl implements SuggestionInteractionRepository {
  static const _keyInteractions = 'suggestion_interactions';

  final SuggestionInteractionRemoteDataSource _remote;

  SuggestionInteractionRepositoryImpl({SuggestionInteractionRemoteDataSource? remote})
      : _remote = remote ?? SuggestionInteractionRemoteDataSource();

  @override
  Future<String> openInteraction(ContextSnapshot context, PlaceLabel? placeLabel) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final id = DateTime.now().microsecondsSinceEpoch.toString();
    final interactions = await _read();
    interactions.add(SuggestionInteraction(
      id: id,
      openedAt: now,
      closedAt: null,
      partOfDay: context.partOfDay,
      isWeekend: context.isWeekend,
      weather: context.weather?.name,
      placeLabel: placeLabel,
      shownSuggestions: const [],
      outcome: InteractionOutcome.pending,
      acceptedActivityId: null,
      chosenActivityId: null,
      updatedAt: now,
    ));
    await _write(interactions);
    unawaited(syncUnsynced());
    return id;
  }

  @override
  Future<void> addShownSuggestion(String id, Recommendation suggestion, int availableMin) async {
    await _update(id, (interaction) {
      final shown = interaction.shownSuggestions;
      //The same suggestion for the same time is not added twice
      final last = shown.isEmpty ? null : shown.last;
      if (last != null && last.activityId == suggestion.activity.id && last.availableMin == availableMin) {
        return null;
      }
      final now = DateTime.now().millisecondsSinceEpoch;
      return interaction.copyWith(
        shownSuggestions: [
          ...shown,
          ShownSuggestion(
            activityId: suggestion.activity.id,
            category: suggestion.activity.category,
            availableMin: availableMin,
            score: suggestion.score,
            reasons: suggestion.reasons,
            shownAt: now,
          ),
        ],
        updatedAt: now,
      );
    });
  }

  @override
  Future<void> closeInteraction(
    String id, {
    required InteractionOutcome outcome,
    String? acceptedActivityId,
    String? chosenActivityId,
  }) async {
    await _update(id, (interaction) {
      //If the activity chosen from the list was also suggested, it counts as accepted
      final wasShown = chosenActivityId != null &&
          interaction.shownSuggestions.any((shown) => shown.activityId == chosenActivityId);
      final now = DateTime.now().millisecondsSinceEpoch;
      return interaction.copyWith(
        outcome: wasShown ? InteractionOutcome.accepted : outcome,
        acceptedActivityId: wasShown ? chosenActivityId : acceptedActivityId,
        chosenActivityId: wasShown ? null : chosenActivityId,
        closedAt: now,
        updatedAt: now,
      );
    });
  }

  @override
  Future<void> updatePlace(String id, PlaceLabel? placeLabel) async {
    await _update(id, (interaction) {
      return interaction.copyWith(
        placeLabel: placeLabel,
        clearPlace: placeLabel == null,
        updatedAt: DateTime.now().millisecondsSinceEpoch,
      );
    });
  }

  @override
  Future<void> syncUnsynced() async {
    final pending = (await _read()).where((interaction) => !interaction.synced).toList();
    if (pending.isEmpty) return;

    try {
      if (!await _remote.upload(pending)) return;
    } catch (e) {
      debugPrint('[SuggestionInteractionRepository] sync failed, will retry later: $e');
      return;
    }

    //An interaction that changed while it was being uploaded stays pending (same check as the Kotlin DAO)
    final uploaded = {for (final interaction in pending) interaction.id: interaction.updatedAt};
    final interactions = await _read();
    await _write([
      for (final interaction in interactions)
        uploaded[interaction.id] == interaction.updatedAt ? interaction.copyWith(synced: true) : interaction,
    ]);
    debugPrint('[SuggestionInteractionRepository] synced ${pending.length} interactions');
  }

  //Changes an interaction that is still pending. change returns null to leave it as it is
  Future<void> _update(String id, SuggestionInteraction? Function(SuggestionInteraction) change) async {
    final interactions = await _read();
    final index = interactions.indexWhere((interaction) => interaction.id == id);
    if (index == -1 || interactions[index].outcome != InteractionOutcome.pending) return;

    final updated = change(interactions[index]);
    if (updated == null) return;
    interactions[index] = updated.copyWith(synced: false);
    await _write(interactions);
    unawaited(syncUnsynced());
  }

  Future<List<SuggestionInteraction>> _read() async {
    final prefs = await SharedPreferences.getInstance();
    final records = prefs.getStringList(_keyInteractions) ?? [];
    return [
      for (final record in records) SuggestionInteraction.fromJson(jsonDecode(record) as Map<String, dynamic>),
    ];
  }

  Future<void> _write(List<SuggestionInteraction> interactions) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_keyInteractions, [
      for (final interaction in interactions) jsonEncode(interaction.toJson()),
    ]);
  }
}
