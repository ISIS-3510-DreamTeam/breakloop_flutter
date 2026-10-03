import '../model/activity_category.dart';
import '../model/offline_activity.dart';
import '../model/recommendation.dart';

sealed class OfflineUiState {
  const OfflineUiState();
}

class OfflineLoading extends OfflineUiState {
  const OfflineLoading();
}

class OfflineContent extends OfflineUiState {
  //Null when no activity fits in the available time
  final Recommendation? suggestion;
  final int availableMin;
  final bool isWeatherAvailable;
  //Activities of the selected category, or all of them
  final List<OfflineActivity> activities;
  //Null means "All"
  final ActivityCategory? selectedCategory;

  const OfflineContent({
    required this.suggestion,
    required this.availableMin,
    required this.isWeatherAvailable,
    required this.activities,
    required this.selectedCategory,
  });
}
