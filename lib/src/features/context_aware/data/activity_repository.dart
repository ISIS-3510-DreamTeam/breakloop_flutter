import '../model/offline_activity.dart';

//Source of the offline activities catalog
abstract interface class ActivityRepository {
  Future<List<OfflineActivity>> getCatalog();

  Future<OfflineActivity?> getActivity(String id);
}
