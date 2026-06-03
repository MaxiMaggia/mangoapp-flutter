import 'package:equatable/equatable.dart';

/// Cotización del dólar devuelta por dolarapi.com.
///
/// `casa` es el identificador de la casa de cambio según la API
/// ('oficial', 'blue', 'bolsa', 'tarjeta', etc.).
class DolarQuote extends Equatable {
  final String casa;
  final String nombre;
  final double compra; // a cuanto te compran el dolar
  final double venta; // a cuanto te lo venden
  final DateTime fechaActualizacion; // ultima vez que la API actualizo el valor

  const DolarQuote({
    required this.casa,
    required this.nombre,
    required this.compra,
    required this.venta,
    required this.fechaActualizacion,
  });

  // Arma una cotizacion a partir del JSON que devuelve dolarapi.com.
  factory DolarQuote.fromJson(Map<String, dynamic> json) => DolarQuote(
        casa: json['casa'] as String,
        nombre: json['nombre'] as String,
        compra: (json['compra'] as num).toDouble(),
        venta: (json['venta'] as num).toDouble(),
        fechaActualizacion:
            DateTime.parse(json['fechaActualizacion'] as String),
      );

  @override
  List<Object?> get props =>
      [casa, nombre, compra, venta, fechaActualizacion];
}
