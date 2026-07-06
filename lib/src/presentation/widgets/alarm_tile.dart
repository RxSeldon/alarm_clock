import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../domain/entities/alarm.dart';
import '../providers/providers.dart';
import '../utils/time_formatter.dart';
import 'add_edit_alarm_sheet.dart';

/// One row in the alarm list: time, label/repeat summary, an enable switch,
/// tap-to-edit, and swipe-to-delete.
class AlarmTile extends ConsumerWidget {
  const AlarmTile({super.key, required this.alarm});

  final Alarm alarm;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ThemeData theme = Theme.of(context);
    final Color dimmed = theme.colorScheme.onSurface.withValues(alpha: 0.4);

    return Dismissible(
      key: ValueKey<String>(alarm.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Icon(Icons.delete_outline, color: theme.colorScheme.error),
      ),
      onDismissed: (_) =>
          ref.read(alarmListProvider.notifier).removeAlarm(alarm.id),
      child: ListTile(
        onTap: () => showAddEditAlarmSheet(context, existing: alarm),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        title: Text(
          TimeFormatter.alarmTime(alarm.hour, alarm.minute),
          style: theme.textTheme.displayMedium?.copyWith(
            fontSize: 30,
            color: alarm.isEnabled ? theme.colorScheme.onSurface : dimmed,
          ),
        ),
        subtitle: Text(
          alarm.label.isEmpty
              ? TimeFormatter.repeatSummary(alarm.repeatDays)
              : '${alarm.label} · ${TimeFormatter.repeatSummary(alarm.repeatDays)}',
          style: theme.textTheme.bodySmall,
        ),
        trailing: Switch(
          value: alarm.isEnabled,
          onChanged: (bool value) =>
              ref.read(alarmListProvider.notifier).toggleAlarm(alarm.id, value),
        ),
      ),
    );
  }
}
