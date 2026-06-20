import 'package:cloud_firestore/cloud_firestore.dart';

import '../domain/app_user.dart';
import '../domain/entity_status.dart';
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

  // Borrado en cascada y atomico de toda la data del usuario: gastos, categorias
  // y el propio documento de usuario, todo marcado como 'deleted' en uno o mas
  // WriteBatch. Como las tres colecciones viven en el mismo Firestore, este repo
  // puede armar un batch que las toque a todas, de forma que el borrado sea
  // todo-o-nada (si se corta la conexion no queda nada a medias).
  @override
  Future<void> deleteUserDataInCascade(String userId) async {
    // PASO DE LECTURA (fuera del batch): juntamos las referencias de todo lo que
    // hay que marcar. Los batches son solo de escritura.
    final expensesSnapshot = await _firestore
        .collection('expenses')
        .where('userId', isEqualTo: userId)
        .where('status', isEqualTo: EntityStatus.available.name)
        .get();
    final categoriesSnapshot = await _firestore
        .collection('categories')
        .where('userId', isEqualTo: userId)
        .where('status', isEqualTo: EntityStatus.available.name)
        .get();

    // Una sola lista con todas las referencias: gastos + categorias + el usuario.
    final refs = <DocumentReference<Map<String, dynamic>>>[
      ...expensesSnapshot.docs.map((doc) => doc.reference),
      ...categoriesSnapshot.docs.map((doc) => doc.reference),
      _firestore.collection('users').doc(userId),
    ];

    // PASO DE ESCRITURA (atomico): marcamos todo como deleted. NO tocamos
    // updatedAt, solo status y deletedAt (mantenemos esa separacion).
    final update = <String, dynamic>{
      'status': EntityStatus.deleted.name,
      'deletedAt': Timestamp.now(),
    };

    // Un WriteBatch admite hasta 500 ops; usamos 450 de margen para no rozar el
    // limite. Cada 450 ops hacemos commit y arrancamos un batch nuevo.
    const maxOpsPerBatch = 450;
    var batch = _firestore.batch();
    var opsInBatch = 0;
    for (final ref in refs) {
      batch.update(ref, update);
      opsInBatch++;
      if (opsInBatch >= maxOpsPerBatch) {
        await batch.commit();
        batch = _firestore.batch();
        opsInBatch = 0;
      }
    }
    // Commit del ultimo batch (siempre hay al menos el doc del usuario).
    if (opsInBatch > 0) {
      await batch.commit();
    }
  }
}
