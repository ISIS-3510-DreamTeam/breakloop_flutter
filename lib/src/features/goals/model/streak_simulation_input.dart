//We keep content in this file as primitive as possible as it is being passed through isolates

class StreakSimulationInput {

  // History of usage in minutes, without including today
  final List<int> minutes;

  //Mapping from days to numbers. i.e monday = 1, sunday = 7. For each element in minutes
  final List<int> weekdays;

  //Starting day for the simulation
  final int startWeekday;

  // Parameters for the simulation
  final int simulations;
  final int horizonDays;
  final int streakLength;
  final int minGoal;
  final int maxGoal;
  final int step;
  final double targetProbability;
  final double minSamplesPerWeekday;
  //TODO: Possible remove
  final int? seed;


  const StreakSimulationInput({
    required this.minutes,
    required this.weekdays,
    required this.startWeekday,
    this.simulations = 10000, //TODO: check if this is too high
    this.horizonDays = 30, // A month
    this.streakLength = 7, // A week
    this.minGoal = 15,
    this.maxGoal = 720,
    this.step = 15,
    this.targetProbability = 0.7,
    this.minSamplesPerWeekday = 2,
    this.seed
  });

}