import 'philippine_time.dart';

/// Produces a heartbeat of wall-clock time.
///
/// This is the root of the app's stream architecture: everything that needs
/// "now" (the on-screen clock, the alarm scheduler) subscribes to
/// [onTick] instead of polling `DateTime.now()` directly. Depending on this
/// interface -- rather than a concrete timer -- means the clock source can be
/// swapped (e.g. for a fake clock in tests) without touching any consumer
/// (Dependency Inversion + Interface Segregation: this contract exposes
/// nothing but the one stream consumers need).
abstract interface class ClockService {
  Stream<DateTime> get onTick;
}

/// [ClockService] driven by a real one-second system timer.
class SystemClockService implements ClockService {
  /// A single broadcast stream shared by every listener, so the underlying
  /// timer is created once no matter how many widgets/providers watch it.
  late final Stream<DateTime> _stream = Stream<DateTime>.periodic(
    const Duration(seconds: 1),
    (_) => PhilippineTime.now(),
  ).asBroadcastStream();

  @override
  Stream<DateTime> get onTick => _stream;
}
