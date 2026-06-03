import 'package:intl/intl.dart';

/// Helpers de formato. Locale fijo en es_AR para Mango.
class Fmt {
  static final _money = NumberFormat.currency(
    locale: 'es_AR',
    symbol: '\$',
    decimalDigits: 0,
  );

  static final _moneyUsd = NumberFormat.currency(
    locale: 'en_US',
    symbol: 'US\$',
    decimalDigits: 2,
  );

  static final _shortDate = DateFormat('dd/MM/yyyy', 'es_AR');
  static final _dateTime = DateFormat('dd/MM/yyyy HH:mm', 'es_AR');
  static final _longDate = DateFormat("d 'de' MMMM, y", 'es_AR');
  static final _monthLabel = DateFormat('MMM yyyy', 'es_AR');

  // Monto en pesos sin decimales, tipo "$ 1.234".
  static String money(num value) => _money.format(value);
  // Monto en dolares con 2 decimales, tipo "US$ 12,34".
  static String usd(num value) => _moneyUsd.format(value);
  // Fecha cortita "dd/MM/yyyy".
  static String shortDate(DateTime date) => _shortDate.format(date);
  // Fecha con hora "dd/MM/yyyy HH:mm".
  static String dateTime(DateTime date) => _dateTime.format(date);
  // Fecha larga "1 de mayo, 2026".
  static String longDate(DateTime date) => _longDate.format(date);
  // Mes y año abreviado "may 2026".
  static String monthLabel(DateTime date) => _monthLabel.format(date);

  /// "Mayo 2026" (con inicial mayúscula; es_AR lo devuelve en minúscula).
  static String monthYear(DateTime date) {
    final formatted = DateFormat('MMMM yyyy', 'es_AR').format(date);
    return formatted[0].toUpperCase() + formatted.substring(1);
  }
}
