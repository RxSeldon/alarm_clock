import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../providers/providers.dart';
import '../utils/time_formatter.dart';

/// The big time-of-day readout at the top of the home screen.
///
/// Subscribes to [currentTimeProvider], the one-second [Stream<DateTime>]
/// coming from the clock service, so it rebuilds exactly once per second and
/// stays in sync with whatever else in the app is watching the same stream
/// (e.g. the alarm scheduler).
class DigitalClock extends ConsumerWidget {
  const DigitalClock({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<DateTime> timeAsync = ref.watch(currentTimeProvider);
    final DateTime now = timeAsync.valueOrNull ?? DateTime.now();
    final ThemeData theme = Theme.of(context);

    return Column(
      children: [
        Text(
          TimeFormatter.clock24(now),
          style: theme.textTheme.displayLarge,
        ),
        const SizedBox(height: 8),
        Text(
          TimeFormatter.longDate(now),
          style: theme.textTheme.bodySmall?.copyWith(letterSpacing: 1),
        ),
      ],
    );
  }
}
