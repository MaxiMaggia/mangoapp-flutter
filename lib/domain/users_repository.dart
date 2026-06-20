import 'app_user.dart';

// Contrato para leer y escribir el documento de usuario en la base.
abstract interface class UsersRepository {
  // Crea el documento del usuario (se llama al registrarse).
  Future<void> createUserDocument(AppUser user);
  // Trae el usuario por id, o null si no existe.
  Future<AppUser?> getUserById(String userId);

  /// Borrado en cascada y atomico de toda la data del usuario (gastos +
  /// categorias + el propio documento de usuario) como soft delete, en uno o
  /// mas WriteBatch. Usado en el flujo de borrado de cuenta: o se marca todo o
  /// no se marca nada.
  Future<void> deleteUserDataInCascade(String userId);
}
