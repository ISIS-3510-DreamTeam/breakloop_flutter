enum AuthFailureType {
  invalidEmail,
  wrongPassword,
  userNotFound,
  emailAlreadyInUse,
  weakPassword,
  unknown,
}

class AuthFailure { 
  final AuthFailureType type;
  final String message;
  
  const AuthFailure(this.type, this.message);
  
  factory AuthFailure.fromCode(String code){
    switch (code) {
      case 'invalid-email':
        return const AuthFailure(AuthFailureType.invalidEmail, "The e-mail is not valid.");
      case 'wrong-password':
        return const AuthFailure(AuthFailureType.wrongPassword, "Incorrect password not valid.");
      case 'user-not-found':
        return const AuthFailure(AuthFailureType.userNotFound, "There is no account associated to the entered e-mail.");
      case 'weak-password':
        return const AuthFailure(AuthFailureType.weakPassword, "The password is too weak.");
      default:
        return const AuthFailure(AuthFailureType.unknown, "Oops, something went wrong. Try again. ");
            
    }
  }
  
  
}