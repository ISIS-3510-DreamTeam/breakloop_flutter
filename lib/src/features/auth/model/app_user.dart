class AppUser {
  final String uid;
  final String? email;
  final bool emailVerified;
  final String? displayName;

  const AppUser({
    required this.uid,
    required this.email,
    required this.emailVerified,
    this.displayName,

  });

}