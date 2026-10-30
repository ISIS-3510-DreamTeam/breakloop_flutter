import '../model/context_snapshot.dart';
import '../model/place_label.dart';
import '../model/recommendation.dart';
import '../model/suggestion_interaction.dart';

//Visits to the Offline view with the suggestions shown and what the user chose (data of BQ12)
abstract interface class SuggestionInteractionRepository {
  //Starts a pending interaction and returns its id
  Future<String> openInteraction(ContextSnapshot context, PlaceLabel? placeLabel);

  Future<void> addShownSuggestion(String id, Recommendation suggestion, int availableMin);

  //Ends the interaction when the user starts an activity
  Future<void> closeInteraction(
    String id, {
    required InteractionOutcome outcome,
    String? acceptedActivityId,
    String? chosenActivityId,
  });

  Future<void> updatePlace(String id, PlaceLabel? placeLabel);

  //Sends the interactions that the backend does not have yet. If it fails they stay queued for the next try
  Future<void> syncUnsynced();
}
