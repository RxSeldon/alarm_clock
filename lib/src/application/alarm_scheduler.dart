import '../domain/entities/alarm.dart';
import '../domain/entities/alarm_event.dart';
import 'clock_service.dart';

/// Turns "time passing" + "the current alarm list" into [AlarmEvent]s.
///
/// This is the event-producing half of the event-driven architecture: it has
/// exactly one job -- decide, on every clock tick, whether an alarm should
/// ring -- and knows nothing about sound, UI, or storage (Single
/// Responsibility Principle). It depends only on the [ClockService]
/// abstraction, not on where ticks actually come from (Dependency
/// Inversion).
class AlarmScheduler {
  AlarmScheduler(this._clock);

  final ClockService _clock;

  /// Tracks the last minute each alarm fired on, so a match that stays true
  /// for the whole 60-second window only produces a single event.
  final Map<String, String> _lastFiredKey = <String, String>{};

  /// Combines the clock stream with the caller-supplied alarm list and emits
  /// an [AlarmRingingEvent] whenever an enabled alarm matches "now".
  ///
  /// [alarms] is read fresh on every tick (rather than captured once) so the
  /// scheduler always reacts to the latest set of alarms without needing to
  /// be recreated when the user adds, edits, or removes one.
  Stream<AlarmEvent> watch(List<Alarm> Function() alarms) {
    return _clock.onTick
        .map((DateTime now) => _matchAlarm(now, alarms()))
        .where((AlarmEvent? event) => event != null)
        .cast<AlarmEvent>();
  }

  AlarmEvent? _matchAlarm(DateTime now, List<Alarm> alarms) {
    for (final Alarm alarm in alarms) {
      if (!alarm.isEnabled) continue;
      if (alarm.hour != now.hour || alarm.minute != now.minute) continue;
      if (alarm.isRepeating && !alarm.repeatDays.contains(now.weekday)) {
        continue;
      }

      final String minuteKey =
          '${now.year}-${now.month}-${now.day}-${now.hour}-${now.minute}';
      if (_lastFiredKey[alarm.id] == minuteKey) continue;

      _lastFiredKey[alarm.id] = minuteKey;
      return AlarmRingingEvent(alarm);
    }
    return null;
  }
}
