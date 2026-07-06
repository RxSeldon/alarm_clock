/// Every provider below wires an abstraction (left-hand type) to one
/// concrete implementation (right-hand constructor). Nothing in the
/// presentation layer ever instantiates [SystemClockService],
/// [SharedPreferencesAlarmRepository], etc. directly -- it only ever asks
/// Riverpod for the interface, which is what makes each piece swappable and
/// testable (Dependency Inversion Principle in practice).
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/alarm_scheduler.dart';
import '../../application/alarm_sound_player.dart';
import '../../application/clock_service.dart';
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

final Provider<AlarmSoundPlayer> alarmSoundPlayerProvider =
    Provider<AlarmSoundPlayer>((ref) {
  final SystemAlarmSoundPlayer player = SystemAlarmSoundPlayer();
  ref.onDispose(player.stop);
  return player;
});

final Provider<AlarmScheduler> alarmSchedulerProvider =
    Provider<AlarmScheduler>(
  (ref) => AlarmScheduler(ref.watch(clockServiceProvider)),
);

/// The live wall-clock time, ticking once per second. Backs the on-screen
/// digital clock.
final StreamProvider<DateTime> currentTimeProvider =
    StreamProvider<DateTime>((ref) {
  return ref.watch(clockServiceProvider).onTick;
});

/// The stream of alarm-triggered events. Screens subscribe via `ref.listen`
/// to react (e.g. push the ringing screen) without polling anything.
final StreamProvider<AlarmEvent> alarmEventProvider =
    StreamProvider<AlarmEvent>((ref) {
  final AlarmScheduler scheduler = ref.watch(alarmSchedulerProvider);
  return scheduler.watch(() => ref.read(alarmListProvider));
});

/// Owns the in-memory list of alarms and keeps it persisted through
/// [AlarmRepository]. This is the single place alarm CRUD happens; UI
/// widgets never mutate the list directly (Single Responsibility).
class AlarmListNotifier extends Notifier<List<Alarm>> {
  late final AlarmRepository _repository;

  @override
  List<Alarm> build() {
    _repository = ref.watch(alarmRepositoryProvider);
    _loadInitial();
    return <Alarm>[];
  }

  Future<void> _loadInitial() async {
    final List<Alarm> alarms = await _repository.loadAlarms();
    state = _sorted(alarms);
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

  /// Called when a one-time (non-repeating) alarm finishes ringing, so it
  /// doesn't fire again on the same saved time.
  Future<void> disableOneTimeAlarm(String id) async {
    final int index = state.indexWhere((Alarm a) => a.id == id);
    if (index == -1 || state[index].isRepeating) return;
    await toggleAlarm(id, false);
  }

  Future<void> _persist() => _repository.saveAlarms(state);

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
