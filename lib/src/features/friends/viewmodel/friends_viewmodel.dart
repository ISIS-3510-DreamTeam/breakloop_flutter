import 'dart:async';
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

  // Listens for connection changes to sync when the network comes back
  StreamSubscription<bool>? _connectionSubscription;

  // Listens for account changes so the screen never shows another user's data
  StreamSubscription<User?>? _authSubscription;
  String? _currentUid;

  FriendsViewModel({
    FriendsRepository? repository,
    FirebaseAuth? auth,
  })  : _repository = repository ?? FriendsRepository(),
        _auth = auth ?? FirebaseAuth.instance {
    _connectionSubscription =
        _repository.watchConnection().listen(_onConnectionChanged);
    // Emits the current user right away, so this also does the first load
    _authSubscription = _auth.authStateChanges().listen(_onUserChanged);
  }

  void _onUserChanged(User? user) {
    if (user?.uid == _currentUid) return;
    _currentUid = user?.uid;

    // Start from an empty screen for the new account
    _state = const FriendsUiState();
    notifyListeners();
    if (user != null) loadFriends();
  }

  void _onConnectionChanged(bool isOnline) {
    if (isOnline) {
      // Send the codes queued offline and refresh the list
      loadFriends(forceRefresh: true);
    } else {
      _state = _state.copyWith(isOffline: true);
      notifyListeners();
    }
  }

  // Loads the user's friend code and friends list.
  // Shows the saved list first and then updates it from Firestore.
  Future<void> loadFriends({bool forceRefresh = false}) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      _state = _state.copyWith(
        errorMessage: 'Log in to see your friends',
      );
      notifyListeners();
      return;
    }

    // Avoid running two loads at the same time
    if (_state.isLoading) return;

    final uid = currentUser.uid;
    _state = _state.copyWith(isLoading: true);
    notifyListeners();

    List<FriendModel>? storedFriends;
    String? errorMessage;

    try {
      // Show the last known list right away (memory first, then device)
      storedFriends = await _repository.getStoredFriends(uid);
      _state = _state.copyWith(
        friends: storedFriends,
        lastUpdated: _repository.lastUpdated(uid),
        pendingCodes: await _repository.getPendingCodes(uid),
      );
      notifyListeners();

      final isOnline = await _repository.isOnline();
      _state = _state.copyWith(isOffline: !isOnline);

      // The friend code is created online once and then read from the device
      final profile = await _repository.ensureProfile(
        uid: uid,
        email: currentUser.email ?? '',
      );
      _state = _state.copyWith(myFriendCode: profile?.friendCode);

      if (!isOnline) {
        // Without a saved list there is nothing to show, so explain why
        if (storedFriends == null) {
          errorMessage =
              "You're offline. Connect to the internet to see your friends";
        }
      } else if (forceRefresh || !_repository.isCacheFresh(uid)) {
        // Send the codes added while offline
        final invalidCodes = await _repository.syncPendingCodes(uid);
        if (invalidCodes.isNotEmpty) {
          errorMessage =
              "We couldn't add a friend with the code: ${invalidCodes.join(', ')}";
        }
        _state = _state.copyWith(
          pendingCodes: await _repository.getPendingCodes(uid),
        );

        // Download the updated list
        final friends = await _repository.refreshFriends(uid);
        _state = _state.copyWith(
          friends: friends,
          lastUpdated: _repository.lastUpdated(uid),
        );
      }
    } catch (e) {
      debugPrint('[FriendsViewModel] loadFriends failed: $e');
      errorMessage = storedFriends == null
          ? "We couldn't load your friends. Try again"
          : "We couldn't update your list. Showing the last saved one";
    } finally {
      // Always hide the loading state, even if something failed
      _state = _state.copyWith(isLoading: false, errorMessage: errorMessage);
      notifyListeners();
    }
  }

  // Adds a friend using the code they shared.
  // Without connection the code is queued and sent later.
  Future<void> addFriend(String code) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      _state = _state.copyWith(
        errorMessage: 'Log in to add friends',
      );
      notifyListeners();
      return;
    }

    // Codes are stored in uppercase
    final normalizedCode = code.trim().toUpperCase();

    // Check that the user typed a code
    if (normalizedCode.isEmpty) {
      _state = _state.copyWith(errorMessage: 'Enter a code');
      notifyListeners();
      return;
    }

    // The own code can be checked without connection
    if (normalizedCode == _state.myFriendCode) {
      _state = _state.copyWith(errorMessage: "You can't add yourself");
      notifyListeners();
      return;
    }

    if (_state.isLoading) return;

    // Without connection, keep the code and add the friend later
    if (!await _repository.isOnline()) {
      final pendingCodes = await _repository.queuePendingCode(
        uid: currentUser.uid,
        code: normalizedCode,
      );
      _state = _state.copyWith(pendingCodes: pendingCodes, isOffline: true);
      notifyListeners();
      return;
    }

    _state = _state.copyWith(isLoading: true);
    notifyListeners();

    try {
      final result = await _repository.addFriendByCode(
        uid: currentUser.uid,
        code: normalizedCode,
      );

      switch (result) {
        case AddFriendResult.added:
          // Reload the list so the new friend appears
          _state = _state.copyWith(isLoading: false);
          await loadFriends(forceRefresh: true);
          return;
        case AddFriendResult.notFound:
          _state = _state.copyWith(
            isLoading: false,
            errorMessage: 'No user has that code',
          );
        case AddFriendResult.ownCode:
          _state = _state.copyWith(
            isLoading: false,
            errorMessage: "You can't add yourself",
          );
      }
    } catch (e) {
      _state = _state.copyWith(
        isLoading: false,
        errorMessage: "We couldn't add your friend. Try again",
      );
    }
    notifyListeners();
  }

  @override
  void dispose() {
    // Stop listening for connection changes when the ViewModel is removed
    _connectionSubscription?.cancel();
    _authSubscription?.cancel();
    super.dispose();
  }
}
