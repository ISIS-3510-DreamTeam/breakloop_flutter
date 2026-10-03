import 'dart:convert';

import 'package:flutter/services.dart';

import '../model/offline_activity.dart';

//Reads the catalog of offline activities bundled with the app
class ActivityCatalogDataSource {
  static const _catalogPath = 'assets/data/activities.json';

  Future<List<OfflineActivity>> loadBundledCatalog() async {
    final text = await rootBundle.loadString(_catalogPath);
    final raw = jsonDecode(text) as List;
    return [
      for (final item in raw) OfflineActivity.fromJson(item as Map<String, dynamic>),
    ];
  }
}
