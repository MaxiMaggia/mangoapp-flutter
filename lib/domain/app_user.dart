import 'package:equatable/equatable.dart';

/// Usuario autenticado.
///
/// Se llama AppUser para no chocar con `User` de Firebase Auth cuando se
/// integre la capa real.
class AppUser extends Equatable {
  final String id;
  final String email;
  final String displayName;

  const AppUser({
    required this.id,
    required this.email,
    required this.displayName,
  });

  AppUser copyWith({String? id, String? email, String? displayName}) => AppUser(
        id: id ?? this.id,
        email: email ?? this.email,
        displayName: displayName ?? this.displayName,
      );

  @override
  List<Object?> get props => [id, email, displayName];
}
