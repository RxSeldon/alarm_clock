/// Every provider below wires an abstraction (left-hand type) to one
/// concrete implementation (right-hand constructor). Nothing in the
/// presentation layer ever instantiates [SystemClockService],
/// [SharedPreferencesAlarmRepository], etc. directly -- it only ever asks
/// Riverpod for the interface, which is what makes each piece swappable and
/// testable (Dependency Inversion Principle in practice).
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/clock_service.dart';
import '../../application/philippine_time.dart';
import '../../application/system_alarm_service.dart';
import '../../data/firebase_auth_repository.dart';
import '../../data/shared_preferences_alarm_repository.dart';
import '../../domain/entities/alarm.dart';
import '../../domain/entities/alarm_event.dart';
import '../../domain/entities/app_user.dart';
import '../../domain/repositories/alarm_repository.dart';
import '../../domain/repositories/auth_repository.dart';

final Provider<ClockService> clockServiceProvider = Provider<ClockService>(
  (ref) => SystemClockService(),
);

final Provider<AlarmRepository> alarmRepositoryProvider =
    Provider<AlarmRepository>((ref) => SharedPreferencesAlarmRepository());

final Provider<AuthRepository> authRepositoryProvider =
    Provider<AuthRepository>((ref) => FirebaseAuthRepository());

/// The current authentication state, streamed from the [AuthRepository].
/// Emits the signed-in [AppUser] or `null` when signed out. The [AuthGate]
/// watches this to decide between the login flow and the home screen, and the
/// home screen reads it to show the signed-in email.
final StreamProvider<AppUser?> authStateProvider =
    StreamProvider<AppUser?>((ref) {
  return ref.watch(authRepositoryProvider).authStateChanges();
});

/// Bridge to real OS alarms (sound + notification even when the app is in
/// the background, the screen is off, or the app was killed).
final Provider<SystemAlarmService> systemAlarmServiceProvider =
    Provider<SystemAlarmService>((ref) => SystemAlarmService());

/// The live wall-clock time, ticking once per second. Backs the on-screen
/// digital clock.
final StreamProvider<DateTime> currentTimeProvider =
    StreamProvider<DateTime>((ref) {
  return ref.watch(clockServiceProvider).onTick;
});

/// The stream of alarm-triggered events. Screens subscribe via `ref.listen`
/// to react (e.g. push the ringing screen) without polling anything. The
/// events now originate from real OS alarms instead of an in-app timer, but
/// consumers only ever see the same [AlarmEvent] contract.
final StreamProvider<AlarmEvent> alarmEventProvider =
    StreamProvider<AlarmEvent>((ref) {
  final SystemAlarmService service = ref.watch(systemAlarmServiceProvider);
  return service
      .onAlarmRinging(() => ref.read(alarmListProvider))
      .map(AlarmRingingEvent.new);
});

/// Owns the in-memory list of alarms and keeps it persisted through
/// [AlarmRepository]. This is the single place alarm CRUD happens; UI
/// widgets never mutate the list directly (Single Responsibility).
class AlarmListNotifier extends Notifier<List<Alarm>> {
  late final AlarmRepository _repository;
  late final SystemAlarmService _systemAlarms;

  @override
  List<Alarm> build() {
    _repository = ref.watch(alarmRepositoryProvider);
    _systemAlarms = ref.watch(systemAlarmServiceProvider);
    _loadInitial();
    return <Alarm>[];
  }

  Future<void> _loadInitial() async {
    final List<Alarm> alarms = await _repository.loadAlarms();
    state = _sorted(alarms);
    // Re-register everything with the OS in case alarms changed while the
    // app was closed (or the OS dropped them, e.g. after a reboot).
    await _systemAlarms.syncAlarms(state);
  }

  Future<void> addAlarm(Alarm alarm) async {
    state = _sorted([...state, alarm]);
    await _persist();
  }

  Future<void> updateAlarm(Alarm updated) async {
    state = _sorted([
      for (final Alarm a in state) if (a.id == updated.id) updated else a,
    ]);
    await _persist();
  }

  Future<void> removeAlarm(String id) async {
    state = state.where((Alarm a) => a.id != id).toList();
    await _persist();
  }

  Future<void> toggleAlarm(String id, bool isEnabled) async {
    state = [
      for (final Alarm a in state)
        if (a.id == id) a.copyWith(isEnabled: isEnabled) else a,
    ];
    await _persist();
  }

  /// Stops the ringing OS alarm, turns off one-time alarms so they don't
  /// fire again tomorrow, and re-syncs so repeating alarms get their next
  /// occurrence scheduled.
  Future<void> dismissRinging(Alarm alarm) async {
    await _systemAlarms.stopRinging(alarm);
    final int index = state.indexWhere((Alarm a) => a.id == alarm.id);
    if (index != -1 && !state[index].isRepeating) {
      state = [
        for (final Alarm a in state)
          if (a.id == alarm.id) a.copyWith(isEnabled: false) else a,
      ];
    }
    await _persist();
  }

  /// Stops the ringing OS alarm and schedules a one-time alarm [delay] from
  /// now in its place.
  Future<void> snoozeRinging(
    Alarm alarm, {
    Duration delay = const Duration(minutes: 5),
  }) async {
    await _systemAlarms.stopRinging(alarm);
    final DateTime snoozeAt = PhilippineTime.now().add(delay);
    await addAlarm(Alarm(
      id: 'snooze-${DateTime.now().microsecondsSinceEpoch}',
      hour: snoozeAt.hour,
      minute: snoozeAt.minute,
      label: alarm.label.isEmpty ? 'Snooze' : '${alarm.label} (snoozed)',
    ));
  }

  /// Saves the list and mirrors it into the OS alarm schedule, so storage
  /// and "what will actually ring" can never drift apart.
  Future<void> _persist() async {
    await _repository.saveAlarms(state);
    await _systemAlarms.syncAlarms(state);
  }

  List<Alarm> _sorted(List<Alarm> alarms) {
    final List<Alarm> copy = [...alarms];
    copy.sort(
      (Alarm a, Alarm b) =>
          (a.hour * 60 + a.minute).compareTo(b.hour * 60 + b.minute),
    );
    return copy;
  }
}

final NotifierProvider<AlarmListNotifier, List<Alarm>> alarmListProvider =
    NotifierProvider<AlarmListNotifier, List<Alarm>>(AlarmListNotifier.new);
