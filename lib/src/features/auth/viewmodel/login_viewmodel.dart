import 'package:flutter/foundation.dart';
import '../data/auth_repository.dart';
import '../model/auth_failure.dart';

enum LoginStatus { idle, loading, error }

class LoginViewModel extends ChangeNotifier {
  final AuthRepository _repository;
  LoginViewModel(this._repository);

  LoginStatus status = LoginStatus.idle;
  AuthFailure? failure;

  Future<void> login(String email, String password) async {
    status = LoginStatus.loading;
    failure = null;
    notifyListeners();

    try {
      await _repository.signIn(email, password);
      status = LoginStatus.idle;

    } on AuthFailure catch (e) {
      status = LoginStatus.error;
      failure = e;
    }
    notifyListeners();
  }

}