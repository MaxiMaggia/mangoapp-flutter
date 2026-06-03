import 'app_user.dart';

// Contrato para leer y escribir el documento de usuario en la base.
abstract interface class UsersRepository {
  // Crea el documento del usuario (se llama al registrarse).
  Future<void> createUserDocument(AppUser user);
  // Trae el usuario por id, o null si no existe.
  Future<AppUser?> getUserById(String userId);
  // Marca al usuario como borrado (soft delete, no lo elimina de verdad).
  Future<void> markUserAsDeleted(String userId);
}
