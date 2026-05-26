import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/auth_repository.dart';
import '../domain/categories_repository.dart';
import '../domain/expenses_repository.dart';
import 'firebase_auth_repository.dart';
import 'firestore_categories_repository.dart';
import 'firestore_expenses_repository.dart';

/// Providers de los repositorios.
final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => FirebaseAuthRepositoryImpl(
    ref.read(categoriesRepositoryProvider),
  ),
);

final expensesRepositoryProvider = Provider<ExpensesRepository>(
  (ref) => FirestoreExpensesRepositoryImpl(),
);

final categoriesRepositoryProvider = Provider<CategoriesRepository>(
  (ref) => FirestoreCategoriesRepositoryImpl(),
);
