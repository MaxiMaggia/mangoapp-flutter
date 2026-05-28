import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/providers.dart';
import '../../../domain/app_user.dart';
import '../../../domain/auth_repository.dart';
import '../../../domain/entity_status.dart';
import '../../utils/base_screen_state.dart';
import '../states/auth_state.dart';

class AuthNotifier extends Notifier<AuthState> {
  late final AuthRepository _authRepo = ref.read(authRepositoryProvider);
  StreamSubscription<AppUser?>? _authSub;

  @override
  AuthState build() {
    _authSub = _authRepo.authStateChanges.listen((user) async {
      if (user == null) {
        state = state.copyWith(
          screenState: const BaseScreenState.idle(),
          clearUser: true,
        );
        return;
      }
      // Validar el status en Firestore ANTES de setear el user, para que una
      // cuenta con status=deleted nunca llegue a verse logueada (ni un frame).
      try {
        final usersRepo = ref.read(usersRepositoryProvider);
        final firestoreUser = await usersRepo.getUserById(user.id);
        if (firestoreUser != null &&
            firestoreUser.status == EntityStatus.deleted) {
          await _authRepo.signOut();
          state = state.copyWith(
            screenState:
                const BaseScreenState.error('Esta cuenta fue eliminada.'),
            clearUser: true,
          );
          return;
        }
      } catch (_) {
        // Si la validación falla por red u otro motivo transitorio, no
        // bloqueamos el login.
      }
      state = state.copyWith(
        screenState: const BaseScreenState.idle(),
        user: user,
      );
    });
    ref.onDispose(() => _authSub?.cancel());
    return AuthState(user: _authRepo.currentUser);
  }

  Future<void> signIn(String email, String password) async {
    state = state.copyWith(screenState: const BaseScreenState.loading());
    try {
      final user = await _authRepo.signIn(email: email, password: password);
      state = state.copyWith(
        screenState: const BaseScreenState.idle(),
        user: user,
      );
    } catch (error) {
      state = state.copyWith(
        screenState: BaseScreenState.error(error.toString()),
      );
    }
  }

  Future<void> signUp({
    required String email,
    required String password,
    required String displayName,
  }) async {
    state = state.copyWith(screenState: const BaseScreenState.loading());
    try {
      final user = await _authRepo.signUp(
        email: email,
        password: password,
        displayName: displayName,
      );
      state = state.copyWith(
        screenState: const BaseScreenState.idle(),
        user: user,
      );
    } catch (error) {
      state = state.copyWith(
        screenState: BaseScreenState.error(error.toString()),
      );
    }
  }

  Future<void> signOut() async {
    await _authRepo.signOut();
    state = state.copyWith(
      screenState: const BaseScreenState.idle(),
      clearUser: true,
    );
  }

  /// Borra la cuenta. NO toca el state a propósito: el listener de
  /// authStateChanges detecta el signOut interno del repo y limpia el user
  /// (que dispara el redirect al login). Tocar el state acá además del
  /// listener generaba una condición de carrera con el pop del diálogo.
  /// Si falla, la excepción sube al diálogo, que la maneja con estado local.
  Future<void> deleteAccount(String password) async {
    await _authRepo.deleteAccount(password: password);
  }

  /// Limpia el ultimo error sin perder el usuario logueado.
  void clearError() {
    if (state.screenState.isError) {
      state = state.copyWith(screenState: const BaseScreenState.idle());
    }
  }
}
