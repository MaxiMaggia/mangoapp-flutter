import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;

import '../domain/app_user.dart';
import '../domain/auth_repository.dart';

class FirebaseAuthRepositoryImpl implements AuthRepository {
  FirebaseAuthRepositoryImpl({
    firebase_auth.FirebaseAuth? auth,
    FirebaseFirestore? firestore,
  })  : _auth = auth ?? firebase_auth.FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance;

  final firebase_auth.FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  @override
  AppUser? get currentUser => _auth.currentUser?.toAppUser();

  @override
  Stream<AppUser?> get authStateChanges =>
      _auth.authStateChanges().map((user) => user?.toAppUser());

  @override
  Future<AppUser> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      final user = credential.user;
      if (user == null) throw Exception('No se pudo iniciar sesion.');
      return user.toAppUser();
    } on firebase_auth.FirebaseAuthException catch (error) {
      throw Exception(_authMessage(error));
    }
  }

  @override
  Future<AppUser> signUp({
    required String email,
    required String password,
    required String displayName,
  }) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      final user = credential.user;
      if (user == null) throw Exception('No se pudo crear la cuenta.');

      await user.updateDisplayName(displayName.trim());
      await user.reload();
      final refreshedUser = _auth.currentUser ?? user;
      final appUser = refreshedUser.toAppUser(displayNameFallback: displayName);

      await _firestore.collection('users').doc(appUser.id).set({
        'email': appUser.email,
        'displayName': appUser.displayName,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      return appUser;
    } on firebase_auth.FirebaseAuthException catch (error) {
      throw Exception(_authMessage(error));
    }
  }

  @override
  Future<void> signOut() => _auth.signOut();

  String _authMessage(firebase_auth.FirebaseAuthException error) {
    switch (error.code) {
      case 'email-already-in-use':
        return 'Ya existe una cuenta con ese email.';
      case 'invalid-email':
        return 'El email no es valido.';
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return 'Email o contrasena incorrectos.';
      case 'weak-password':
        return 'La contrasena es demasiado debil.';
      case 'network-request-failed':
        return 'No se pudo conectar con Firebase.';
      default:
        return error.message ?? 'Error de autenticacion.';
    }
  }
}

extension on firebase_auth.User {
  AppUser toAppUser({String? displayNameFallback}) => AppUser(
        id: uid,
        email: email ?? '',
        displayName: displayName?.trim().isNotEmpty == true
            ? displayName!.trim()
            : (displayNameFallback?.trim().isNotEmpty == true
                ? displayNameFallback!.trim()
                : (email ?? 'Usuario')),
      );
}
