import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../data/friends_repository.dart';
import '../model/friend_model.dart';
import 'friends_ui_state.dart';

class FriendsViewModel extends ChangeNotifier {
  // Handles the user's profile and friends
  final FriendsRepository _repository;

  // Handles the current authenticated user
  final FirebaseAuth _auth;

  // Stores the current state of the friends screen
  FriendsUiState _state = const FriendsUiState();

  // Provides the current state to the View
  FriendsUiState get state => _state;

  FriendsViewModel({
    FriendsRepository? repository,
    FirebaseAuth? auth,
  })  : _repository = repository ?? FriendsRepository(),
        _auth = auth ?? FirebaseAuth.instance;

  // Loads the user's friend code and friends list
  Future<void> loadFriends() async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      _state = _state.copyWith(
        errorMessage: 'Debes iniciar sesión para ver a tus amigos',
      );
      notifyListeners();
      return;
    }

    _state = _state.copyWith(isLoading: true);
    notifyListeners();

    try {
      // Make sure the user has a profile with a friend code
      final profile = await _repository.ensureProfile(
        uid: currentUser.uid,
        email: currentUser.email ?? '',
      );
      final friends = await _repository.getFriends(currentUser.uid);

      _state = _state.copyWith(
        myFriendCode: profile.friendCode,
        friends: friends,
        isLoading: false,
      );
    } catch (e) {
      _state = _state.copyWith(
        isLoading: false,
        errorMessage: 'No se pudieron cargar tus amigos',
      );
    }
    notifyListeners();
  }

  // Adds a friend using the code they shared
  Future<void> addFriend(String code) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      _state = _state.copyWith(
        errorMessage: 'Debes iniciar sesión para agregar amigos',
      );
      notifyListeners();
      return;
    }

    // Check that the user typed a code
    if (code.trim().isEmpty) {
      _state = _state.copyWith(errorMessage: 'Ingresa un código');
      notifyListeners();
      return;
    }

    _state = _state.copyWith(isLoading: true);
    notifyListeners();

    try {
      final result = await _repository.addFriendByCode(
        uid: currentUser.uid,
        code: code,
      );

      switch (result) {
        case AddFriendResult.added:
          // Reload the list so the new friend appears
          await loadFriends();
          return;
        case AddFriendResult.notFound:
          _state = _state.copyWith(
            isLoading: false,
            errorMessage: 'No existe un usuario con ese código',
          );
        case AddFriendResult.ownCode:
          _state = _state.copyWith(
            isLoading: false,
            errorMessage: 'No puedes agregarte a ti mismo',
          );
      }
    } catch (e) {
      _state = _state.copyWith(
        isLoading: false,
        errorMessage: 'No se pudo agregar al amigo',
      );
    }
    notifyListeners();
  }
}
