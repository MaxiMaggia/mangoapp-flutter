import 'dolar_quote.dart';

// Contrato para traer las cotizaciones del dolar (las saca de una API externa).
abstract interface class DolarRepository {
  // Trae la lista de cotizaciones actuales (oficial, blue, MEP, etc.).
  Future<List<DolarQuote>> getQuotes();
}
