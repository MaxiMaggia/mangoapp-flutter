import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

import 'entity_status.dart';

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
  final DateTime? updatedAt;
  final EntityStatus status;

  Category({
    this.id,
    required this.userId,
    required this.title,
    required this.iconKey,
    required this.colorValue,
    DateTime? createdAt,
    this.updatedAt,
    this.status = EntityStatus.available,
  }) : createdAt = createdAt ?? DateTime.now();

  Color get color => Color(colorValue);

  Category copyWith({
    String? id,
    String? userId,
    String? title,
    String? iconKey,
    int? colorValue,
    DateTime? createdAt,
    DateTime? updatedAt,
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
        status,
      ];

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'title': title,
      'iconKey': iconKey,
      'colorValue': colorValue,
      'createdAt': Timestamp.fromDate(createdAt),
      if (updatedAt != null) 'updatedAt': Timestamp.fromDate(updatedAt!),
      'status': status.name,
    };
  }

  static Category fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
    SnapshotOptions? options,
  ) {
    final data = snapshot.data()!;
    return Category(
      id: snapshot.id,
      userId: data['userId'] as String,
      title: data['title'] as String,
      iconKey: data['iconKey'] as String,
      colorValue: data['colorValue'] as int,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: data['updatedAt'] != null
          ? (data['updatedAt'] as Timestamp).toDate()
          : null,
      status: EntityStatus.values.byName(
        (data['status'] as String?) ?? EntityStatus.available.name,
      ),
    );
  }
}

extension CategoryValidator on Category {
  bool get isValid => isTitleValid;
  bool get isTitleValid => title.trim().isNotEmpty;
}
