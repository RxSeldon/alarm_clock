/// Wall-clock time for the Philippines, independent of the device timezone.
///
/// The app always displays and schedules against Philippine Standard Time.
/// PHT is a fixed UTC+8 offset with no daylight saving, so we can derive it
/// from UTC arithmetic without pulling in a full timezone database.
///
/// The returned [DateTime] is flagged UTC but has already been shifted by
/// +8 hours, so reading `.hour`, `.minute`, `.weekday`, `.day`, etc. off it
/// yields the correct Philippine local values.
class PhilippineTime {
  const PhilippineTime._();

  /// UTC+8, the Philippines' fixed offset from UTC.
  static const Duration _offset = Duration(hours: 8);

  /// "Now" in Philippine Standard Time.
  static DateTime now() => DateTime.now().toUtc().add(_offset);

  /// Converts a PHT wall-clock value (in the shifted-UTC form produced by
  /// [now]) into the same instant expressed in the device's local time --
  /// the form the OS wants when scheduling a real alarm.
  static DateTime toDeviceTime(DateTime phtTime) =>
      phtTime.subtract(_offset).toLocal();

  /// The reverse of [toDeviceTime]: a device-local instant as PHT wall time.
  static DateTime fromDeviceTime(DateTime deviceTime) =>
      deviceTime.toUtc().add(_offset);
}
