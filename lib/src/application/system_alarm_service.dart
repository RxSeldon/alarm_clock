import 'package:alarm/alarm.dart' as system;
import 'package:alarm/utils/alarm_set.dart' as system;
import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';

import '../domain/entities/alarm.dart';
import 'philippine_time.dart';

/// Bridges the app's domain [Alarm]s to real operating-system alarms.
///
/// The previous implementation checked the time with an in-app [Stream] and
/// only worked while the app was open and on screen. This service instead
/// registers each enabled alarm with the OS (via the `alarm` plugin), so it
/// fires with sound, vibration, and a full-screen notification even when the
/// app is in the background, the screen is locked, or the app was killed.
///
/// It is the only class that touches the plugin: the rest of the app keeps
/// talking in domain [Alarm]s and [Stream]s (Dependency Inversion), exactly
/// like the old tick-based scheduler it replaces.
class SystemAlarmService {
  /// Plugin ids seen ringing on the previous emission of [onAlarmRinging],
  /// so each ring produces exactly one event.
  Set<int> _previouslyRinging = <int>{};

  /// Boots the plugin. Must run once before `runApp`, so alarms that were
  /// scheduled in a previous session (or are ringing right now) are restored.
  static Future<void> ensureInitialized() => system.Alarm.init();

  /// Asks for the runtime permissions real alarms need on modern Android:
  /// notifications (Android 13+) and, if the OS revoked it, exact alarms.
  /// Safe to call every launch -- it only prompts while not yet granted.
  Future<void> requestPermissions() async {
    try {
      await Permission.notification.request();
      if (!await Permission.scheduleExactAlarm.isGranted) {
        await Permission.scheduleExactAlarm.request();
      }
    } catch (error) {
      // Platform without the plugin (tests, desktop): alarms are best-effort.
      debugPrint('Alarm permission request unavailable: $error');
    }
  }

  /// Emits the domain [Alarm] each time an OS alarm starts ringing.
  ///
  /// [currentAlarms] is read at emission time so the event always carries the
  /// latest saved version of the alarm (same pattern the old scheduler used).
  Stream<Alarm> onAlarmRinging(List<Alarm> Function() currentAlarms) {
    return system.Alarm.ringing.expand((system.AlarmSet ringing) {
      debugPrint('RINGDBG service: set=${ringing.alarms.map((a) => a.id)} '
          'prev=$_previouslyRinging');
      final List<system.AlarmSettings> started = ringing.alarms
          .where((system.AlarmSettings s) => !_previouslyRinging.contains(s.id))
          .toList();
      _previouslyRinging =
          ringing.alarms.map((system.AlarmSettings s) => s.id).toSet();

      // Map each newly ringing OS alarm to its domain alarm. Guarded per
      // alarm: if one mapping fails the ring event must still reach the UI,
      // so the failure falls back to a bare alarm instead of erroring (and
      // thereby killing) the whole event stream.
      final List<Alarm> events = <Alarm>[];
      for (final system.AlarmSettings settings in started) {
        try {
          events.add(_toDomain(settings, currentAlarms()));
        } catch (error) {
          debugPrint('Could not map ringing alarm ${settings.id}: $error');
          final DateTime pht = PhilippineTime.fromDeviceTime(settings.dateTime);
          events.add(Alarm(
            id: settings.payload ?? 'os-${settings.id}',
            hour: pht.hour,
            minute: pht.minute,
          ));
        }
      }
      debugPrint('RINGDBG service: emitting ${events.length} event(s)');
      return events;
    });
  }

  /// Makes the OS schedule mirror [alarms]: every enabled alarm gets an OS
  /// alarm at its next occurrence; everything else is cancelled.
  Future<void> syncAlarms(List<Alarm> alarms) async {
    try {
      final DateTime nowPht = PhilippineTime.now();
      final Map<int, Alarm> wanted = <int, Alarm>{
        for (final Alarm alarm in alarms)
          if (alarm.isEnabled) platformId(alarm.id): alarm,
      };

      // Cancel OS alarms whose app-side alarm was deleted or switched off.
      for (final system.AlarmSettings scheduled
          in await system.Alarm.getAlarms()) {
        if (!wanted.containsKey(scheduled.id)) {
          await system.Alarm.stop(scheduled.id);
        }
      }

      // Ids ringing right now are left alone: re-registering one would stop
      // its sound mid-ring. Their next occurrence is scheduled by the sync
      // that runs when the user dismisses or snoozes them.
      final Set<int> ringingNow = system.Alarm.ringing.value.alarms
          .map((system.AlarmSettings s) => s.id)
          .toSet();

      for (final MapEntry<int, Alarm> entry in wanted.entries) {
        if (ringingNow.contains(entry.key)) continue;
        final DateTime? triggerAt = _nextTrigger(entry.value, nowPht);
        if (triggerAt == null) continue;
        await system.Alarm.set(
          alarmSettings: _settingsFor(entry.key, entry.value, triggerAt),
        );
      }
    } catch (error) {
      debugPrint('Could not sync alarms with the OS: $error');
    }
  }

