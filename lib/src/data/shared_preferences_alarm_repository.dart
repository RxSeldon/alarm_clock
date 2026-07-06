import 'package:shared_preferences/shared_preferences.dart';

import '../domain/entities/alarm.dart';
import '../domain/repositories/alarm_repository.dart';

/// [AlarmRepository] implementation backed by `shared_preferences`.
///
/// This class only knows how to turn a `List<Alarm>` into stored strings and
/// back -- it has no idea how the list is scheduled, displayed, or matched
/// against the clock (Single Responsibility Principle).
class SharedPreferencesAlarmRepository implements AlarmRepository {
  static const String _storageKey = 'alarms';

  @override
  Future<List<Alarm>> loadAlarms() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final List<String> raw = prefs.getStringList(_storageKey) ?? const <String>[];
    return raw.map(Alarm.decode).toList();
  }

  @override
  Future<void> saveAlarms(List<Alarm> alarms) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      _storageKey,
      alarms.map((Alarm a) => a.encode()).toList(),
    );
  }
}
