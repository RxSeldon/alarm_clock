import 'package:flutter/foundation.dart';

/// The signed-in user, reduced to just what the app needs.
///
/// A plain domain entity with no dependency on Firebase: the presentation
/// layer talks about an [AppUser], never a `firebase_auth` `User`, so the
/// authentication backend stays swappable (Dependency Inversion).
@immutable
class AppUser {
  const AppUser({
    required this.uid,
    required this.email,
    this.displayName,
    this.photoUrl,
    this.phoneNumber,
    this.provider = SignInProvider.emailPassword,
  });

  /// Stable unique id assigned by the auth backend.
  final String uid;

  /// The account's email address. Null only if the backend omits it.
  final String? email;

  /// The account's display name. Populated for Google sign-in; usually null
  /// for plain email/password accounts.
  final String? displayName;

  /// URL of the account's profile picture. Populated for Google sign-in;
  /// usually null for plain email/password accounts.
  final String? photoUrl;

  /// The account's phone number. Neither Google nor email/password sign-in
  /// supplies this in the app today, so it is null in practice; kept here so
  /// the field is ready if phone verification is ever added.
  final String? phoneNumber;

  /// Which method the user signed in with.
  final SignInProvider provider;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AppUser &&
          other.uid == uid &&
          other.email == email &&
          other.displayName == displayName &&
          other.photoUrl == photoUrl &&
          other.phoneNumber == phoneNumber &&
          other.provider == provider);

  @override
  int get hashCode =>
      Object.hash(uid, email, displayName, photoUrl, phoneNumber, provider);
}

/// The method an [AppUser] used to sign in. Kept as a plain enum (not a raw
/// Firebase provider id string) so the presentation layer never needs to
/// know Firebase's `"google.com"` / `"password"` string constants.
enum SignInProvider { google, emailPassword }
