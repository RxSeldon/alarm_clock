import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../domain/entities/app_user.dart';
import '../domain/repositories/auth_repository.dart';

/// [AuthRepository] implementation backed by Firebase Authentication.
///
/// This is the one place in the app that knows about `firebase_auth`. It
/// translates Firebase's [User] into the app's own [AppUser] and its
/// [FirebaseAuthException]s into friendly [AuthException]s, so nothing above
/// the data layer ever imports Firebase (Single Responsibility + Dependency
/// Inversion).
class FirebaseAuthRepository implements AuthRepository {
  FirebaseAuthRepository([FirebaseAuth? auth, GoogleSignIn? googleSignIn])
      : _auth = auth ?? FirebaseAuth.instance,
        _googleSignIn = googleSignIn ?? GoogleSignIn();

  final FirebaseAuth _auth;
  final GoogleSignIn _googleSignIn;

  @override
  Stream<AppUser?> authStateChanges() =>
      _auth.authStateChanges().map(_toAppUser);

  @override
  AppUser? get currentUser => _toAppUser(_auth.currentUser);

  @override
  Future<void> register({
    required String email,
    required String password,
  }) async {
    try {
      await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      throw AuthException(_messageFor(e));
    }
  }

  @override
  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    try {
      await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      throw AuthException(_messageFor(e));
    }
  }

  @override
  Future<void> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      // The user backed out of the account chooser -- not an error.
      if (googleUser == null) return;

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      await _auth.signInWithCredential(credential);
    } on FirebaseAuthException catch (e) {
      throw AuthException(_messageFor(e));
    }
  }

  @override
  Future<void> signOut() async {
    // Sign out of Google too, so the next Google sign-in shows the account
    // chooser again instead of silently reusing the last account.
    await _googleSignIn.signOut();
    await _auth.signOut();
  }

  AppUser? _toAppUser(User? user) => user == null
      ? null
      : AppUser(
          uid: user.uid,
          email: user.email,
          displayName: user.displayName,
          photoUrl: user.photoURL,
          phoneNumber: user.phoneNumber,
          provider: _providerFor(user),
        );

  /// A user can technically be linked to multiple providers; this app only
  /// offers Google and email/password, so "any linked Google provider" is
  /// enough to call the account a Google sign-in.
  SignInProvider _providerFor(User user) {
    final bool hasGoogle =
        user.providerData.any((info) => info.providerId == 'google.com');
    return hasGoogle ? SignInProvider.google : SignInProvider.emailPassword;
  }

  /// Maps Firebase error codes to messages that are safe to show the user.
  String _messageFor(FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-email':
        return 'That email address is not valid.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return 'Incorrect email or password.';
      case 'email-already-in-use':
        return 'An account already exists for that email.';
      case 'weak-password':
        return 'Password is too weak. Use at least 6 characters.';
      case 'operation-not-allowed':
        return 'Email/password sign-in is not enabled for this project.';
      case 'account-exists-with-different-credential':
        return 'An account already exists with the same email but a '
            'different sign-in method.';
      case 'network-request-failed':
        return 'Network error. Check your connection and try again.';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';
      default:
        return e.message ?? 'Authentication failed. Please try again.';
    }
  }
}
