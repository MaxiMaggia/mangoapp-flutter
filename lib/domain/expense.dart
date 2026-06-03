import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

import 'entity_status.dart';

/// Moneda en la que se carga un gasto.
enum Currency { ars, usd }

/// Tipo de cotización para conversiones USD -> ARS.
/// Coincide con las casas de dolarapi.com (oficial, blue, mep, ccl, etc.).
class DolarType {
  final String code; // 'blue', 'oficial', 'mep'...
  final String label; // 'Blue', 'Oficial', 'MEP'...

  const DolarType({required this.code, required this.label});

  static const blue = DolarType(code: 'blue', label: 'Blue');
  static const oficial = DolarType(code: 'oficial', label: 'Oficial');
  static const mep = DolarType(code: 'mep', label: 'MEP');
  static const tarjeta = DolarType(code: 'tarjeta', label: 'Tarjeta');

  static const all = [blue, oficial, mep, tarjeta];

  /// Nombre de la casa según dolarapi.com (en dolarapi el MEP se llama
  /// "bolsa"; el resto coincide con nuestro `code`).
  String get apiCasa => code == 'mep' ? 'bolsa' : code;
}

/// Entidad principal: un gasto registrado por el usuario.
///
/// `amountArs` siempre se guarda en pesos (es lo que se usa para todos los
/// reportes). Si el gasto se cargo en USD, `originalAmount` y `currency`
/// guardan el monto original y `dolarType` la cotizacion usada.
class Expense extends Equatable {
  final String? id;
  final String userId;
  final String name;
  final String categoryId;
  final double amountArs;
  final double? originalAmount;
  final Currency currency;
  final String? dolarType; // codigo de DolarType
  final DateTime date;
  final String? attachmentUrl;
  final DateTime createdAt;
  final DateTime updatedAt; // siempre presente: igual a createdAt al crear.
  final DateTime? deletedAt; // momento del borrado logico (null si esta vivo).
  final EntityStatus status;

  Expense({
    this.id,
    required this.userId,
    required this.name,
    required this.categoryId,
    required this.amountArs,
    this.originalAmount,
    this.currency = Currency.ars,
    this.dolarType,
    required this.date,
    this.attachmentUrl,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.deletedAt,
    this.status = EntityStatus.available,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? (createdAt ?? DateTime.now());

  // Devuelve una copia del gasto cambiando solo los campos que le pases.
  Expense copyWith({
    String? id,
    String? userId,
    String? name,
    String? categoryId,
    double? amountArs,
    double? originalAmount,
    Currency? currency,
    String? dolarType,
    DateTime? date,
    String? attachmentUrl,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? deletedAt,
    bool clearDeletedAt = false,
    EntityStatus? status,
  }) =>
      Expense(
        id: id ?? this.id,
        userId: userId ?? this.userId,
        name: name ?? this.name,
        categoryId: categoryId ?? this.categoryId,
        amountArs: amountArs ?? this.amountArs,
        originalAmount: originalAmount ?? this.originalAmount,
        currency: currency ?? this.currency,
        dolarType: dolarType ?? this.dolarType,
        date: date ?? this.date,
        attachmentUrl: attachmentUrl ?? this.attachmentUrl,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        deletedAt: clearDeletedAt ? null : (deletedAt ?? this.deletedAt),
        status: status ?? this.status,
      );

  @override
  List<Object?> get props => [
        id,
        userId,
        name,
        categoryId,
        amountArs,
        originalAmount,
        currency,
        dolarType,
        date,
        attachmentUrl,
        createdAt,
        updatedAt,
        deletedAt,
        status,
      ];

  // Convierte el gasto al mapa que se guarda en Firestore.
  Map<String, dynamic> toFirestore() {
    return {
      if (id != null) 'id': id,
      'userId': userId,
      'name': name,
      'categoryId': categoryId,
      'amountArs': amountArs,
      if (originalAmount != null) 'originalAmount': originalAmount,
      'currency': currency.name,
      if (dolarType != null) 'dolarType': dolarType,
      'date': Timestamp.fromDate(date),
      if (attachmentUrl != null) 'attachmentUrl': attachmentUrl,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      if (deletedAt != null) 'deletedAt': Timestamp.fromDate(deletedAt!),
      'status': status.name,
    };
  }

  // Reconstruye un gasto a partir del documento que viene de Firestore.
  static Expense fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
    SnapshotOptions? options,
  ) {
    final data = snapshot.data()!;
    return Expense(
      id: (data['id'] as String?) ?? snapshot.id,
      userId: data['userId'] as String,
      name: data['name'] as String,
      categoryId: data['categoryId'] as String,
      amountArs: (data['amountArs'] as num).toDouble(),
      originalAmount: data['originalAmount'] != null
          ? (data['originalAmount'] as num).toDouble()
          : null,
      currency: Currency.values.byName(data['currency'] as String),
      dolarType: data['dolarType'] as String?,
      date: (data['date'] as Timestamp).toDate(),
      attachmentUrl: data['attachmentUrl'] as String?,
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

// Reglas para validar un gasto antes de guardarlo (nombre, categoria, monto y fecha).
extension ExpenseValidator on Expense {
  // El gasto es valido solo si pasa todas las validaciones de abajo.
  bool get isValid =>
      isNameValid && isCategoryValid && isAmountValid && isDateValid;
  bool get isNameValid => name.trim().isNotEmpty;
  bool get isCategoryValid => categoryId.isNotEmpty;
  bool get isAmountValid => amountArs > 0;
  bool get isDateValid => !date.isAfter(DateTime.now());
}
