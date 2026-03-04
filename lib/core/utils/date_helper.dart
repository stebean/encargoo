import 'package:intl/intl.dart';

class DateHelper {
  DateHelper._();

  static String formatDate(DateTime? date) {
    if (date == null) return 'Sin fecha';
    return DateFormat('d MMM yyyy', 'es').format(date);
  }

  static String formatShort(DateTime? date) {
    if (date == null) return '—';
    return DateFormat('d/M', 'es').format(date);
  }

  static String formatFull(DateTime date) {
    return DateFormat("EEEE d 'de' MMMM, yyyy", 'es').format(date);
  }

  static String formatRelative(DateTime? date) {
    if (date == null) return 'Sin fecha de entrega';
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(date.year, date.month, date.day);
    final diff = target.difference(today).inDays;

    if (diff < 0) return 'Atrasado ${-diff} día${-diff == 1 ? '' : 's'}';
    if (diff == 0) return '¡Entrega hoy!';
    if (diff == 1) return 'Entrega mañana';
    if (diff <= 3) return 'En $diff días';
    return DateHelper.formatDate(date);
  }

  static bool isOverdue(DateTime? date) {
    if (date == null) return false;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return DateTime(date.year, date.month, date.day).isBefore(today);
  }

  static bool isUrgent(DateTime? date) {
    if (date == null) return false;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(date.year, date.month, date.day);
    final diff = target.difference(today).inDays;
    return diff >= 0 && diff <= 3;
  }
}
