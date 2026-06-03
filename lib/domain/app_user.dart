import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

import 'entity_status.dart';

/// Usuario autenticado.
///
/// Se llama AppUser para no chocar con `User` de Firebase Auth cuando se
/// integre la capa real.
class AppUser extends Equatable {
  final String id;            // El uid que da Firebase Auth.
  final String email;
  final String displayName;   // El nombre que ve el usuario en la app.
  final EntityStatus status;  // available o deleted (soft delete de la cuenta).
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt; // momento del borrado logico (null si esta vivo).

  AppUser({
    required this.id,
    required this.email,
    required this.displayName,
    this.status = EntityStatus.available,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.deletedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  // Devuelve una copia cambiando solo los campos que le pases.
  // clearDeletedAt permite volver deletedAt a null explicitamente.
  AppUser copyWith({
    String? id,
    String? email,
    String? displayName,
    EntityStatus? status,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? deletedAt,
    bool clearDeletedAt = false,
  }) =>
      AppUser(
        id: id ?? this.id,
        email: email ?? this.email,
        displayName: displayName ?? this.displayName,
        status: status ?? this.status,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        deletedAt: clearDeletedAt ? null : (deletedAt ?? this.deletedAt),
      );

  @override
  List<Object?> get props => [
        id,
        email,
        displayName,
        status,
        createdAt,
        updatedAt,
        deletedAt,
      ];

  // Arma el mapa que se guarda en Firestore. El id ahora tambien va adentro.
  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'email': email,
      'displayName': displayName,
      'status': status.name,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      if (deletedAt != null) 'deletedAt': Timestamp.fromDate(deletedAt!),
    };
  }

  // Reconstruye el AppUser desde el documento de Firestore, con defaults por si falta algo.
  static AppUser fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
    SnapshotOptions? options,
  ) {
    final data = snapshot.data() ?? <String, dynamic>{};
    return AppUser(
      id: (data['id'] as String?) ?? snapshot.id,
      email: (data['email'] as String?) ?? '',
      displayName: (data['displayName'] as String?) ?? '',
      status: EntityStatus.values.byName(
        (data['status'] as String?) ?? EntityStatus.available.name,
      ),
      createdAt: data['createdAt'] != null
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      updatedAt: data['updatedAt'] != null
          ? (data['updatedAt'] as Timestamp).toDate()
          : DateTime.now(),
      deletedAt: data['deletedAt'] != null
          ? (data['deletedAt'] as Timestamp).toDate()
          : null,
    );
  }
}
