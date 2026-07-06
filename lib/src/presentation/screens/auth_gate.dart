import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../providers/providers.dart';
import 'home_screen.dart';
import 'login_screen.dart';

/// The app's authentication switchboard.
///
/// Watches [authStateProvider] and shows the right screen for the current
/// auth state: the [HomeScreen] when a user is signed in, the [LoginScreen]
/// otherwise. Because it reacts to the auth *stream*, signing in or out
/// anywhere in the app automatically routes here -- no manual navigation
/// after login/logout is needed.
class AuthGate extends ConsumerWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<Object?> authState = ref.watch(authStateProvider);

    return authState.when(
      data: (user) => user == null ? const LoginScreen() : const HomeScreen(),
      loading: () => const _AuthLoading(),
      error: (Object error, _) => _AuthError(message: error.toString()),
    );
  }
}

class _AuthLoading extends StatelessWidget {
  const _AuthLoading();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}

class _AuthError extends StatelessWidget {
  const _AuthError({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline,
                  size: 44, color: theme.colorScheme.error),
              const SizedBox(height: 12),
              Text("Couldn't reach authentication",
                  style: theme.textTheme.titleMedium),
              const SizedBox(height: 4),
              Text(message,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodySmall),
            ],
          ),
        ),
      ),
    );
  }
}
