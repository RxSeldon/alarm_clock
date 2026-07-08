// Smoke test: the app boots, shows the live clock, and the empty-alarms
// state before any alarm has been added.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:alarm_clock_app/main.dart';
import 'package:alarm_clock_app/src/application/clock_service.dart';
import 'package:alarm_clock_app/src/presentation/providers/providers.dart';

import 'fakes.dart';

/// A [ClockService] that never ticks. Swapped in for [clockServiceProvider]
/// so this test doesn't depend on a real periodic [Timer] -- exactly the
/// kind of substitution the [ClockService] abstraction exists to enable.
class _StillClockService implements ClockService {
  @override
  Stream<DateTime> get onTick => const Stream<DateTime>.empty();
}

void main() {
  testWidgets('Home screen shows the clock and an empty alarm list',
      (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          clockServiceProvider.overrideWithValue(_StillClockService()),
          authRepositoryProvider
              .overrideWithValue(const FakeSignedInAuthRepository()),
          systemAlarmServiceProvider
              .overrideWithValue(FakeSystemAlarmService()),
        ],
        child: const AlarmClockApp(),
      ),
    );
    // Two pumps: one for the auth stream to emit, one for the rebuild.
    await tester.pump();
    await tester.pump();

    expect(find.text('No alarms yet'), findsOneWidget);
    expect(find.byIcon(Icons.add), findsOneWidget);
  });
}
