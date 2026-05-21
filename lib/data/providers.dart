import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mango/data/firestore_expenses_repository.dart';

import '../domain/auth_repository.dart';
import '../domain/categories_repository.dart';
import '../domain/expenses_repository.dart';
import 'firebase_auth_repository.dart';
import 'firestore_categories_repository.dart';

/// Providers de los repositorios.
///
/// Para conectar Firebase, se cambia el lado derecho por la implementacion
/// real (FirebaseAuthRepositoryImpl, FirestoreExpensesRepositoryImpl, etc.)
/// y nada mas tiene que cambiar en el resto del codigo.
final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => FirebaseAuthRepositoryImpl(), // FakeAuthRepository(),
);

final expensesRepositoryProvider = Provider<ExpensesRepository>(
  (ref) => FirestoreExpensesRepositoryImpl(),
);

final categoriesRepositoryProvider = Provider<CategoriesRepository>(
  (ref) => FirestoreCategoriesRepositoryImpl(),
);
