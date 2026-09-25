import 'package:flutter/foundation.dart';
import '../data/auth_repository.dart';
import '../model/auth_failure.dart';

enum ResetStatus  { idle, loading, success, error }

class PasswordResetViewmodel extends ChangeNotifier {
  final AuthRepository _repository;
  PasswordResetViewmodel(this._repository);

  ResetStatus  status = ResetStatus .idle;
  AuthFailure? failure;

  Future<void> sendResetEmail(String email) async {
    status = ResetStatus .loading;
    failure = null;
    notifyListeners();

    try {
      await _repository.sendPasswordResetEmail(email);
      status = ResetStatus.success;

    } on AuthFailure catch (e) {
      status = ResetStatus.error;
      failure = e;
    }
    notifyListeners();
  }

}