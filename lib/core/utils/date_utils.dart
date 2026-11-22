import 'package:intl/intl.dart';

class ArabicDateUtils {
  static final DateFormat _arabicDateFormat = DateFormat('yyyy/MM/dd', 'ar');
  static final DateFormat _arabicDateLongFormat = DateFormat('d MMMM yyyy', 'ar');

  static String formatDate(dynamic date) {
    if (date == null) return '—';
    DateTime? dt;
    if (date is DateTime) {
      dt = date;
    } else if (date is String) {
      if (date.trim().isEmpty) return '—';
      try {
        dt = DateTime.parse(date);
      } catch (_) {
        return date;
      }
    }
    if (dt == null) return '—';
    return _arabicDateFormat.format(dt);
  }

  static String formatDateLong(dynamic date) {
    if (date == null) return '—';
    DateTime? dt;
    if (date is DateTime) {
      dt = date;
    } else if (date is String) {
      if (date.trim().isEmpty) return '—';
      try {
        dt = DateTime.parse(date);
      } catch (_) {
        return date;
      }
    }
    if (dt == null) return '—';
    return _arabicDateLongFormat.format(dt);
  }

  /// Calculates months since last donation to assess donation eligibility
  /// Typically 3 months (90 days) for men, 4 months for women
  static int? daysSince(DateTime? date) {
    if (date == null) return null;
    return DateTime.now().difference(date).inDays;
  }
}
