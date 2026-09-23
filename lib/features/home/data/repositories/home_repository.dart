import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../../core/errors/failures.dart';
import '../models/care_recipient_type.dart';
import '../models/caregiver_model.dart';
import '../models/care_recipient_model.dart';

/// Repository for Home / Profile Selection feature with real Firebase Firestore integration.
/// Includes error handling, categorization, and retry logic for resilience.
class HomeRepository {
  HomeRepository({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  /// Maximum number of retry attempts for transient failures.
  static const int _maxRetries = 3;

  /// Delay between retries in milliseconds.
  static const int _retryDelayMs = 1000;

  /// Categorizes a Firebase/network error into a specific [RepositoryErrorType].
  RepositoryErrorType _categorizeError(Object error) {
    final errorString = error.toString().toLowerCase();

    // SSL/Certificate errors
    if (errorString.contains('ssl') ||
        errorString.contains('certificate') ||
        errorString.contains('handshake') ||
        errorString.contains('sec_error')) {
      return RepositoryErrorType.sslCertificate;
    }

    // Network/Connection errors
    if (errorString.contains('network') ||
        errorString.contains('socket') ||
        errorString.contains('connection') ||
        errorString.contains('os error') ||
        errorString.contains('timeout') ||
        errorString.contains('abort') ||
        errorString.contains('no address')) {
      return RepositoryErrorType.network;
    }

    // Authentication errors
    if (errorString.contains('not authenticated') ||
        errorString.contains('sign in') ||
        errorString.contains('auth')) {
      return RepositoryErrorType.notAuthenticated;
    }

    // Permission errors
    if (errorString.contains('permission') || 
        errorString.contains('denied')) {
      return RepositoryErrorType.permissionDenied;
    }

    // Firebase/Firestore errors
    if (error is FirebaseException) {
      return RepositoryErrorType.firestore;
    }

    return RepositoryErrorType.unknown;
  }

  /// Determines whether an error is transient and can be retried.
  bool _isTransientError(RepositoryErrorType errorType) {
    return errorType == RepositoryErrorType.network ||
        errorType == RepositoryErrorType.sslCertificate;
  }

  /// Generates a user-friendly Portuguese error message based on error type.
  String _getErrorMessage(RepositoryErrorType errorType, Object originalError) {
    switch (errorType) {
      case RepositoryErrorType.sslCertificate:
        return 'Erro de segurança (SSL). Verifique a conexão ou tente novamente.';

      case RepositoryErrorType.network:
        return 'Conexão com a internet perdida. Verifique sua rede.';

      case RepositoryErrorType.notAuthenticated:
        return 'Você foi desconectado. Faça login novamente.';

      case RepositoryErrorType.permissionDenied:
        return 'Sem permissão para realizar essa ação.';

      case RepositoryErrorType.firestore:
        return 'Erro ao acessar o banco de dados. Tente novamente.';

      case RepositoryErrorType.invalidData:
        return 'Dados inválidos. Verifique as informações fornecidas.';

      case RepositoryErrorType.unknown:
        return 'Erro desconhecido. Tente novamente mais tarde.';
    }
  }

  /// Executes an async operation with automatic retry logic for transient failures.
  Future<T> _executeWithRetry<T>(
    Future<T> Function() operation, {
    int retries = 0,
  }) async {
    try {
      return await operation();
    } catch (e) {
      final errorType = _categorizeError(e);
      final isTransient = _isTransientError(errorType);

      // If error is transient and we have retries left, wait and retry
      if (isTransient && retries < _maxRetries) {
        await Future.delayed(Duration(milliseconds: _retryDelayMs * (retries + 1)));
        return _executeWithRetry(operation, retries: retries + 1);
      }

      // All retries exhausted or error is not transient - convert to RepositoryFailure
      throw RepositoryFailure(
        _getErrorMessage(errorType, e),
        errorType: errorType,
        originalError: e is Exception ? e : Exception(e.toString()),
        canRetry: isTransient,
      );
    }
  }

  /// Fetches the currently authenticated Caregiver.
  Future<CaregiverModel> fetchCaregiver() async {
    return _executeWithRetry(() async {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('Usuário não autenticado. Faça login novamente.');
      }

      final doc = await _firestore.collection('caregivers').doc(user.uid).get();
      if (doc.exists && doc.data() != null) {
        return CaregiverModel.fromJson(doc.data()!);
      }

      // Fallback: usa dados reais do Firebase Auth (sem documento no Firestore).
      return CaregiverModel(
        id: user.uid,
        name: user.displayName ?? 'Cuidador',
        email: user.email ?? '',
        photoUrl: user.photoURL,
      );
    });
  }

  /// Fetches all Care Recipients managed by this Caregiver from Firestore.
  Future<List<CareRecipientModel>> fetchCareRecipients() async {
    return _executeWithRetry(() async {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('Usuário não autenticado. Faça login novamente.');
      }

      final snapshot = await _firestore
          .collection('care_recipients')
          .where('caregiverId', isEqualTo: user.uid)
          .get();

      if (snapshot.docs.isNotEmpty) {
        return snapshot.docs
            .map((doc) => CareRecipientModel.fromJson(doc.data()))
            .toList();
      }

      return [];
    });
  }

  /// Adds a new Care Recipient to the Caregiver's profile list in Firestore.
  /// Includes automatic retry logic for transient network/SSL errors.
  Future<CareRecipientModel> addCareRecipient({
    required String name,
    required CareRecipientType recipientType,
    DateTime? dateOfBirth,
    String? photoBase64,
  }) async {
    return _executeWithRetry(() async {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('Usuário não autenticado. Faça login novamente.');
      }
      final userId = user.uid;
      final id = 'recipient_${DateTime.now().millisecondsSinceEpoch}';

      final profile = CareRecipientModel(
        id: id,
        name: name,
        type: recipientType == CareRecipientType.pet ? 'pet' : 'person',
        recipientType: recipientType,
        dateOfBirth: dateOfBirth,
        photoBase64: photoBase64,
        unreadNotificationsCount: 0,
      );

      final data = profile.toJson();
      data['caregiverId'] = userId;

      await _firestore.collection('care_recipients').doc(id).set(data);

      return profile;
    });
  }

  /// Deletes a Care Recipient from Firestore.
  /// Includes automatic retry logic for transient network/SSL errors.
  Future<void> deleteProfile(String profileId) async {
    return _executeWithRetry(() async {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('Usuário não autenticado. Faça login novamente.');
      }

      await _firestore.collection('care_recipients').doc(profileId).delete();
    });
  }
}
