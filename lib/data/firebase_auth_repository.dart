import 'package:firebase_auth/firebase_auth.dart' as fb_auth;

import '../domain/app_user.dart';
import '../domain/auth_repository.dart';
import '../domain/categories_repository.dart';

class FirebaseAuthRepositoryImpl implements AuthRepository {
  final fb_auth.FirebaseAuth _auth = fb_auth.FirebaseAuth.instance;
  final CategoriesRepository _categoriesRepo;

  FirebaseAuthRepositoryImpl(this._categoriesRepo);

  AppUser _mapUser(fb_auth.User user) => AppUser(
        id: user.uid,
        email: user.email ?? '',
        displayName: user.displayName ?? '',
      );

  @override
  AppUser? get currentUser {
    final user = _auth.currentUser;
    if (user == null) return null;
    return _mapUser(user);
  }

  @override
  Future<AppUser> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return _mapUser(credential.user!);
    } on fb_auth.FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'user-not-found':
        case 'invalid-email':
          throw Exception('No existe una cuenta con ese email.');
        case 'wrong-password':
        case 'invalid-credential':
          throw Exception('La contraseña es incorrecta.');
        case 'too-many-requests':
          throw Exception('Demasiados intentos. Probá más tarde.');
        default:
          throw Exception('Error al iniciar sesión: ${e.message}');
      }
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
        email: email,
        password: password,
      );
      await credential.user!.updateDisplayName(displayName);
      await credential.user!.reload();
      try {
        await _categoriesRepo.seedDefaultCategories(_auth.currentUser!.uid);
      } catch (e) {
        // ignore: avoid_print
        print('Warning: no se pudo crear el seed de categorías: $e');
      }
      return _mapUser(_auth.currentUser!);
    } on fb_auth.FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'email-already-in-use':
          throw Exception('Ya existe una cuenta con ese email.');
        case 'weak-password':
          throw Exception('La contraseña es muy débil (mínimo 6 caracteres).');
        case 'invalid-email':
          throw Exception('El email no es válido.');
        default:
          throw Exception('Error al crear la cuenta: ${e.message}');
      }
    }
  }

  @override
  Future<void> signOut() async {
    await _auth.signOut();
  }
}
