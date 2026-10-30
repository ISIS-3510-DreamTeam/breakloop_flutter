import 'dart:math';

import '../model/streak_simulation_input.dart';
import '../model/streak_simulation_result.dart';

//Function to be executed by an isolate
StreakSimulationResult runStreakSimulation(StreakSimulationInput input) {

  //We validate the integrity of the input
  assert(input.minutes.length == input.weekdays.length);

  // Return empty simulation if input is not valid
  if (input.minutes.isEmpty){
    return StreakSimulationResult.empty(
        minGoal: input.minGoal,
        maxGoal: input.maxGoal,
        step: input.step
    );
  }

  //TODO: Might delete later
  final rng = input.seed == null ? Random() : Random(input.seed);

  // Compute the simulation

  // 1. Group data by week day. For instance all data that we have for a monday is grouped as monday: [60, 90]
  final byWeekday = List<List<int>>.generate(8, (_) => <int>[]);
  for (var i = 0; i < input.minutes.length; i++){
    byWeekday[input.weekdays[i]].add(input.minutes[i]);
  }

  //2. If a day doesn't have enough samples, we use the whole history of minutes. This prevents the simulation getting stuck
  // with atypical data and gives a better approximation of what a day may be like.
  final pools = List<List<int>>.generate(
    8,
    (w) => byWeekday[w].length >= input.minSamplesPerWeekday ? byWeekday[w] : input.minutes
  );

  //3. we create pools for every future day
  final dayPools = List<List<int>>.generate(
    input.horizonDays,
    (d) => pools[(input.startWeekday - 1 + d) % 7 + 1]
  );

  final goalCount = (input.maxGoal - input.minGoal) ~/ input.step + 1;

  //4. Histogram[i] = simulations whose successful goal count is the goal i
  final histogram = List<int>.filled(goalCount, 0);
  final trajectory = List<int>.filled(input.horizonDays, 0);
  final lastStart = input.horizonDays - input.streakLength;

  //5. Create s simulations of 30 days
  for (var s = 0; s < input.simulations; s ++){
    for (var d = 0; d < input.horizonDays; d++){
      final pool = dayPools[d];
      //We select the minutes of each day based on the existing data.
      trajectory[d] = pool[rng.nextInt(pool.length)];
    }

    // 6. There is a 7 day streak if for 7 consecutive days the maximum use time is lower than a goal G.
    // For each window of 7 days we calculate the minimum G* to have a 7 day streak, every G>G* satisfies having a streak as well
    // Thus we calculate the window with the smallest G* out of all the trajectories

    var threshold = 1 << 30; // Very big number 2**30
    for (var start = 0; start <= lastStart; start++){
      var windowMax = 0;
      for (var k = 0; k < input.streakLength; k++) {
        final v = trajectory[start+k];
        if (v > windowMax){
          windowMax = v;
          if (windowMax >= threshold) break; //This window doesn't improve
        }
      }
      if (windowMax < threshold){
        threshold = windowMax;
      }
    }
    if (threshold > input.maxGoal) continue;

    final index = threshold <= input.minGoal
        ? 0
        : (threshold - input.minGoal -input.step - 1) ~/ input.step;

    histogram[index]++;
  }
  // 7. calculate probabilities: P(Goal) = cumulative success / simulations. We suggest the first one that satisfies
  //  .7 probability
  final probabilities = List<double>.filled(goalCount, 0);
  var cumulative = 0;
  int? suggested;
  for (var i = 0; i < goalCount; i++){
    cumulative += histogram[i];
    probabilities[i] = cumulative / input.simulations;
    if (suggested == null && probabilities[i] >= input.targetProbability) {
      suggested = input.minGoal + i * input.step;
    }
  }

  return StreakSimulationResult(
      minGoal: input.minGoal,
      step: input.step,
      probabilities: probabilities,
      simulations: input.simulations,
      suggestedGoalMinutes: suggested
  );
}