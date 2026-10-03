//Part of the day used to match activities with the current moment.
//It is called PartOfDay (TimeOfDay in Kotlin) to avoid a clash with Flutter's TimeOfDay class
enum PartOfDay {
  morning,
  afternoon,
  evening,
  night;

  static PartOfDay fromHour(int hour) {
    if (hour >= 6 && hour <= 11) {
      return PartOfDay.morning;
    } else if (hour >= 12 && hour <= 17) {
      return PartOfDay.afternoon;
    } else if (hour >= 18 && hour <= 22) {
      return PartOfDay.evening;
    }
    return PartOfDay.night;
  }
}
