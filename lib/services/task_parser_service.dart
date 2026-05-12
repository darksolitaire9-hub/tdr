import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'task_parser_service.g.dart';

@riverpod
class TaskParserService extends _$TaskParserService {
  @override
  void build() {}

  static const _kDays = [
    'monday', 'tuesday', 'wednesday', 'thursday',
    'friday', 'saturday', 'sunday',
  ];

  /// Returns `(DateTime, previewLabel)` or null if nothing recognised.
  (DateTime, String)? parseDate(String input) {
    if (input.trim().isEmpty) return null;
    final lower = input.toLowerCase();
    final now   = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    DateTime? base;
    String?   label;

    if (lower.contains('today')) {
      base  = today;
      label = 'Today';
    } else if (lower.contains('tomorrow')) {
      base  = today.add(const Duration(days: 1));
      label = 'Tomorrow';
    } else {
      for (var i = 0; i < _kDays.length; i++) {
        if (!lower.contains(_kDays[i])) continue;
        var daysAhead = (i + 1) - now.weekday;
        if (daysAhead <= 0) daysAhead += 7;
        if (lower.contains('next')) daysAhead += 7;
        base  = today.add(Duration(days: daysAhead));
        label = _kDays[i][0].toUpperCase() + _kDays[i].substring(1);
        break;
      }
    }

    if (base == null) return null;

    final timeRe = RegExp(r'(\d{1,2})(?::(\d{2}))?\s*(am|pm)', caseSensitive: false);
    final m = timeRe.firstMatch(lower);
    int hour = 0, minute = 0;
    String timePart = '';
    if (m != null) {
      hour   = int.parse(m.group(1)!);
      minute = int.parse(m.group(2) ?? '0');
      final ampm = m.group(3)!.toLowerCase();
      if (ampm == 'pm' && hour != 12) hour += 12;
      if (ampm == 'am' && hour == 12) hour = 0;
      timePart = ' ${_fmtTime(hour, minute)}';
    }

    return (
      DateTime(base.year, base.month, base.day, hour, minute),
      '$label$timePart',
    );
  }

  String _fmtTime(int hour, int minute) {
    final h   = hour % 12 == 0 ? 12 : hour % 12;
    final min = minute > 0 ? ':${minute.toString().padLeft(2, '0')}' : '';
    return '$h$min ${hour < 12 ? 'AM' : 'PM'}';
  }

  String stripDateTerms(String text) {
    String r = text;
    for (final d in _kDays) {
      r = r.replaceAll(RegExp(r'\b' + d + r'\b', caseSensitive: false), '');
    }
    r = r
        .replaceAll(RegExp(r'\btoday\b',    caseSensitive: false), '')
        .replaceAll(RegExp(r'\btomorrow\b', caseSensitive: false), '')
        .replaceAll(RegExp(r'\bnext\b',     caseSensitive: false), '')
        .replaceAll(RegExp(r'\b(at|@)\b',   caseSensitive: false), '')
        .replaceAll(RegExp(r'\d{1,2}(?::\d{2})?\s*(?:am|pm)', caseSensitive: false), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    return r;
  }
}
