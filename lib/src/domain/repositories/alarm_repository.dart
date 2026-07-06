import '../entities/alarm.dart';

/// Persistence contract for alarms.
///
/// The rest of the app depends on this abstraction rather than a concrete
/// storage mechanism (Dependency Inversion Principle). Swapping
/// `shared_preferences` for, say, a local database only means writing a new
/// class that implements this interface -- nothing else in the app changes
/// (Open/Closed Principle).
abstract interface class AlarmRepository {
  Future<List<Alarm>> loadAlarms();

  Future<void> saveAlarms(List<Alarm> alarms);
}
