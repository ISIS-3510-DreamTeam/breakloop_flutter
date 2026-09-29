import 'package:firebase_auth/firebase_auth.dart';
import '../model/app_user.dart';
import '../model/auth_failure.dart';

class AuthRepository {
  //The underscore means this is a private attribute
  final FirebaseAuth _auth;

  //We allow for optional Firebase to facilitate testing by using mocks.
  AuthRepository({FirebaseAuth? auth}) : _auth = auth ?? FirebaseAuth.instance;

  //Parse Firebase user into our model user
  AppUser? _toAppUser(User? user){
    if (user == null){
      return null;
    }
    return AppUser(uid: user.uid, email: user.email, emailVerified: user.emailVerified);
  }

  // Subscribe to the auth state of an user. With this we monitor when an object is registered, logged in or logged out.
  Stream<AppUser?> get authStateChange =>
      _auth.authStateChanges().map(_toAppUser);

  //Get the current user
  AppUser? get currentUser => _toAppUser(_auth.currentUser);

  //Now we define the main operations

  //Sign in
  Future<void> signIn(String email, String password) async {
    try{
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      //Notice this event will be caught by the authStateChange and we will get the user from that.
    } on FirebaseAuthException catch (e){
      throw AuthFailure.fromCode(e.code);
    }
  }

  //Sign up
  Future<void> signUp(String email, String password) async {
    try{
      await _auth.createUserWithEmailAndPassword(email: email, password: password);
      //Notice this event will be caught by the authStateChange and we will get the user from that.
    } on FirebaseAuthException catch (e){
      throw AuthFailure.fromCode(e.code);
    }
  }

  //Reset password by receiving an e-mail
  Future<void> sendPasswordResetEmail(String email) async {
    try{
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw AuthFailure.fromCode(e.code);
    }
  }

  //Log Out
  Future<void> signOut() => _auth.signOut();
  
}