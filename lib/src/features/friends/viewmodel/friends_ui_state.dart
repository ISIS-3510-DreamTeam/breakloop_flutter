import '../model/friend_model.dart';

class FriendsUiState {
  // Code the user shares so others can add them
  final String? myFriendCode;

  // Friends of the user
  final List<FriendModel> friends;

  // When the friends list was last downloaded ("updated X ago")
  final DateTime? lastUpdated;

  // Codes added while offline that will be sent when the connection comes back
  final List<String> pendingCodes;

  // Indicates if the device has no connection
  final bool isOffline;

  // Indicates if friends are being loaded or added
  final bool isLoading;

  // Stores an error message if something goes wrong
  final String? errorMessage;

  const FriendsUiState({
    this.myFriendCode,
    this.friends = const [],
    this.lastUpdated,
    this.pendingCodes = const [],
    this.isOffline = false,
    this.isLoading = false,
    this.errorMessage,
  });

  // Creates a new state while keeping the values that were not changed
  FriendsUiState copyWith({
    String? myFriendCode,
    List<FriendModel>? friends,
    DateTime? lastUpdated,
    List<String>? pendingCodes,
    bool? isOffline,
    bool? isLoading,
    String? errorMessage,
  }) {
    return FriendsUiState(
      myFriendCode: myFriendCode ?? this.myFriendCode,
      friends: friends ?? this.friends,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      pendingCodes: pendingCodes ?? this.pendingCodes,
      isOffline: isOffline ?? this.isOffline,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }
}
