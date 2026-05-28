import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;

import '../domain/app_user.dart';
import '../domain/auth_repository.dart';
import '../domain/categories_repository.dart';
import '../domain/entity_status.dart';
import '../domain/expenses_repository.dart';
import '../domain/users_repository.dart';

class FirebaseAuthRepositoryImpl implements AuthRepository {
  FirebaseAuthRepositoryImpl(
    this._categoriesRepo,
    this._usersRepo,
    this._expensesRepo, {
    firebase_auth.FirebaseAuth? auth,
  }) : _auth = auth ?? firebase_auth.FirebaseAuth.instance;

  final CategoriesRepository _categoriesRepo;
  final UsersRepository _usersRepo;
  final ExpensesRepository _expensesRepo;
  final firebase_auth.FirebaseAuth _auth;

  @override
  AppUser? get currentUser => _auth.currentUser?.toAppUser();

  @override
  Stream<AppUser?> get authStateChanges =>
      _auth.authStateChanges().map((user) => user?.toAppUser());

  @override
  Future<AppUser> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      final user = credential.user;
      if (user == null) throw Exception('No se pudo iniciar sesion.');

      final firestoreUser = await _usersRepo.getUserById(user.uid);
      if (firestoreUser != null &&
          firestoreUser.status == EntityStatus.deleted) {
        await _auth.signOut();
        throw Exception(
          'Esta cuenta fue eliminada. Si querés recuperarla, contactanos.',
        );
      }
      if (firestoreUser == null) {
        try {
          await _usersRepo.createUserDocument(user.toAppUser());
        } catch (e) {
          // ignore: avoid_print
          print('Warning: lazy migration de usuario falló: $e');
        }
      }

      return user.toAppUser();
    } on firebase_auth.FirebaseAuthException catch (error) {
      throw Exception(_authMessage(error));
    }
  }

  @override
  Future<AppUser> signUp({
    required String email,
    required String password,
    required String displayName,
  }) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      final user = credential.user;
      if (user == null) throw Exception('No se pudo crear la cuenta.');

      await user.updateDisplayName(displayName.trim());
      await user.reload();
      final refreshedUser = _auth.currentUser ?? user;
      final appUser = refreshedUser.toAppUser(displayNameFallback: displayName);

      try {
        await _usersRepo.createUserDocument(appUser);
      } catch (e) {
        // ignore: avoid_print
        print('Warning: no se pudo crear el documento de usuario: $e');
      }

      await _categoriesRepo.seedDefaultCategories(appUser.id);

      return appUser;
    } on firebase_auth.FirebaseAuthException catch (error) {
      throw Exception(_authMessage(error));
    }
  }

  @override
  Future<void> signOut() => _auth.signOut();

  @override
  Future<void> deleteAccount({required String password}) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('No hay sesión activa.');
    }
    final email = user.email;
    if (email == null) {
      throw Exception('El usuario no tiene email asociado.');
    }
    final uid = user.uid;
    try {
      final credential = firebase_auth.EmailAuthProvider.credential(
        email: email,
        password: password,
      );
      await user.reauthenticateWithCredential(credential);

      await _expensesRepo.markAllUserExpensesAsDeleted(uid);
      await _categoriesRepo.markAllUserCategoriesAsDeleted(uid);
      await _usersRepo.markUserAsDeleted(uid);

      await _auth.signOut();
    } on firebase_auth.FirebaseAuthException catch (e) {
      if (e.code == 'wrong-password' || e.code == 'invalid-credential') {
        throw Exception('La contraseña es incorrecta.');
      }
      if (e.code == 'requires-recent-login') {
        throw Exception(
          'Por seguridad, volvé a iniciar sesión antes de eliminar la cuenta.',
        );
      }
      throw Exception('Error al eliminar la cuenta: ${e.message}');
    }
  }

  String _authMessage(firebase_auth.FirebaseAuthException error) {
    switch (error.code) {
      case 'email-already-in-use':
        return 'Ya existe una cuenta con ese email.';
      case 'invalid-email':
        return 'El email no es valido.';
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return 'Email o contrasena incorrectos.';
      case 'weak-password':
        return 'La contrasena es demasiado debil.';
      case 'network-request-failed':
        return 'No se pudo conectar con Firebase.';
      default:
        return error.message ?? 'Error de autenticacion.';
    }
  }
}

extension on firebase_auth.User {
  AppUser toAppUser({String? displayNameFallback}) => AppUser(
        id: uid,
        email: email ?? '',
        displayName: displayName?.trim().isNotEmpty == true
            ? displayName!.trim()
            : (displayNameFallback?.trim().isNotEmpty == true
                ? displayNameFallback!.trim()
                : (email ?? 'Usuario')),
      );
}
