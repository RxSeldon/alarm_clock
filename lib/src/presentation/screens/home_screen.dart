import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../domain/entities/alarm.dart';
import '../../domain/entities/alarm_event.dart';
import '../providers/providers.dart';
import '../widgets/add_edit_alarm_sheet.dart';
import '../widgets/alarm_tile.dart';
import '../widgets/digital_clock.dart';
import 'alarm_ringing_screen.dart';

/// App root screen: live clock + alarm list.
///
/// Also owns the event-driven wiring for the alarm engine: it listens to
/// [alarmEventProvider] and, whenever an [AlarmRingingEvent] arrives, pushes
/// the full-screen [AlarmRingingScreen] on top of itself. The scheduler that
/// produces the event has no idea the UI exists; the UI has no idea how the
/// event was computed -- they only share the [AlarmEvent] contract.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ThemeData theme = Theme.of(context);
    final List<Alarm> alarms = ref.watch(alarmListProvider);
    final int activeCount = alarms.where((Alarm a) => a.isEnabled).length;

    ref.listen<AsyncValue<AlarmEvent>>(alarmEventProvider, (previous, next) {
      next.whenData((AlarmEvent event) {
        if (event is AlarmRingingEvent) {
          Navigator.of(context).push(
            MaterialPageRoute<void>(
              fullscreenDialog: true,
              builder: (_) => AlarmRingingScreen(alarm: event.alarm),
            ),
          );
        }
      });
    });

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 32),
            const DigitalClock(),
            const SizedBox(height: 28),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'ALARMS',
                    style: theme.textTheme.labelLarge?.copyWith(letterSpacing: 3),
                  ),
                  Text(
                    '$activeCount active',
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 4),
            Expanded(
              child: alarms.isEmpty
                  ? _EmptyState(theme: theme)
                  : ListView.separated(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      itemCount: alarms.length,
                      separatorBuilder: (_, _) => Divider(
                        height: 1,
                        indent: 16,
                        endIndent: 16,
                        color: theme.dividerColor,
                      ),
                      itemBuilder: (_, int i) => AlarmTile(alarm: alarms[i]),
                    ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => showAddEditAlarmSheet(context),
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.theme});

  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.bedtime_outlined,
            size: 44,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 12),
          Text('No alarms yet', style: theme.textTheme.bodyMedium),
          const SizedBox(height: 4),
          Text(
            'Tap + to add one',
            style: theme.textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}
