import 'dart:async';

import 'package:flutter/foundation.dart';

import '../data/flagged_apps_repository.dart';
import '../model/flagged_app.dart';
import '../model/installed_app.dart';
import 'flagged_apps_ui_state.dart';

//Shared by the flagged apps screen and the card in Stats
class FlaggedAppsViewModel extends ChangeNotifier {
  final FlaggedAppsRepository _repository;

  //Null while the installed apps are loading
  List<InstalledApp>? _installedApps;
  List<FlaggedApp> _flagged = [];
  String? _editingPackage;
  //Apps flagged when the screen was opened. They stay on top so the list does not jump when the user flags or unflags
  Set<String>? _pinnedPackages;
  StreamSubscription<List<FlaggedApp>>? _flaggedSubscription;

  FlaggedAppsViewModel(this._repository) {
    _flaggedSubscription = _repository.watchFlaggedApps().listen((flagged) {
      _flagged = flagged;
      notifyListeners();
    });
    _load();
  }

  Future<void> _load() async {
    _flagged = await _repository.getFlaggedApps();
    notifyListeners();

    final installed = await _repository.getInstalledApps();
    _installedApps = installed;
    notifyListeners();

    //Forget the apps that were uninstalled
    await _repository.deleteUninstalledApps({for (final app in installed) app.packageName});
  }

  //Rows of the flagged apps screen: flagged apps first, then the rest, both by name
  FlaggedAppsUiState get uiState {
    final installed = _installedApps;
    if (installed == null) return const FlaggedAppsLoading();
    if (installed.isEmpty) return const FlaggedAppsEmpty();

    final flaggedByPackage = {for (final app in _flagged) app.packageName: app};
    final pinned = _pinnedPackages ??= flaggedByPackage.keys.toSet();
    final rows = [
      for (final app in installed) FlaggedAppRow(app: app, flagged: flaggedByPackage[app.packageName]),
    ];
    //installed is already sorted by name, so each group keeps that order
    final sortedRows = [
      ...rows.where((row) => pinned.contains(row.app.packageName)),
      ...rows.where((row) => !pinned.contains(row.app.packageName)),
    ];
    final editing = sortedRows.where((row) => row.app.packageName == _editingPackage).firstOrNull;
    return FlaggedAppsContent(rows: sortedRows, editing: editing);
  }

  //Flagged apps for the Stats card, or null while loading
  List<FlaggedAppRow>? get flaggedRows {
    final installed = _installedApps;
    if (installed == null) return null;
    final flaggedByPackage = {for (final app in _flagged) app.packageName: app};
    return [
      for (final app in installed)
        if (flaggedByPackage.containsKey(app.packageName)) FlaggedAppRow(app: app, flagged: flaggedByPackage[app.packageName]),
    ];
  }

  Future<Uint8List?> loadIcon(String packageName, int sizePx) => _repository.getAppIcon(packageName, sizePx);

  //The order of the list is decided again every time the screen is opened
  void onScreenOpened() {
    _pinnedPackages = null;
    _editingPackage = null;
  }

  Future<void> onCheckboxClick(FlaggedAppRow row) async {
    if (row.flagged != null) {
      await _repository.deleteFlaggedApp(row.app.packageName);
    } else {
      await _repository.addFlaggedApp(row.app.packageName, null);
      //When flagging, open the sheet to choose the limit right away
      _editingPackage = row.app.packageName;
      notifyListeners();
    }
  }

  void onEditClick(FlaggedAppRow row) {
    _editingPackage = row.app.packageName;
    notifyListeners();
  }

  void onDismissEdit() {
    _editingPackage = null;
    notifyListeners();
  }

  Future<void> onLimitSave(int hours, int minutes, bool noLimit) async {
    final packageName = _editingPackage;
    if (packageName == null) return;

    final total = hours * 60 + minutes;
    final limit = noLimit || total == 0 ? null : total;
    _editingPackage = null;
    await _repository.changeFlaggedAppLimit(packageName, limit);
  }

  @override
  void dispose() {
    _flaggedSubscription?.cancel();
    super.dispose();
  }
}
