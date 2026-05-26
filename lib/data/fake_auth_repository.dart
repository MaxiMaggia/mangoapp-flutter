import 'dart:async';

import '../domain/app_user.dart';
import '../domain/auth_repository.dart';

/// Implementacion fake en memoria. Se reemplaza por FirebaseAuthRepositoryImpl
/// cuando se integre Firebase Auth.
class FakeAuthRepository implements AuthRepository {
  AppUser? _current;
  final _authStateController = StreamController<AppUser?>.broadcast();

  // Algunos usuarios de prueba para poder loguearse.
  // En la version Firebase esto desaparece.
  final Map<String, _StoredUser> _users = {
    'demo@mango.com': _StoredUser(
      user: const AppUser(
        id: 'u_demo',
        email: 'demo@mango.com',
        displayName: 'Maxi Demo',
      ),
      password: '123456',
    ),
  };

  @override
  AppUser? get currentUser => _current;

  @override
  Stream<AppUser?> get authStateChanges => _authStateController.stream;

  @override
  Future<AppUser> signIn({
    required String email,
    required String password,
  }) async {
    await Future.delayed(const Duration(milliseconds: 600));
    final stored = _users[email.toLowerCase()];
    if (stored == null) {
      throw Exception('No existe una cuenta con ese email.');
    }
    if (stored.password != password) {
      throw Exception('La contrasena es incorrecta.');
    }
    _current = stored.user;
    _authStateController.add(_current);
    return stored.user;
  }

  @override
  Future<AppUser> signUp({
    required String email,
    required String password,
    required String displayName,
  }) async {
    await Future.delayed(const Duration(milliseconds: 600));
    final normalizedEmail = email.toLowerCase();
    if (_users.containsKey(normalizedEmail)) {
      throw Exception('Ya existe una cuenta con ese email.');
    }
    final newUser = AppUser(
      id: 'u_${DateTime.now().millisecondsSinceEpoch}',
      email: normalizedEmail,
      displayName: displayName,
    );
    _users[normalizedEmail] = _StoredUser(user: newUser, password: password);
    _current = newUser;
    _authStateController.add(_current);
    return newUser;
  }

  @override
  Future<void> signOut() async {
    await Future.delayed(const Duration(milliseconds: 200));
    _current = null;
    _authStateController.add(null);
  }
}

class _StoredUser {
  final AppUser user;
  final String password;
  _StoredUser({required this.user, required this.password});
}
