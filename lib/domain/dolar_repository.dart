import 'dolar_quote.dart';

abstract interface class DolarRepository {
  Future<List<DolarQuote>> getQuotes();
}
