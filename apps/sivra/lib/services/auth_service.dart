import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _auth;

  AuthService(this._auth);

  static AuthService get instance => AuthService(FirebaseAuth.instance);

  User? get currentUser => _auth.currentUser;

  Future<User> ensureSignedIn() async {
    final user = _auth.currentUser;
    if (user != null) {
      return user;
    }

    final cred = await _auth.signInAnonymously();
    return cred.user!;
  }
}

