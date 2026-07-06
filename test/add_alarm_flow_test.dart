// Drives the add-alarm flow the way a user would: tap the FAB, pick a
// repeat day, save, then confirm the new alarm shows up and its switch
// works.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:alarm_clock_app/main.dart';
import 'package:alarm_clock_app/src/application/clock_service.dart';
import 'package:alarm_clock_app/src/presentation/providers/providers.dart';

class _StillClockService implements ClockService {
  @override
  Stream<DateTime> get onTick => const Stream<DateTime>.empty();
}

void main() {
  testWidgets('User can add an alarm from the FAB and toggle it off',
      (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          clockServiceProvider.overrideWithValue(_StillClockService()),
        ],
        child: const AlarmClockApp(),
      ),
    );
    await tester.pump();

    // Empty state before adding anything.
    expect(find.text('No alarms yet'), findsOneWidget);

    // Open the add-alarm sheet.
    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle();

    expect(find.text('New alarm'), findsOneWidget);

    // Pick a repeat day (Monday chip) without touching the time picker
    // (default is "now", which is enough to prove the flow works).
    await tester.tap(find.widgetWithText(ChoiceChip, 'M'));
    await tester.pump();

    // Save.
    await tester.tap(find.widgetWithText(FilledButton, 'SAVE'));
    await tester.pumpAndSettle();

    // Sheet closed, empty state gone, one alarm row now exists.
    expect(find.text('New alarm'), findsNothing);
    expect(find.text('No alarms yet'), findsNothing);
    expect(find.text('Mon'), findsOneWidget);
    expect(find.text('1 active'), findsOneWidget);

    // Toggling the switch off should update the active count.
    await tester.tap(find.byType(Switch));
    await tester.pump();
    expect(find.text('0 active'), findsOneWidget);
  });
}
