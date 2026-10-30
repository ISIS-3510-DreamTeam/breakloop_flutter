import 'package:breakloop_flutter/src/features/goals/data/streak_simulator.dart';
import 'package:breakloop_flutter/src/features/goals/model/streak_simulation_input.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Constant data at 60 min: P=0 low 60, P=1 from 60', () {
    final r = runStreakSimulation(StreakSimulationInput(
      minutes: List.filled(28, 60),
      weekdays: List.generate(28, (i) => i % 7 + 1),
      startWeekday: DateTime.monday,
      simulations: 2000,
      seed: 42,
    ));
    expect(r.probabilityFor(45), 0);
    expect(r.probabilityFor(60), 1);
    expect(r.suggestedGoalMinutes, 60);
  });

  test('Probability not decreasing with goal', () {
    final r = runStreakSimulation(StreakSimulationInput(
      minutes: [30, 90, 150, 240, 60, 120, 200, 45, 100, 180],
      weekdays: [1, 2, 3, 4, 5, 6, 7, 1, 2, 3],
      startWeekday: DateTime.wednesday,
      simulations: 5000,
      seed: 7,
    ));
    for (var i = 1; i < r.probabilities.length; i++) {
      expect(r.probabilities[i], greaterThanOrEqualTo(r.probabilities[i - 1]));
    }
  });

  test('empty history', () {
    final r = runStreakSimulation(const StreakSimulationInput(
      minutes: [], weekdays: [], startWeekday: 1,
    ));
    expect(r.hasData, false);
    expect(r.suggestedGoalMinutes, isNull);
  });
}