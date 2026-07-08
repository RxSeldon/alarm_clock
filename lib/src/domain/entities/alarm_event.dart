import 'package:flutter/foundation.dart';

import 'alarm.dart';

/// Base type for events produced by the alarm engine.
///
/// This is the "event" side of the event-driven architecture: the
/// `SystemAlarmService` (application layer) emits these when an OS alarm
/// fires, and the presentation layer reacts to them (e.g. by pushing the
/// ringing screen) without either side knowing the concrete details of the
/// other.
@immutable
sealed class AlarmEvent {
  const AlarmEvent();
}

/// Emitted the moment the wall-clock time matches an enabled [Alarm].
class AlarmRingingEvent extends AlarmEvent {
  const AlarmRingingEvent(this.alarm);

  final Alarm alarm;
}
