import 'package:flutter/foundation.dart';

/// The signed-in user, reduced to just what the app needs.
///
/// A plain domain entity with no dependency on Firebase: the presentation
/// layer talks about an [AppUser], never a `firebase_auth` `User`, so the
/// authentication backend stays swappable (Dependency Inversion).
@immutable
class AppUser {
  const AppUser({required this.uid, required this.email});

  /// Stable unique id assigned by the auth backend.
  final String uid;

  /// The account's email address. Null only if the backend omits it.
  final String? email;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AppUser && other.uid == uid && other.email == email);

  @override
  int get hashCode => Object.hash(uid, email);
}
