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
  static final _longDate = DateFormat("d 'de' MMMM, y", 'es_AR');
  static final _monthLabel = DateFormat('MMM yyyy', 'es_AR');

  static String money(num value) => _money.format(value);
  static String usd(num value) => _moneyUsd.format(value);
  static String shortDate(DateTime date) => _shortDate.format(date);
  static String longDate(DateTime date) => _longDate.format(date);
  static String monthLabel(DateTime date) => _monthLabel.format(date);
}
