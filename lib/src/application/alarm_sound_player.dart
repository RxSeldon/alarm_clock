import 'dart:async';

import 'package:flutter/services.dart';

/// Plays the "an alarm is ringing" feedback.
///
/// Kept as a two-method abstraction (`start`/`stop`) so the ringing screen
/// never needs to know *how* the alert is produced -- system sound, a real
/// ringtone file, a plugin, etc. -- only that it can be started and stopped
/// (Interface Segregation + Dependency Inversion).
abstract interface class AlarmSoundPlayer {
  void start();

  void stop();
}

/// Repeats the platform alert sound and a haptic pulse until stopped.
///
/// This avoids bundling a proprietary audio asset/plugin for what is a
/// classroom project; swapping in a real ringtone later only means writing a
/// new [AlarmSoundPlayer] implementation.
class SystemAlarmSoundPlayer implements AlarmSoundPlayer {
  Timer? _timer;

  @override
  void start() {
    stop();
    _timer = Timer.periodic(const Duration(milliseconds: 800), (_) {
      SystemSound.play(SystemSoundType.alert);
      HapticFeedback.heavyImpact();
    });
  }

  @override
  void stop() {
    _timer?.cancel();
    _timer = null;
  }
}
