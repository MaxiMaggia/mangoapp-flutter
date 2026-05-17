import 'package:equatable/equatable.dart';

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
  final DateTime? updatedAt;

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
    this.updatedAt,
  }) : createdAt = createdAt ?? DateTime.now();

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
      ];
<<<<<<< HEAD
=======
  
  /// Serializa la instancia a un Map para Firestore
  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'name': name,
      'categoryId': categoryId,
      'amountArs': amountArs,
      if (originalAmount != null) 'originalAmount': originalAmount,
      'currency': currency.name,
      if (dolarType != null) 'dolarType': dolarType,
      'date': date.toIso8601String(),
      if (attachmentUrl != null) 'attachmentUrl': attachmentUrl,
      'createdAt': createdAt.toIso8601String(),
      if (updatedAt != null) 'updatedAt': updatedAt!.toIso8601String(),
    };
  }

  /// Crea una instancia desde un Map de Firestore
  factory Expense.fromJson(Map<String, dynamic> json) {
    return Expense(
      id: json['id'] as String?,
      userId: json['userId'] as String,
      name: json['name'] as String,
      categoryId: json['categoryId'] as String,
      amountArs: (json['amountArs'] as num).toDouble(),
      originalAmount: json['originalAmount'] != null ? (json['originalAmount'] as num).toDouble() : null,
      currency: (json['currency'] as String) == 'usd' ? Currency.usd : Currency.ars,
      dolarType: json['dolarType'] as String?,
      date: DateTime.parse(json['date'] as String),
      attachmentUrl: json['attachmentUrl'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: json['updatedAt'] != null ? DateTime.parse(json['updatedAt'] as String) : null,
    );
  }
>>>>>>> 53e1994 (Migración a Firestore y mejoras de modelo)
}

extension ExpenseValidator on Expense {
  bool get isValid =>
      isNameValid && isCategoryValid && isAmountValid && isDateValid;
  bool get isNameValid => name.trim().isNotEmpty;
  bool get isCategoryValid => categoryId.isNotEmpty;
  bool get isAmountValid => amountArs > 0;
  bool get isDateValid => !date.isAfter(DateTime.now());
}
