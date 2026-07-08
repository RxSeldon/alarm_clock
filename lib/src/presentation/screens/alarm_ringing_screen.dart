import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../domain/entities/alarm.dart';
import '../providers/providers.dart';
import '../utils/time_formatter.dart';

/// Full-screen alert shown the instant an [Alarm] fires.
///
/// The alarm sound itself is played by the OS alarm (see
/// `SystemAlarmService`), so it keeps ringing even if this screen never
/// appears (locked phone, app in background); this screen only displays the
/// alarm and offers snooze/dismiss.
///
/// Uses `useAnimationController` + `useAnimation` (flutter_hooks) to drive a
/// pulsing icon: the hook owns the controller's lifecycle, so it is created
/// once and disposed automatically when this screen is popped, with no
/// `initState`/`dispose` pair to maintain by hand.
class AlarmRingingScreen extends HookConsumerWidget {
  const AlarmRingingScreen({super.key, required this.alarm});

  final Alarm alarm;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ThemeData theme = Theme.of(context);

    final AnimationController pulseController = useAnimationController(
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    final double pulse = useAnimation(
      CurvedAnimation(parent: pulseController, curve: Curves.easeInOut),
    );

    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 48),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  children: [
                    Text(
                      'ALARM',
                      style: theme.textTheme.labelLarge?.copyWith(letterSpacing: 6),
                    ),
                    const SizedBox(height: 32),
                    Opacity(
                      opacity: 0.55 + pulse * 0.45,
                      child: Icon(
                        Icons.alarm_rounded,
                        size: 96,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
                Column(
                  children: [
                    Text(
                      TimeFormatter.alarmTime(alarm.hour, alarm.minute),
                      style: theme.textTheme.displayLarge,
                    ),
                    if (alarm.label.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(alarm.label, style: theme.textTheme.titleMedium),
                    ],
                  ],
                ),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => _snooze(context, ref),
                        child: const Text('SNOOZE +5'),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: FilledButton(
                        onPressed: () => _dismiss(context, ref),
                        child: const Text('DISMISS'),
                      ),
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

  void _dismiss(BuildContext context, WidgetRef ref) {
    ref.read(alarmListProvider.notifier).dismissRinging(alarm);
    Navigator.of(context).pop();
  }

  void _snooze(BuildContext context, WidgetRef ref) {
    ref.read(alarmListProvider.notifier).snoozeRinging(alarm);
    Navigator.of(context).pop();
  }
}
