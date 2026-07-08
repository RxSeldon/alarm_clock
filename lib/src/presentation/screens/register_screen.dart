import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../domain/repositories/auth_repository.dart';
import '../providers/providers.dart';

/// Email + password account-creation screen.
///
/// Does light client-side validation (email present, password length, and
/// matching confirmation) before calling the [AuthRepository]; anything the
/// backend rejects comes back as an [AuthException] and is shown inline. On
/// success Firebase signs the new user in and this screen pops back to the
/// [AuthGate], which is already showing the home screen for the new session.
class RegisterScreen extends HookConsumerWidget {
  const RegisterScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ThemeData theme = Theme.of(context);
    final TextEditingController emailController = useTextEditingController();
    final TextEditingController passwordController = useTextEditingController();
    final TextEditingController confirmController = useTextEditingController();
    final ValueNotifier<bool> isLoading = useState(false);
    final ValueNotifier<bool> obscure = useState(true);
    final ValueNotifier<String?> errorText = useState<String?>(null);

    Future<void> submit() async {
      final String email = emailController.text.trim();
      final String password = passwordController.text;
      final String confirm = confirmController.text;

      if (email.isEmpty || password.isEmpty) {
        errorText.value = 'Please fill in every field.';
        return;
      }
      if (password.length < 6) {
        errorText.value = 'Password must be at least 6 characters.';
        return;
      }
      if (password != confirm) {
        errorText.value = 'Passwords do not match.';
        return;
      }

      errorText.value = null;
      isLoading.value = true;
      try {
        await ref
            .read(authRepositoryProvider)
            .register(email: email, password: password);
        // Success: Firebase has signed the new user in and the AuthGate (the
        // navigator's first route) is already swapping to the home screen.
        // This screen was *pushed on top* of the AuthGate, so it must pop
        // itself, or the user stays stuck here behind the spinner.
        if (context.mounted) {
          Navigator.of(context).popUntil((Route<dynamic> route) => route.isFirst);
        }
      } on AuthException catch (e) {
        errorText.value = e.message;
        isLoading.value = false;
      } catch (_) {
        errorText.value = 'Something went wrong. Please try again.';
        isLoading.value = false;
      }
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Create account')),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Join in',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.titleLarge),
                const SizedBox(height: 4),
                Text('Create an account to set your alarms',
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
                  textInputAction: TextInputAction.next,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    helperText: 'At least 6 characters',
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(obscure.value
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined),
                      onPressed: () => obscure.value = !obscure.value,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: confirmController,
                  obscureText: obscure.value,
                  enabled: !isLoading.value,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => isLoading.value ? null : submit(),
                  decoration: const InputDecoration(
                    labelText: 'Confirm password',
                    prefixIcon: Icon(Icons.lock_outline),
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
                      : const Text('Register'),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('Already have an account?',
                        style: theme.textTheme.bodySmall),
                    TextButton(
                      onPressed: isLoading.value
                          ? null
                          : () => Navigator.of(context).pop(),
                      child: const Text('Log in'),
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
