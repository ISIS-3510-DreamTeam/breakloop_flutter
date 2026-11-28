import 'package:flutter/foundation.dart';

enum AuthFailureType {
  invalidEmail,
  invalidCredentials,
  wrongPassword,
  userNotFound,
  emailAlreadyInUse,
  weakPassword,
  tooManyRequests,
  accountDisabled,
  network,
  unknown,
}

class AuthFailure {
  final AuthFailureType type;
  final String message;

  const AuthFailure(this.type, this.message);

  /// Maps a FirebaseAuthException.code (without the "auth/" prefix) to a message.
  factory AuthFailure.fromCode(String code) {
    switch (code) {
      case 'invalid-email':
        return const AuthFailure(
          AuthFailureType.invalidEmail,
          'The e-mail address is not valid.',
        );

    // With email enumeration protection (on by default in new projects), Firebase
    // returns this single code for a wrong password AND for an unknown e-mail.
    // The older codes are kept in case the protection is turned off.
      case 'invalid-credential':
      case 'invalid-login-credentials':
      case 'wrong-password':
      case 'user-not-found':
        return const AuthFailure(
          AuthFailureType.invalidCredentials,
          'Incorrect e-mail or password.',
        );

      case 'email-already-in-use':
        return const AuthFailure(
          AuthFailureType.emailAlreadyInUse,
          'An account already exists with this e-mail.',
        );

      case 'weak-password':
      case 'password-does-not-meet-requirements':
        return const AuthFailure(
          AuthFailureType.weakPassword,
          'Your password does not meet the requirements shown above.',
        );

      case 'too-many-requests':
        return const AuthFailure(
          AuthFailureType.tooManyRequests,
          'Too many attempts. Wait a few minutes and try again.',
        );

      case 'user-disabled':
        return const AuthFailure(
          AuthFailureType.accountDisabled,
          'This account has been disabled.',
        );

      case 'network-request-failed':
        return const AuthFailure(
          AuthFailureType.network,
          'Network error. Check your device connection.',
        );

      default:
      // Unknown codes appear in the logs, so they can be mapped later.
        debugPrint('[AuthFailure] unmapped Firebase code: $code');
        return const AuthFailure(
          AuthFailureType.unknown,
          'Oops, something went wrong. Try again.',
        );
    }
  }
}