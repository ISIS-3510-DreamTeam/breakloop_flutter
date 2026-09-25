import 'package:flutter/foundation.dart';
import '../data/auth_repository.dart';
import '../model/auth_failure.dart';

enum SignupStatus { idle, loading, error }

class SignupViewModel extends ChangeNotifier {
  final AuthRepository _repository;
  SignupViewModel(this._repository);

  SignupStatus status = SignupStatus.idle;
  AuthFailure? failure;

  Future<void> signUp(String email, String password, String confirmPassword) async {
    if (password != confirmPassword){
      status = SignupStatus.error;
      failure = const AuthFailure(AuthFailureType.unknown, "The passwords do not match.");
      notifyListeners();
      return;
    }
    status = SignupStatus.loading;
    failure = null;
    notifyListeners();

    try {
      await _repository.signIn(email, password);
      status = SignupStatus.idle;

    } on AuthFailure catch (e) {
      status = SignupStatus.error;
      failure = e;
    }
    notifyListeners();
  }

}