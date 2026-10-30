import '../model/flagged_app.dart';
import '../model/installed_app.dart';

//Installed app with its flag, or null if it is not flagged
class FlaggedAppRow {
  final InstalledApp app;
  final FlaggedApp? flagged;

  const FlaggedAppRow({required this.app, required this.flagged});
}

sealed class FlaggedAppsUiState {
  const FlaggedAppsUiState();
}

class FlaggedAppsLoading extends FlaggedAppsUiState {
  const FlaggedAppsLoading();
}

class FlaggedAppsEmpty extends FlaggedAppsUiState {
  const FlaggedAppsEmpty();
}

class FlaggedAppsContent extends FlaggedAppsUiState {
  final List<FlaggedAppRow> rows;
  //App whose daily limit is being edited, or null
  final FlaggedAppRow? editing;

  const FlaggedAppsContent({required this.rows, required this.editing});
}
