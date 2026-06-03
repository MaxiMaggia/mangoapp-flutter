import 'package:cloud_firestore/cloud_firestore.dart';

import '../domain/app_user.dart';
import '../domain/users_repository.dart';

// Maneja los documentos de usuario en Firestore (la colección 'users').
class FirestoreUsersRepositoryImpl implements UsersRepository {
  // Si no te pasan una instancia de Firestore, usa la default de la app.
  FirestoreUsersRepositoryImpl({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  // Atajo a la colección 'users' ya tipada como AppUser (convierte solo a/desde Firestore).
  CollectionReference<AppUser> get _col =>
      _firestore.collection('users').withConverter<AppUser>(
            fromFirestore: AppUser.fromFirestore,
            toFirestore: (user, _) => user.toFirestore(),
          );

  // Crea (o pisa) el documento del usuario usando su id como id del doc.
  @override
  Future<void> createUserDocument(AppUser user) async {
    await _col.doc(user.id).set(user);
  }

  // Trae un usuario por id; devuelve null si no existe.
  @override
  Future<AppUser?> getUserById(String userId) async {
    final doc = await _col.doc(userId).get();
    return doc.data();
  }

  // Borrado lógico: marca al usuario como 'deleted' en vez de eliminarlo de verdad.
  @override
  Future<void> markUserAsDeleted(String userId) async {
    await _col.doc(userId).update({
      'status': 'deleted',
      'deletedAt': Timestamp.now(),
    });
  }
}
