import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../application/philippine_time.dart';
import '../../domain/entities/alarm.dart';
import '../providers/providers.dart';
import '../utils/time_formatter.dart';

/// Opens the create/edit bottom sheet. Pass [existing] to edit an alarm,
/// or omit it to create a new one.
Future<void> showAddEditAlarmSheet(BuildContext context, {Alarm? existing}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => AddEditAlarmSheet(existing: existing),
  );
}

/// Create/edit form for a single alarm.
///
/// Built with `flutter_hooks` (`useState`, `useTextEditingController`)
/// instead of a `StatefulWidget`: the ephemeral form fields (picked time,
/// selected repeat days, label text) live exactly as long as this widget is
/// on screen, with no manual `dispose()` boilerplate to remember.
class AddEditAlarmSheet extends HookConsumerWidget {
  const AddEditAlarmSheet({super.key, this.existing});

  final Alarm? existing;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ThemeData theme = Theme.of(context);
    final DateTime now = PhilippineTime.now();
    final bool isEditing = existing != null;

    final ValueNotifier<int> hour = useState(existing?.hour ?? now.hour);
    final ValueNotifier<int> minute = useState(existing?.minute ?? now.minute);
    final ValueNotifier<Set<int>> repeatDays =
        useState<Set<int>>({...?existing?.repeatDays});
    final TextEditingController labelController =
        useTextEditingController(text: existing?.label ?? '');

    Future<void> pickTime() async {
      final TimeOfDay? picked = await showTimePicker(
        context: context,
        initialTime: TimeOfDay(hour: hour.value, minute: minute.value),
      );
      if (picked != null) {
        hour.value = picked.hour;
        minute.value = picked.minute;
      }
    }

    void toggleDay(int day) {
      final Set<int> updated = {...repeatDays.value};
      if (!updated.remove(day)) updated.add(day);
      repeatDays.value = updated;
    }

    void save() {
      final AlarmListNotifier notifier = ref.read(alarmListProvider.notifier);
      if (isEditing) {
        notifier.updateAlarm(existing!.copyWith(
          hour: hour.value,
          minute: minute.value,
          label: labelController.text.trim(),
          repeatDays: repeatDays.value,
        ));
      } else {
        notifier.addAlarm(Alarm(
          id: DateTime.now().microsecondsSinceEpoch.toString(),
          hour: hour.value,
          minute: minute.value,
          label: labelController.text.trim(),
          repeatDays: repeatDays.value,
        ));
      }
      Navigator.of(context).pop();
    }

    void delete() {
      ref.read(alarmListProvider.notifier).removeAlarm(existing!.id);
      Navigator.of(context).pop();
    }

    const List<String> dayLetters = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(
                      color: theme.dividerColor,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Text(
                  isEditing ? 'Edit alarm' : 'New alarm',
                  style: theme.textTheme.titleLarge,
                ),
                const SizedBox(height: 20),
                Center(
                  child: TextButton(
                    onPressed: pickTime,
                    child: Text(
                      TimeFormatter.alarmTime(hour.value, minute.value),
                      style: theme.textTheme.displayMedium,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 8,
                  runSpacing: 8,
                  children: List.generate(7, (int i) {
                    final int day = i + 1;
                    final bool selected = repeatDays.value.contains(day);
                    return ChoiceChip(
                      label: Text(dayLetters[i]),
                      selected: selected,
                      onSelected: (_) => toggleDay(day),
                    );
                  }),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: labelController,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(labelText: 'Label (optional)'),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    if (isEditing) ...[
                      Expanded(
                        child: OutlinedButton(
                          onPressed: delete,
                          child: const Text('DELETE'),
                        ),
                      ),
                      const SizedBox(width: 12),
                    ],
                    Expanded(
                      child: FilledButton(
                        onPressed: save,
                        child: const Text('SAVE'),
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
}
