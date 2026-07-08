// Shared test doubles, so widget tests can reach the home screen without
// Firebase and exercise the alarm flow without the OS alarm plugin.

import 'dart:async';

import 'package:alarm_clock_app/src/application/clock_service.dart';
import 'package:alarm_clock_app/src/application/system_alarm_service.dart';
import 'package:alarm_clock_app/src/domain/entities/alarm.dart';
import 'package:alarm_clock_app/src/domain/entities/app_user.dart';
import 'package:alarm_clock_app/src/domain/repositories/auth_repository.dart';

/// An [AuthRepository] that is permanently signed in as [user] -- exactly the
/// kind of substitution the [AuthRepository] abstraction exists to enable.
class FakeSignedInAuthRepository implements AuthRepository {
  const FakeSignedInAuthRepository();

  static const AppUser user = AppUser(
    uid: 'test-uid',
    email: 'tester@example.com',
  );

  @override
  Stream<AppUser?> authStateChanges() => Stream<AppUser?>.value(user);

  @override
  AppUser? get currentUser => user;

  @override
  Future<void> register({required String email, required String password})
      async {}

  @override
  Future<void> signIn({required String email, required String password})
      async {}

  @override
  Future<void> signOut() async {}
}

/// A [SystemAlarmService] that never talks to the OS: no alarms are
/// scheduled and no permissions are requested. Tests can make an alarm
/// "ring" on demand by adding it to [ringController].
class FakeSystemAlarmService extends SystemAlarmService {
  final StreamController<Alarm> ringController =
      StreamController<Alarm>.broadcast();

  @override
  Future<void> requestPermissions() async {}

  @override
  Stream<Alarm> onAlarmRinging(List<Alarm> Function() currentAlarms) =>
      ringController.stream;

  @override
  Future<void> syncAlarms(List<Alarm> alarms) async {}

  @override
  Future<void> stopRinging(Alarm alarm) async {}
}

/// A [ClockService] that never ticks, so tests don't depend on a real
/// periodic [Timer].
class FakeClockService implements ClockService {
  @override
  Stream<DateTime> get onTick => const Stream<DateTime>.empty();
}
