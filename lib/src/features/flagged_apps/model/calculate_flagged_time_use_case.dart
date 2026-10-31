import 'flagged_app.dart';

//Time spent today in the flagged apps
class CalculateFlaggedTimeUseCase {
  const CalculateFlaggedTimeUseCase();

  //usageByPackage: milliseconds in the foreground of each app
  int getFlaggedAppTime(Map<String, int> usageByPackage, List<FlaggedApp> flagged) {
    var flaggedTime = 0;
    for (final app in flagged) {
      flaggedTime += usageByPackage[app.packageName] ?? 0;
    }
    return flaggedTime;
  }
}
