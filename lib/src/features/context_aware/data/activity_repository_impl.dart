import '../model/offline_activity.dart';
import 'activity_catalog_data_source.dart';
import 'activity_repository.dart';

class ActivityRepositoryImpl implements ActivityRepository {
  final ActivityCatalogDataSource _catalogDataSource;

  //The catalog does not change while the app runs, so it is read only once
  List<OfflineActivity>? _cache;

  ActivityRepositoryImpl(this._catalogDataSource);

  @override
  Future<List<OfflineActivity>> getCatalog() async {
    _cache ??= await _catalogDataSource.loadBundledCatalog();
    return _cache!;
  }

  @override
  Future<OfflineActivity?> getActivity(String id) async {
    final catalog = await getCatalog();
    for (final activity in catalog) {
      if (activity.id == id) {
        return activity;
      }
    }
    return null;
  }
}
