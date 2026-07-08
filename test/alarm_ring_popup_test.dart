// Proves the app-level wiring in AlarmClockApp: when an alarm starts
// ringing, the full-screen ringing UI is pushed on top of whatever is
// showing, and DISMISS takes the user back.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:alarm_clock_app/main.dart';
import 'package:alarm_clock_app/src/domain/entities/alarm.dart';
import 'package:alarm_clock_app/src/presentation/providers/providers.dart';
import 'package:alarm_clock_app/src/presentation/screens/alarm_ringing_screen.dart';

import 'fakes.dart';

void main() {
  testWidgets('Ringing screen pops up when an alarm fires and can be dismissed',
      (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final FakeSystemAlarmService alarmService = FakeSystemAlarmService();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          clockServiceProvider.overrideWithValue(FakeClockService()),
          authRepositoryProvider
              .overrideWithValue(const FakeSignedInAuthRepository()),
          systemAlarmServiceProvider.overrideWithValue(alarmService),
        ],
        child: const AlarmClockApp(),
      ),
    );
    // Two pumps: one for the auth stream to emit, one for the rebuild.
    await tester.pump();
    await tester.pump();

    expect(find.text('DISMISS'), findsNothing);

    // Simulate the OS alarm firing.
    alarmService.ringController.add(
      const Alarm(id: 'a1', hour: 7, minute: 30, label: 'Wake up'),
    );
    // Extra pumps: one to deliver the stream event, one for the push, then
    // the route's entrance animation. (No pumpAndSettle: the ringing screen
    // pulses forever by design.)
    await tester.pump();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.byType(AlarmRingingScreen), findsOneWidget);
    expect(find.text('ALARM'), findsOneWidget);
    expect(find.text('Wake up'), findsOneWidget);
    expect(find.text('07:30 AM'), findsOneWidget);

    // Dismissing pops back to the home screen.
    await tester.tap(find.text('DISMISS'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));

    expect(find.text('ALARM'), findsNothing);
    expect(find.text('No alarms yet'), findsOneWidget);
  });
}
