import '../model/friend_model.dart';

class FriendsUiState {
  // Code the user shares so others can add them
  final String? myFriendCode;

  // Friends of the user
  final List<FriendModel> friends;

  // Indicates if friends are being loaded or added
  final bool isLoading;

  // Stores an error message if something goes wrong
  final String? errorMessage;

  const FriendsUiState({
    this.myFriendCode,
    this.friends = const [],
    this.isLoading = false,
    this.errorMessage,
  });

  // Creates a new state while keeping the values that were not changed
  FriendsUiState copyWith({
    String? myFriendCode,
    List<FriendModel>? friends,
    bool? isLoading,
    String? errorMessage,
  }) {
    return FriendsUiState(
      myFriendCode: myFriendCode ?? this.myFriendCode,
      friends: friends ?? this.friends,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }
}
