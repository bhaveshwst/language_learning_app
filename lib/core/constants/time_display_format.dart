import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Converts backend 24-hour clock strings to localized 12-hour display (AM/PM).
/// API payloads must continue to use the original 24-hour strings unchanged.
class TimeDisplayFormat {
  TimeDisplayFormat._();

  static DateTime? _tryParseApiClockToDate(String raw) {
    final normalized = raw.trim().replaceAll('.', ':');
    if (normalized.isEmpty) return null;
    final lower = normalized.toLowerCase();
    if (lower.contains('am') || lower.contains('pm')) return null;

    final segs = normalized.split(':');
    final h = int.tryParse(segs[0].trim());
    if (h == null || h < 0 || h > 23) return null;
    final m = segs.length > 1 ? (int.tryParse(segs[1].trim()) ?? 0) : 0;
    if (m < 0 || m > 59) return null;
    return DateTime(2000, 1, 1, h, m);
  }

  /// e.g. `20:30` / `20:30:00` → `8:30 PM` (locale-dependent).
  static String formatApiClockForDisplay(String raw, Locale locale) {
    final dt = _tryParseApiClockToDate(raw);
    if (dt == null) return raw.trim();
    return DateFormat.jm(locale.toString()).format(dt);
  }

  /// e.g. `20:30` + `21:00` → `8:30 PM - 9:00 PM`.
  static String formatApiClockRangeForDisplay(
    String startRaw,
    String endRaw,
    Locale locale,
  ) {
    final a = startRaw.trim();
    final b = endRaw.trim();
    if (a.isEmpty && b.isEmpty) return '-';
    if (b.isEmpty) return formatApiClockForDisplay(a, locale);
    return '${formatApiClockForDisplay(a, locale)} - ${formatApiClockForDisplay(b, locale)}';
  }

  /// Parses a single-line range like `17:15:00 - 17:45:00` for display only.
  static String formatSlotRangeLabelForDisplay(String range, Locale locale) {
    final trimmed = range.trim();
    if (trimmed.isEmpty) return '-';
    final parts = trimmed
        .split(RegExp(r'\s*-\s*'))
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
    if (parts.isEmpty) return trimmed;
    if (parts.length == 1) {
      return formatApiClockForDisplay(parts.first, locale);
    }
    return '${formatApiClockForDisplay(parts.first, locale)} - ${formatApiClockForDisplay(parts.last, locale)}';
  }
}
