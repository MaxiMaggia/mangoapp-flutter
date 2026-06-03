import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/auth_repository.dart';
import '../domain/categories_repository.dart';
import '../domain/dolar_repository.dart';
import '../domain/expenses_repository.dart';
import '../domain/users_repository.dart';
import 'dolar_api_repository.dart';
import 'firebase_auth_repository.dart';
import 'firestore_categories_repository.dart';
import 'firestore_expenses_repository.dart';
import 'firestore_users_repository.dart';

/// Providers de los repositorios.
/// Aca decidimos que implementacion concreta usa cada contrato. Si manana
/// cambiamos de backend, solo tocamos estos providers y nada mas.

// Auth: depende de los otros repos para poder limpiar/crear datos del usuario.
final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => FirebaseAuthRepositoryImpl(
    ref.read(categoriesRepositoryProvider),
    ref.read(usersRepositoryProvider),
    ref.read(expensesRepositoryProvider),
  ),
);

// Gastos: implementacion sobre Firestore.
final expensesRepositoryProvider = Provider<ExpensesRepository>(
  (ref) => FirestoreExpensesRepositoryImpl(),
);

// Categorias: implementacion sobre Firestore.
final categoriesRepositoryProvider = Provider<CategoriesRepository>(
  (ref) => FirestoreCategoriesRepositoryImpl(),
);

// Documento de usuario: implementacion sobre Firestore.
final usersRepositoryProvider = Provider<UsersRepository>(
  (ref) => FirestoreUsersRepositoryImpl(),
);

// Cotizaciones del dolar: implementacion contra la API publica.
final dolarRepositoryProvider = Provider<DolarRepository>(
  (ref) => DolarApiRepository(),
);
