import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../application/alarm_sound_player.dart';
import '../../application/philippine_time.dart';
import '../../domain/entities/alarm.dart';
import '../providers/providers.dart';
import '../utils/time_formatter.dart';

/// Full-screen alert shown the instant an [Alarm] fires.
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

    useEffect(() {
      final AlarmSoundPlayer player = ref.read(alarmSoundPlayerProvider);
      player.start();
      return player.stop;
    }, const []);

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
    ref.read(alarmListProvider.notifier).disableOneTimeAlarm(alarm.id);
    Navigator.of(context).pop();
  }

  void _snooze(BuildContext context, WidgetRef ref) {
    final DateTime snoozeAt = PhilippineTime.now().add(const Duration(minutes: 5));
    ref.read(alarmListProvider.notifier).addAlarm(
          Alarm(
            id: 'snooze-${DateTime.now().microsecondsSinceEpoch}',
            hour: snoozeAt.hour,
            minute: snoozeAt.minute,
            label: alarm.label.isEmpty ? 'Snooze' : '${alarm.label} (snoozed)',
          ),
        );
    Navigator.of(context).pop();
  }
}
