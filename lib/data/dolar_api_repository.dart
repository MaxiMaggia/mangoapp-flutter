import 'dart:convert';

import 'package:http/http.dart' as http;

import '../domain/dolar_quote.dart';
import '../domain/dolar_repository.dart';

class DolarApiRepository implements DolarRepository {
  static const _baseUrl = 'https://dolarapi.com/v1/dolares';

  @override
  Future<List<DolarQuote>> getQuotes() async {
    final response = await http.get(Uri.parse(_baseUrl));
    if (response.statusCode != 200) {
      throw Exception(
        'Error al obtener cotizaciones: ${response.statusCode}',
      );
    }
    final List<dynamic> data = jsonDecode(response.body) as List<dynamic>;
    return data
        .map((json) => DolarQuote.fromJson(json as Map<String, dynamic>))
        .toList();
  }
}
