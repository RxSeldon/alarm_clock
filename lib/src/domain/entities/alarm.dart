import 'dart:convert';

import 'package:flutter/foundation.dart';

/// A single alarm configured by the user.
///
/// This is a plain domain entity: it has no dependency on Flutter widgets,
/// Riverpod, or storage. Anything that needs to read or persist an [Alarm]
/// depends on this type, never the other way around.
@immutable
class Alarm {
  const Alarm({
    required this.id,
    required this.hour,
    required this.minute,
    this.label = '',
    this.isEnabled = true,
    this.repeatDays = const <int>{},
  });

  /// Stable unique identifier, generated once when the alarm is created.
  final String id;

  /// 0-23.
  final int hour;

  /// 0-59.
  final int minute;

  /// Optional user-facing note, e.g. "Gym" or "Take medicine".
  final String label;

  final bool isEnabled;

  /// Days of the week the alarm repeats on, using [DateTime.weekday] values
  /// (1 = Monday ... 7 = Sunday). An empty set means "one-time alarm".
  final Set<int> repeatDays;

  bool get isRepeating => repeatDays.isNotEmpty;

  Alarm copyWith({
    String? id,
    int? hour,
    int? minute,
    String? label,
    bool? isEnabled,
    Set<int>? repeatDays,
  }) {
    return Alarm(
      id: id ?? this.id,
      hour: hour ?? this.hour,
      minute: minute ?? this.minute,
      label: label ?? this.label,
      isEnabled: isEnabled ?? this.isEnabled,
      repeatDays: repeatDays ?? this.repeatDays,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'hour': hour,
      'minute': minute,
      'label': label,
      'isEnabled': isEnabled,
      'repeatDays': repeatDays.toList(),
    };
  }

  factory Alarm.fromMap(Map<String, dynamic> map) {
    return Alarm(
      id: map['id'] as String,
      hour: map['hour'] as int,
      minute: map['minute'] as int,
      label: map['label'] as String? ?? '',
      isEnabled: map['isEnabled'] as bool? ?? true,
      repeatDays: <int>{
        ...((map['repeatDays'] as List<dynamic>? ?? const <dynamic>[])
            .map((dynamic e) => e as int)),
      },
    );
  }

  String encode() => jsonEncode(toMap());

  factory Alarm.decode(String source) =>
      Alarm.fromMap(jsonDecode(source) as Map<String, dynamic>);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Alarm &&
        other.id == id &&
        other.hour == hour &&
        other.minute == minute &&
        other.label == label &&
        other.isEnabled == isEnabled &&
        other.repeatDays.length == repeatDays.length &&
        other.repeatDays.containsAll(repeatDays);
  }

  @override
  int get hashCode => Object.hash(
        id,
        hour,
        minute,
        label,
        isEnabled,
        Object.hashAllUnordered(repeatDays),
      );
}
