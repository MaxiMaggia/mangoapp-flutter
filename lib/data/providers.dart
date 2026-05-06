import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/auth_repository.dart';
import '../domain/categories_repository.dart';
import '../domain/expenses_repository.dart';
import 'fake_auth_repository.dart';
import 'fake_categories_repository.dart';
import 'fake_expenses_repository.dart';

/// Providers de los repositorios.
///
/// Para conectar Firebase, se cambia el lado derecho por la implementacion
/// real (FirebaseAuthRepositoryImpl, FirestoreExpensesRepositoryImpl, etc.)
/// y nada mas tiene que cambiar en el resto del codigo.
final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => FakeAuthRepository(),
);

final expensesRepositoryProvider = Provider<ExpensesRepository>(
  (ref) => FakeExpensesRepository(),
);

final categoriesRepositoryProvider = Provider<CategoriesRepository>(
  (ref) => FakeCategoriesRepository(),
);
