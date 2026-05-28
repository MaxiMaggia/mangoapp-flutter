import 'app_user.dart';

abstract interface class UsersRepository {
  Future<void> createUserDocument(AppUser user);
  Future<AppUser?> getUserById(String userId);
  Future<void> markUserAsDeleted(String userId);
}
