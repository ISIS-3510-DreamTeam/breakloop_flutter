//We keep content in this file as primitive as possible as it is being passed through isolates
class StreakSimulationResult {

  final int minGoal;
  final int step;

  // probabilities[i] = P(7 day streak) for minGoal + i*step
  final List<double> probabilities;
  final int simulations;

  //Lowest possible goal with P >= threshold. Null if none reaches it.
  final int? suggestedGoalMinutes;

  bool get hasData => simulations > 0;

  const StreakSimulationResult({
    required this.minGoal,
    required this.step,
    required this.probabilities,
    required this.simulations,
    required this.suggestedGoalMinutes,
  });

  factory StreakSimulationResult.empty({
    required int minGoal,
    required int maxGoal,
    required int step,
  }) {
    final count = (maxGoal - minGoal) ~/ step + 1; // ~/ is the integer division operator
    return StreakSimulationResult(
      minGoal: minGoal,
      step: step,
      probabilities: List<double>.filled(count, 0),
      simulations: 0,
      suggestedGoalMinutes: null
    );
  }

  double probabilityFor(int goalMinutes) {
    final raw = ((goalMinutes - minGoal) / step).round();
    return probabilities[raw.clamp(0, probabilities.length - 1)];
  }

}