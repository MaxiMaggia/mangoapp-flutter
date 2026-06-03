import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

import 'entity_status.dart';

/// Una categoria de gasto del usuario.
///
/// `iconKey` referencia un icono predefinido en CategoryIcons.
/// `colorValue` se guarda como int (Color.value) para serializar facil.
class Category extends Equatable {
  final String? id;          // null hasta que Firestore le asigna uno al guardar.
  final String userId;       // De quien es la categoria.
  final String title;
  final String iconKey;      // Nombre del icono predefinido (ver CategoryIcons).
  final int colorValue;      // El color guardado como int para poder serializarlo.
  final DateTime createdAt;
  final DateTime updatedAt; // siempre presente: igual a createdAt al crear.
  final DateTime? deletedAt; // momento del borrado logico (null si esta viva).
  final EntityStatus status; // available o deleted (soft delete).

  Category({
    this.id,
    required this.userId,
    required this.title,
    required this.iconKey,
    required this.colorValue,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.deletedAt,
    this.status = EntityStatus.available,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? (createdAt ?? DateTime.now());

  // Convierte el int guardado de vuelta a un Color usable en la UI.
  Color get color => Color(colorValue);

  // Devuelve una copia cambiando solo los campos que le pases.
  Category copyWith({
    String? id,
    String? userId,
    String? title,
    String? iconKey,
    int? colorValue,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? deletedAt,
    bool clearDeletedAt = false,
    EntityStatus? status,
  }) =>
      Category(
        id: id ?? this.id,
        userId: userId ?? this.userId,
        title: title ?? this.title,
        iconKey: iconKey ?? this.iconKey,
        colorValue: colorValue ?? this.colorValue,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        deletedAt: clearDeletedAt ? null : (deletedAt ?? this.deletedAt),
        status: status ?? this.status,
      );

  @override
  List<Object?> get props => [
        id,
        userId,
        title,
        iconKey,
        colorValue,
        createdAt,
        updatedAt,
        deletedAt,
        status,
      ];

  // Arma el mapa que se manda a Firestore al guardar la categoria.
  Map<String, dynamic> toFirestore() {
    return {
      if (id != null) 'id': id,
      'userId': userId,
      'title': title,
      'iconKey': iconKey,
      'colorValue': colorValue,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      if (deletedAt != null) 'deletedAt': Timestamp.fromDate(deletedAt!),
      'status': status.name,
    };
  }

  // Reconstruye una Category a partir del documento que vuelve de Firestore.
  static Category fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
    SnapshotOptions? options,
  ) {
    final data = snapshot.data()!;
    return Category(
      id: (data['id'] as String?) ?? snapshot.id,
      userId: data['userId'] as String,
      title: data['title'] as String,
      iconKey: data['iconKey'] as String,
      colorValue: data['colorValue'] as int,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: data['updatedAt'] != null
          ? (data['updatedAt'] as Timestamp).toDate()
          : (data['createdAt'] as Timestamp).toDate(),
      deletedAt: data['deletedAt'] != null
          ? (data['deletedAt'] as Timestamp).toDate()
          : null,
      status: EntityStatus.values.byName(
        (data['status'] as String?) ?? EntityStatus.available.name,
      ),
    );
  }
}

// Validaciones de la categoria antes de guardarla.
extension CategoryValidator on Category {
  bool get isValid => isTitleValid;
  // El titulo no puede estar vacio (ni solo espacios).
  bool get isTitleValid => title.trim().isNotEmpty;
}
