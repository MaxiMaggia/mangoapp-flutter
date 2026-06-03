import 'package:equatable/equatable.dart';

import '../../../domain/app_user.dart';
import '../../utils/base_screen_state.dart';

/// Estado de autenticacion: a quien tenemos logueado y como va la pantalla
/// de login/registro (loading, error, etc).
class AuthState extends Equatable {
  final BaseScreenState screenState; // estado visual: loading / idle / error
  final AppUser? user; // usuario logueado, null si no hay sesion

  const AuthState({
    this.screenState = const BaseScreenState.idle(),
    this.user,
  });

  // Crea una copia cambiando solo lo que le pasemos. clearUser fuerza user a
  // null (para logout), porque mandar user: null no alcanza con el ?? de abajo.
  AuthState copyWith({
    BaseScreenState? screenState,
    AppUser? user,
    bool clearUser = false,
  }) =>
      AuthState(
        screenState: screenState ?? this.screenState,
        user: clearUser ? null : (user ?? this.user),
      );

  @override
  List<Object?> get props => [screenState, user];
}
