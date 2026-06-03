import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';

/// Estado base de cualquier pantalla. Reproduce el patron del profe en
/// riverpod_mvvm_crud: loading / idle / error como sealed class.
@immutable
sealed class BaseScreenState extends Equatable {
  const BaseScreenState._();

  const factory BaseScreenState.loading() = LoadingState;
  const factory BaseScreenState.idle() = IdleState;
  const factory BaseScreenState.error(String error) = ErrorState;

  @override
  List<Object?> get props => [];
}

// Cargando: mostramos spinner.
class LoadingState extends BaseScreenState {
  const LoadingState() : super._();
}

// Quieto/listo: el caso normal, sin spinner ni error.
class IdleState extends BaseScreenState {
  const IdleState() : super._();
}

// Algo fallo: trae el mensaje de error para mostrar.
class ErrorState extends BaseScreenState {
  final String error;
  const ErrorState(this.error) : super._();

  @override
  List<Object?> get props => [error];
}

// Helpers para no andar haciendo "is LoadingState" por toda la UI.
extension BaseScreenStateX on BaseScreenState {
  bool get isLoading => this is LoadingState;
  bool get isIdle => this is IdleState;
  bool get isError => this is ErrorState;
  String? get errorMessage =>
      this is ErrorState ? (this as ErrorState).error : null;

  // Pattern matching exhaustivo: un callback por cada estado posible.
  R when<R>({
    required R Function() loading,
    required R Function() idle,
    required R Function(String error) error,
  }) =>
      switch (this) {
        LoadingState() => loading(),
        IdleState() => idle(),
        ErrorState() => error((this as ErrorState).error),
      };
}
