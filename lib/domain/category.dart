import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

/// Una categoria de gasto del usuario.
///
/// `iconKey` referencia un icono predefinido en CategoryIcons.
/// `colorValue` se guarda como int (Color.value) para serializar facil.
class Category extends Equatable {
  final String? id;
  final String userId;
  final String title;
  final String iconKey;
  final int colorValue;
  final DateTime createdAt;

  Category({
    this.id,
    required this.userId,
    required this.title,
    required this.iconKey,
    required this.colorValue,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Color get color => Color(colorValue);

  Category copyWith({
    String? id,
    String? userId,
    String? title,
    String? iconKey,
    int? colorValue,
    DateTime? createdAt,
  }) =>
      Category(
        id: id ?? this.id,
        userId: userId ?? this.userId,
        title: title ?? this.title,
        iconKey: iconKey ?? this.iconKey,
        colorValue: colorValue ?? this.colorValue,
        createdAt: createdAt ?? this.createdAt,
      );

  @override
  List<Object?> get props =>
      [id, userId, title, iconKey, colorValue, createdAt];
}

extension CategoryValidator on Category {
  bool get isValid => isTitleValid;
  bool get isTitleValid => title.trim().isNotEmpty;
}
