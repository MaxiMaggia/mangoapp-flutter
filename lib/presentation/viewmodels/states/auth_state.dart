import 'package:equatable/equatable.dart';

import '../../../domain/app_user.dart';
import '../../utils/base_screen_state.dart';

class AuthState extends Equatable {
  final BaseScreenState screenState;
  final AppUser? user;

  const AuthState({
    this.screenState = const BaseScreenState.idle(),
    this.user,
  });

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
