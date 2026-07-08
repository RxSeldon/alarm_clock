import '../entities/app_user.dart';

/// Authentication contract for the app.
///
/// The presentation layer depends on this abstraction, never on
/// `firebase_auth` directly (Dependency Inversion Principle). Swapping the
/// backend -- Firebase today, something else tomorrow -- only means writing a
/// new class that implements this interface; no screen or provider changes.
abstract interface class AuthRepository {
  /// Emits the signed-in [AppUser], or `null` when signed out. Fires once
  /// immediately with the current state, then again on every sign-in and
  /// sign-out. This is what the app's [AuthGate] listens to.
  Stream<AppUser?> authStateChanges();

  /// The currently signed-in user, or `null` if nobody is signed in.
  AppUser? get currentUser;

  /// Creates a new account and signs the user in.
  ///
  /// Throws an [AuthException] with a user-friendly message on failure
  /// (email already in use, weak password, ...).
  Future<void> register({required String email, required String password});

  /// Signs an existing user in.
  ///
  /// Throws an [AuthException] with a user-friendly message on failure
  /// (wrong password, unknown email, ...).
  Future<void> signIn({required String email, required String password});

  /// Signs in with a Google account, creating one on first use.
  ///
  /// Opens the Google account chooser. Returns normally (no throw) if the
  /// user cancels the chooser. Throws an [AuthException] with a user-friendly
  /// message on any other failure.
  Future<void> signInWithGoogle();

  /// Signs the current user out.
  Future<void> signOut();
}

/// A failure surfaced by an [AuthRepository], carrying a message that is safe
/// to show directly to the user. Keeps backend-specific error types (e.g.
/// `FirebaseAuthException`) out of the presentation layer.
class AuthException implements Exception {
  const AuthException(this.message);

  final String message;

  @override
  String toString() => message;
}
