import 'package:cloud_firestore/cloud_firestore.dart';

import '../domain/app_user.dart';
import '../domain/users_repository.dart';

class FirestoreUsersRepositoryImpl implements UsersRepository {
  FirestoreUsersRepositoryImpl({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<AppUser> get _col =>
      _firestore.collection('users').withConverter<AppUser>(
            fromFirestore: AppUser.fromFirestore,
            toFirestore: (user, _) => user.toFirestore(),
          );

  @override
  Future<void> createUserDocument(AppUser user) async {
    await _col.doc(user.id).set(user);
  }

  @override
  Future<AppUser?> getUserById(String userId) async {
    final doc = await _col.doc(userId).get();
    return doc.data();
  }

  @override
  Future<void> markUserAsDeleted(String userId) async {
    await _col.doc(userId).update({
      'status': 'deleted',
      'updatedAt': Timestamp.now(),
    });
  }
}
