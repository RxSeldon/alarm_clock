import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../domain/entities/app_user.dart';
import '../providers/providers.dart';

/// Shows the signed-in account's photo, full name, email, phone, and the
/// provider it signed in with.
///
/// Name and photo only come through for Google sign-in; plain email/password
/// accounts fall back to an initials avatar and a "Not provided" name. Phone
/// is always "Not provided" today -- neither sign-in method in this app
/// supplies it -- but the row is kept so it lights up automatically if phone
/// verification is ever added.
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppUser? user = ref.watch(authStateProvider).valueOrNull;

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(child: _ProfileAvatar(user: user)),
              const SizedBox(height: 28),
              _ProfileField(
                icon: Icons.person_outline,
                label: 'Full name',
                value: user?.displayName ?? 'Not provided',
              ),
              const Divider(height: 1),
              _ProfileField(
                icon: Icons.mail_outline,
                label: 'Email',
                value: user?.email ?? 'Not provided',
              ),
              const Divider(height: 1),
              _ProfileField(
                icon: Icons.phone_outlined,
                label: 'Phone',
                value: user?.phoneNumber ?? 'Not provided',
              ),
              const Divider(height: 1),
              if (user != null)
                _ProfileField(
                  icon: _iconFor(user.provider),
                  label: 'Signed in as',
                  value: _labelFor(user.provider),
                ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _iconFor(SignInProvider provider) => switch (provider) {
        SignInProvider.google => Icons.g_mobiledata,
        SignInProvider.emailPassword => Icons.alternate_email,
      };

  String _labelFor(SignInProvider provider) => switch (provider) {
        SignInProvider.google => 'Google',
        SignInProvider.emailPassword => 'Email & Password',
      };
}

class _ProfileField extends StatelessWidget {
  const _ProfileField({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Row(
        children: [
          Icon(icon, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: theme.textTheme.bodySmall),
                const SizedBox(height: 2),
                Text(value, style: theme.textTheme.titleMedium),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileAvatar extends StatelessWidget {
  const _ProfileAvatar({required this.user});

  final AppUser? user;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final String? photoUrl = user?.photoUrl;

    if (photoUrl != null) {
      return CircleAvatar(radius: 48, backgroundImage: NetworkImage(photoUrl));
    }

    final String? name = user?.displayName;
    final String? email = user?.email;
    final String initial =
        (name?.isNotEmpty ?? false) ? name![0] : (email?.isNotEmpty ?? false) ? email![0] : '?';

    return CircleAvatar(
      radius: 48,
      backgroundColor: theme.colorScheme.primaryContainer,
      child: Text(
        initial.toUpperCase(),
        style: theme.textTheme.headlineMedium
            ?.copyWith(color: theme.colorScheme.onPrimaryContainer),
      ),
    );
  }
}
