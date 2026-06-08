import 'package:flutter/foundation.dart';

import '../../../../core/errors/app_exception.dart';
import '../../../../core/errors/failures.dart';

/// Repository for authentication operations.
///
/// Currently a stub — will be replaced with Firebase Auth integration.
class AuthRepository {
  /// Signs in with email and password.
  Future<void> signInWithEmail({
    required String email,
    required String password,
  }) async {
    // TODO: Integrate with Firebase Auth
    // Simulating network delay
    await Future.delayed(const Duration(seconds: 2));

    // Stub: accept any valid-looking credentials
    if (email.isEmpty || password.isEmpty) {
      throw const InvalidCredentialsFailure();
    }

    debugPrint('AuthRepository: signInWithEmail($email)');
  }

  /// Signs in with Google OAuth.
  Future<void> signInWithGoogle() async {
    // TODO: Integrate with Google Sign-In
    await Future.delayed(const Duration(seconds: 2));
    debugPrint('AuthRepository: signInWithGoogle');
  }

  /// Signs in with Facebook OAuth.
  Future<void> signInWithFacebook() async {
    // TODO: Integrate with Facebook Sign-In
    await Future.delayed(const Duration(seconds: 2));
    debugPrint('AuthRepository: signInWithFacebook');
  }

  /// Signs out the current user.
  Future<void> signOut() async {
    // TODO: Integrate with Firebase Auth
    await Future.delayed(const Duration(milliseconds: 500));
    debugPrint('AuthRepository: signOut');
  }

  /// Sends a password reset email.
  Future<void> sendPasswordResetEmail(String email) async {
    // TODO: Integrate with Firebase Auth
    await Future.delayed(const Duration(seconds: 1));

    if (email.isEmpty) {
      throw const AppException('E-mail não pode estar vazio');
    }

    debugPrint('AuthRepository: sendPasswordResetEmail($email)');
  }
}
