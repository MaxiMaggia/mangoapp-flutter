import 'package:flutter/material.dart';

/// Catalogo cerrado de iconos para categorias.
///
/// Cada categoria guarda un `iconKey` (string) que mapea a uno de estos.
/// Se evita Firebase Storage en esta primera version.
class CategoryIconOption {
  final String key;
  final IconData icon;
  final String label;
  const CategoryIconOption(
      {required this.key, required this.icon, required this.label});
}

class CategoryIcons {
  static const food = CategoryIconOption(
      key: 'food', icon: Icons.restaurant, label: 'Comida');
  static const transport = CategoryIconOption(
      key: 'transport', icon: Icons.directions_car, label: 'Transporte');
  static const entertainment = CategoryIconOption(
      key: 'entertainment',
      icon: Icons.sports_esports,
      label: 'Entretenimiento');
  static const home =
      CategoryIconOption(key: 'home', icon: Icons.home, label: 'Hogar');
  static const education = CategoryIconOption(
      key: 'education', icon: Icons.school, label: 'Educacion');
  static const health = CategoryIconOption(
      key: 'health', icon: Icons.local_hospital, label: 'Salud');
  static const shopping = CategoryIconOption(
      key: 'shopping', icon: Icons.shopping_bag, label: 'Compras');
  static const services = CategoryIconOption(
      key: 'services', icon: Icons.receipt_long, label: 'Servicios');
  static const work =
      CategoryIconOption(key: 'work', icon: Icons.work, label: 'Trabajo');
  static const travel = CategoryIconOption(
      key: 'travel', icon: Icons.flight_takeoff, label: 'Viajes');
  static const gifts = CategoryIconOption(
      key: 'gifts', icon: Icons.card_giftcard, label: 'Regalos');
  static const other = CategoryIconOption(
      key: 'other', icon: Icons.category, label: 'Otros');

  static const all = [
    food,
    transport,
    entertainment,
    home,
    education,
    health,
    shopping,
    services,
    work,
    travel,
    gifts,
    other,
  ];

  /// Devuelve el IconData a partir de la key guardada en la entidad.
  /// Si no existe la key, devuelve el icono "Otros".
  static IconData iconFor(String key) {
    return all
            .firstWhere((o) => o.key == key, orElse: () => other)
            .icon;
  }
}

/// Paleta de colores sugeridos para categorias.
class CategoryColors {
  static const palette = <int>[
    0xFFEF4444, // rojo
    0xFFF59E0B, // ambar
    0xFF10B981, // verde
    0xFF3B82F6, // azul
    0xFFA855F7, // violeta
    0xFFEC4899, // rosa
    0xFF14B8A6, // teal
    0xFF6366F1, // indigo
    0xFFF97316, // naranja
    0xFF84CC16, // lima
  ];
}
