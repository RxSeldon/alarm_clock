import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'firebase_options.dart';
import 'src/application/system_alarm_service.dart';
import 'src/domain/entities/alarm_event.dart';
import 'src/presentation/providers/providers.dart';
import 'src/presentation/screens/alarm_ringing_screen.dart';
import 'src/presentation/screens/auth_gate.dart';
import 'src/presentation/theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    // Restores OS alarms scheduled in a previous session and reconnects to
    // any alarm that is ringing right now.
    await SystemAlarmService.ensureInitialized();
  } catch (error) {
    // Platform without alarm support (e.g. running on desktop): the app
    // still works, alarms just won't fire outside it.
    debugPrint('OS alarm support unavailable: $error');
  }
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (error) {
    // Firebase is only configured for Android; on other platforms (or with a
    // broken config) show the reason instead of dying silently on a white
    // screen before the first frame.
    runApp(FirebaseStartupErrorApp(error: error));
    return;
  }
  runApp(const ProviderScope(child: AlarmClockApp()));
}

/// Shown when Firebase fails to initialize, so the failure is visible.
class FirebaseStartupErrorApp extends StatelessWidget {
  const FirebaseStartupErrorApp({super.key, required this.error});

  final Object error;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, size: 48, color: Colors.red),
                const SizedBox(height: 16),
                const Text(
                  'Firebase could not start',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  '$error\n\nRun this app on an Android device or emulator.',
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class AlarmClockApp extends ConsumerWidget {
  const AlarmClockApp({super.key});

  /// Lets the ringing screen be pushed from outside any screen's context,
  /// so the alarm pops up no matter where in the app the user currently is.
  static final GlobalKey<NavigatorState> _navigatorKey =
      GlobalKey<NavigatorState>();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // App-level (not screen-level) wiring for the alarm engine: whenever an
    // OS alarm starts ringing while the app is open, push the full-screen
    // ringing UI on top of whatever is showing -- login, home, or a sheet.
    ref.listen<AsyncValue<AlarmEvent>>(alarmEventProvider, (previous, next) {
      next.whenData((AlarmEvent event) {
        if (event is AlarmRingingEvent) {
          _navigatorKey.currentState?.push(
            MaterialPageRoute<void>(
              fullscreenDialog: true,
              builder: (_) => AlarmRingingScreen(alarm: event.alarm),
            ),
          );
        }
      });
    });

    return MaterialApp(
      title: 'Minimal Alarm',
      debugShowCheckedModeBanner: false,
      navigatorKey: _navigatorKey,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.system,
      // AuthGate decides between the login flow and the home screen based on
      // the current Firebase auth state.
      home: const AuthGate(),
    );
  }
}
