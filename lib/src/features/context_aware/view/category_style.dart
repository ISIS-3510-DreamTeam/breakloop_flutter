import '../model/activity_category.dart';

//Text and emoji used to show each category in the views
String categoryLabel(ActivityCategory category) {
  switch (category) {
    case ActivityCategory.move:
      return 'Move';
    case ActivityCategory.create:
      return 'Create';
    case ActivityCategory.relax:
      return 'Relax';
    case ActivityCategory.socialize:
      return 'Socialize';
  }
}

String categoryEmoji(ActivityCategory category) {
  switch (category) {
    case ActivityCategory.move:
      return '🏃';
    case ActivityCategory.create:
      return '🎨';
    case ActivityCategory.relax:
      return '☕';
    case ActivityCategory.socialize:
      return '👥';
  }
}
