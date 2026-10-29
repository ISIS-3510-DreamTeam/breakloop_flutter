import 'package:shared_preferences/shared_preferences.dart';

import '../model/activity_category.dart';

//Activity categories the user is interested in. There is no onboarding step that saves them yet, so they are empty by default
class InterestsDataSource {
  static const _keyInterests = 'interests';

  Future<Set<ActivityCategory>> getInterests() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getStringList(_keyInterests) ?? [];
    //Unknown values are ignored
    return {
      for (final name in saved)
        for (final category in ActivityCategory.values)
          if (category.name == name) category,
    };
  }

  Future<void> saveInterests(Set<ActivityCategory> interests) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_keyInterests, [
      for (final category in interests) category.name,
    ]);
  }
}
