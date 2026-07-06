import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../domain/repositories/auth_repository.dart';
import '../providers/providers.dart';
import 'register_screen.dart';

/// Email + password sign-in screen.
///
/// On success it does nothing navigational: the [AuthGate] is watching the
/// auth stream and swaps this screen out for the home screen automatically.
/// Local UI state (controllers, loading, error, obscure-password) is held with
/// flutter_hooks, matching the rest of the app.
class LoginScreen extends HookConsumerWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ThemeData theme = Theme.of(context);
    final TextEditingController emailController = useTextEditingController();
    final TextEditingController passwordController = useTextEditingController();
    final ValueNotifier<bool> isLoading = useState(false);
    final ValueNotifier<bool> obscure = useState(true);
    final ValueNotifier<String?> errorText = useState<String?>(null);

    Future<void> submit() async {
      final String email = emailController.text.trim();
      final String password = passwordController.text;
      if (email.isEmpty || password.isEmpty) {
        errorText.value = 'Please enter your email and password.';
        return;
      }

      errorText.value = null;
      isLoading.value = true;
      try {
        await ref
            .read(authRepositoryProvider)
            .signIn(email: email, password: password);
        // Success: AuthGate swaps in the home screen; nothing to do here.
      } on AuthException catch (e) {
        errorText.value = e.message;
        isLoading.value = false;
      } catch (_) {
        errorText.value = 'Something went wrong. Please try again.';
        isLoading.value = false;
      }
    }

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Icon(Icons.alarm,
                    size: 56, color: theme.colorScheme.onSurface),
                const SizedBox(height: 24),
                Text('Welcome back',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.titleLarge),
                const SizedBox(height: 4),
                Text('Sign in to continue',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodySmall),
                const SizedBox(height: 32),
                TextField(
                  controller: emailController,
                  keyboardType: TextInputType.emailAddress,
                  autocorrect: false,
                  textInputAction: TextInputAction.next,
                  enabled: !isLoading.value,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    prefixIcon: Icon(Icons.mail_outline),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: passwordController,
                  obscureText: obscure.value,
                  enabled: !isLoading.value,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => isLoading.value ? null : submit(),
                  decoration: InputDecoration(
                    labelText: 'Password',
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(obscure.value
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined),
                      onPressed: () => obscure.value = !obscure.value,
                    ),
                  ),
                ),
                if (errorText.value != null) ...[
                  const SizedBox(height: 16),
                  Text(
                    errorText.value!,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: theme.colorScheme.error),
                  ),
                ],
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: isLoading.value ? null : submit,
                  child: isLoading.value
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Log in'),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text("Don't have an account?",
                        style: theme.textTheme.bodySmall),
                    TextButton(
                      onPressed: isLoading.value
                          ? null
                          : () => Navigator.of(context).push(
                                MaterialPageRoute<void>(
                                  builder: (_) => const RegisterScreen(),
                                ),
                              ),
                      child: const Text('Register'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
