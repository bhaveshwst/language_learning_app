class TimezoneHelper {
  TimezoneHelper._();

  static String? matchDeviceTimezoneFromApi(List<String> apiTimezones) {
    if (apiTimezones.isEmpty) return null;

    final now = DateTime.now();
    final deviceOffsetLabel = _formatOffset(now.timeZoneOffset);
    final deviceAbbr = now.timeZoneName.trim().toUpperCase();

    for (final timezone in apiTimezones) {
      final parsed = _parseApiTimezone(timezone);
      if (parsed == null) continue;

      if (parsed.offsetLabel == deviceOffsetLabel) {
        return timezone;
      }
      if (deviceAbbr.isNotEmpty &&
          parsed.abbreviation.isNotEmpty &&
          parsed.abbreviation == deviceAbbr) {
        return timezone;
      }
    }

    return null;
  }

  static ({String offsetLabel, String abbreviation})? _parseApiTimezone(
    String raw,
  ) {
    final value = raw.trim();
    if (value.isEmpty) return null;

    final regex = RegExp(r'(UTC[+-]\d{1,2}(?::\d{2})?)\s*\(([^)]+)\)');
    final match = regex.firstMatch(value);
    if (match == null) return null;

    final offset = match.group(1)?.trim().toUpperCase() ?? '';
    final abbr = match.group(2)?.trim().toUpperCase() ?? '';
    if (offset.isEmpty) return null;

    return (offsetLabel: offset, abbreviation: abbr);
  }

  static String _formatOffset(Duration offset) {
    final sign = offset.isNegative ? '-' : '+';
    final totalMinutes = offset.inMinutes.abs();
    final hours = totalMinutes ~/ 60;
    final minutes = totalMinutes % 60;
    if (minutes == 0) {
      return 'UTC$sign$hours';
    }
    final minutePart = minutes.toString().padLeft(2, '0');
    return 'UTC$sign$hours:$minutePart';
  }
}
