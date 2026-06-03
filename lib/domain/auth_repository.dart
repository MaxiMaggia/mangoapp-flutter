import 'app_user.dart';

// Contrato de autenticacion: login, registro, logout y borrado de cuenta.
abstract interface class AuthRepository {
  /// Usuario actual o null si no hay sesion.
  AppUser? get currentUser;

  /// Cambios de sesion emitidos por el proveedor de auth.
  Stream<AppUser?> get authStateChanges;

  // Inicia sesion con email y contraseña y devuelve el usuario logueado.
  Future<AppUser> signIn({required String email, required String password});

  // Crea una cuenta nueva (email, contraseña y nombre) y devuelve el usuario.
  Future<AppUser> signUp({
    required String email,
    required String password,
    required String displayName,
  });

  // Cierra la sesion actual.
  Future<void> signOut();

  // Borra la cuenta del usuario (le pedimos la contraseña para reautenticar).
  Future<void> deleteAccount({required String password});
}
