import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/providers.dart';
import '../../../domain/app_user.dart';
import '../../../domain/auth_repository.dart';
import '../../utils/base_screen_state.dart';
import '../states/auth_state.dart';

class AuthNotifier extends Notifier<AuthState> {
  late final AuthRepository _authRepo = ref.read(authRepositoryProvider);
  StreamSubscription<AppUser?>? _authSub;

  @override
  AuthState build() {
    _authSub = _authRepo.authStateChanges.listen((user) {
      state = state.copyWith(
        screenState: const BaseScreenState.idle(),
        user: user,
        clearUser: user == null,
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

  /// Limpia el ultimo error sin perder el usuario logueado.
  void clearError() {
    if (state.screenState.isError) {
      state = state.copyWith(screenState: const BaseScreenState.idle());
    }
  }
}
