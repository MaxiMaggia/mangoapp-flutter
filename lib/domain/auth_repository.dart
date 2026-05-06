import 'app_user.dart';

abstract interface class AuthRepository {
  /// Usuario actual o null si no hay sesion.
  AppUser? get currentUser;

  Future<AppUser> signIn({required String email, required String password});

  Future<AppUser> signUp({
    required String email,
    required String password,
    required String displayName,
  });

  Future<void> signOut();
}
