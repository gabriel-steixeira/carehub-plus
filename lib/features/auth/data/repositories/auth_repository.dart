import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../../core/errors/app_exception.dart';
import '../../../../core/errors/failures.dart';
import '../../../../services/auth_service.dart';
import '../../../home/data/models/caregiver_model.dart';

/// Repository for authentication operations.
class AuthRepository {
  AuthRepository({
    AuthService? authService,
    FirebaseFirestore? firestore,
  })  : _authService = authService ?? AuthService(),
        _firestore = firestore ?? FirebaseFirestore.instance;

  final AuthService _authService;
  final FirebaseFirestore _firestore;

  /// Stream of authentication state changes.
  Stream<User?> get authStateChanges => _authService.authStateChanges;

  /// Map Firebase exception codes to domain failures.
  AppException _mapFirebaseException(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return const UserNotFoundFailure();
      case 'wrong-password':
      case 'invalid-email':
      case 'user-disabled':
      case 'invalid-credential':
        return const InvalidCredentialsFailure();
      case 'email-already-in-use':
        return const AuthFailure('Este e-mail já está em uso.');
      case 'weak-password':
        return const AuthFailure('A senha fornecida é muito fraca.');
      case 'network-request-failed':
        return const NetworkFailure();
      case 'too-many-requests':
        return const AuthFailure('Muitas tentativas. Tente novamente mais tarde.');
      case 'ERROR_ABORTED_BY_USER':
        return const AuthFailure('Autenticação cancelada pelo usuário.');
      default:
        return AuthFailure(e.message ?? 'Erro inesperado durante a autenticação.');
    }
  }

  /// Signs in with email and password.
  Future<void> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      await _authService.signInWithEmail(email: email, password: password);
    } on FirebaseAuthException catch (e) {
      throw _mapFirebaseException(e);
    } on FirebaseException catch (e) {
      throw AppException(e.message ?? 'Erro no banco de dados', code: e.code);
    } catch (e) {
      throw AppException(e.toString());
    }
  }

  /// Signs up with email, password and name.
  /// Also stores the Caregiver profile in Firestore.
  Future<void> signUpWithEmail({
    required String name,
    required String email,
    required String password,
    String? photoBase64,
  }) async {
    try {
      final credential = await _authService.signUpWithEmail(
        name: name,
        email: email,
        password: password,
      );

      final user = credential.user;
      if (user != null) {
        final caregiver = CaregiverModel(
          id: user.uid,
          name: name,
          email: email,
          photoUrl: user.photoURL,
          photoBase64: photoBase64,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        await _firestore
            .collection('caregivers')
            .doc(user.uid)
            .set(caregiver.toJson());
      }
    } on FirebaseAuthException catch (e) {
      throw _mapFirebaseException(e);
    } on FirebaseException catch (e) {
      throw AppException(e.message ?? 'Erro no banco de dados', code: e.code);
    } catch (e) {
      throw AppException(e.toString());
    }
  }

  /// Helper method to create a caregiver document in Firestore if it doesn't exist.
  Future<void> _ensureCaregiverDocument(User user) async {
    final docRef = _firestore.collection('caregivers').doc(user.uid);
    final doc = await docRef.get();
    
    if (!doc.exists) {
      final caregiver = CaregiverModel(
        id: user.uid,
        name: user.displayName ?? 'Cuidador',
        email: user.email ?? '',
        photoUrl: user.photoURL,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      await docRef.set(caregiver.toJson());
    }
  }

  /// Signs in with Google OAuth.
  Future<void> signInWithGoogle() async {
    try {
      final credential = await _authService.signInWithGoogle();
      final user = credential.user;
      if (user != null) {
        await _ensureCaregiverDocument(user);
      }
    } on FirebaseAuthException catch (e) {
      throw _mapFirebaseException(e);
    } on FirebaseException catch (e) {
      throw AppException(e.message ?? 'Erro no banco de dados', code: e.code);
    } catch (e) {
      throw AppException(e.toString());
    }
  }

  /// Signs in with Facebook OAuth.
  Future<void> signInWithFacebook() async {
    try {
      final credential = await _authService.signInWithFacebook();
      final user = credential.user;
      if (user != null) {
        await _ensureCaregiverDocument(user);
      }
    } on FirebaseAuthException catch (e) {
      throw _mapFirebaseException(e);
    } on FirebaseException catch (e) {
      throw AppException(e.message ?? 'Erro no banco de dados', code: e.code);
    } catch (e) {
      throw AppException(e.toString());
    }
  }

  /// Signs out the current user.
  Future<void> signOut() async {
    try {
      await _authService.signOut();
    } on FirebaseAuthException catch (e) {
      throw _mapFirebaseException(e);
    } catch (e) {
      throw AppException(e.toString());
    }
  }

  /// Sends a password reset email.
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _authService.sendPasswordResetEmail(email);
    } on FirebaseAuthException catch (e) {
      throw _mapFirebaseException(e);
    } catch (e) {
      throw AppException(e.toString());
    }
  }
}