  /// Silences the currently ringing OS alarm for [alarm].
  Future<void> stopRinging(Alarm alarm) async {
    try {
      await system.Alarm.stop(platformId(alarm.id));
    } catch (error) {
      debugPrint('Could not stop ringing alarm: $error');
    }
  }

  /// Derives the plugin's required `int` id from the domain's `String` id
  /// (FNV-1a, folded to a positive 31-bit value; 0 and -1 are reserved by
  /// the plugin). Deterministic, so the same alarm always maps to the same
  /// OS alarm across app restarts.
  static int platformId(String alarmId) {
    int hash = 0x811c9dc5;
    for (final int unit in alarmId.codeUnits) {
      hash ^= unit;
      hash = (hash * 0x01000193) & 0x7fffffff;
    }
    return hash == 0 ? 1 : hash;
  }

  /// The next moment [alarm] should ring, in device time, or `null` if none.
  ///
  /// Computed in Philippine wall-clock space (same rules the app displays),
  /// then converted to an absolute device-local instant for the OS.
  DateTime? _nextTrigger(Alarm alarm, DateTime nowPht) {
    final DateTime todayAtAlarm = DateTime.utc(
      nowPht.year,
      nowPht.month,
      nowPht.day,
      alarm.hour,
      alarm.minute,
    );

    if (!alarm.isRepeating) {
      final DateTime next = todayAtAlarm.isAfter(nowPht)
          ? todayAtAlarm
          : todayAtAlarm.add(const Duration(days: 1));
      return PhilippineTime.toDeviceTime(next);
    }

    for (int daysAhead = 0; daysAhead <= 7; daysAhead++) {
      final DateTime candidate = todayAtAlarm.add(Duration(days: daysAhead));
      if (candidate.isAfter(nowPht) &&
          alarm.repeatDays.contains(candidate.weekday)) {
        return PhilippineTime.toDeviceTime(candidate);
      }
    }
    return null;
  }

  system.AlarmSettings _settingsFor(
    int id,
    Alarm alarm,
    DateTime triggerAt,
  ) {
    return system.AlarmSettings(
      id: id,
      dateTime: triggerAt,
      // null = the device's default alarm ringtone.
      assetAudioPath: null,
      volumeSettings: const system.VolumeSettings.fixed(),
      notificationSettings: system.NotificationSettings(
        title: alarm.label.isEmpty ? 'Alarm' : alarm.label,
        body: 'It is ${_twelveHour(alarm.hour, alarm.minute)} — '
            'open to snooze or dismiss',
      ),
      // Android alarms survive the app being killed; only iOS needs the
      // "reopen the app" warning.
      warningNotificationOnKill: defaultTargetPlatform == TargetPlatform.iOS,
      // Carries the domain id so a ringing OS alarm can be traced back to
      // the saved alarm that produced it.
      payload: alarm.id,
    );
  }

  Alarm _toDomain(system.AlarmSettings settings, List<Alarm> alarms) {
    for (final Alarm alarm in alarms) {
      if (alarm.id == settings.payload) return alarm;
    }
    // The saved alarm is gone (e.g. deleted after scheduling): fall back to
    // a one-off built from the ring time so the UI can still show it.
    final DateTime pht = PhilippineTime.fromDeviceTime(settings.dateTime);
    return Alarm(
      id: settings.payload ?? 'os-${settings.id}',
      hour: pht.hour,
      minute: pht.minute,
    );
  }

  static String _twelveHour(int hour, int minute) {
    final int displayHour = hour % 12 == 0 ? 12 : hour % 12;
    final String paddedMinute = minute.toString().padLeft(2, '0');
    return '$displayHour:$paddedMinute ${hour >= 12 ? 'PM' : 'AM'}';
  }
}
