import '../model/context_snapshot.dart';

abstract interface class ContextProvider {
  Future<ContextSnapshot> getSnapshot(int availableMin);
}
