import 'app_exception.dart';

/// Network-related failure.
class NetworkFailure extends AppException {
  const NetworkFailure([super.message = 'Sem conexão com a internet'])
    : super(code: 'NETWORK_ERROR');
}

/// Authentication failure.
class AuthFailure extends AppException {
  const AuthFailure([super.message = 'Falha na autenticação'])
    : super(code: 'AUTH_ERROR');
}

/// Invalid credentials failure.
class InvalidCredentialsFailure extends AuthFailure {
  const InvalidCredentialsFailure() : super('E-mail ou senha inválidos');
}

/// User not found failure.
class UserNotFoundFailure extends AuthFailure {
  const UserNotFoundFailure() : super('Usuário não encontrado');
}

/// Server failure.
class ServerFailure extends AppException {
  const ServerFailure([super.message = 'Erro no servidor'])
    : super(code: 'SERVER_ERROR');
}

/// Repository failure with detailed error categorization.
/// Used for handling database, network, and SSL errors.
class RepositoryFailure extends AppException {
  const RepositoryFailure(
    super.message, {
    super.code = 'REPOSITORY_ERROR',
    required this.errorType,
    this.originalError,
    this.canRetry = false,
  });

  /// Categorizes the type of repository error.
  final RepositoryErrorType errorType;

  /// Original exception that caused the failure.
  final Exception? originalError;

  /// Whether the operation can be retried.
  final bool canRetry;
}

/// Categorization of repository errors.
enum RepositoryErrorType {
  /// SSL/Certificate verification failed.
  sslCertificate,

  /// Network connection error.
  network,

  /// Firebase/Firestore operation failed.
  firestore,

  /// User is not authenticated.
  notAuthenticated,

  /// Permission denied by Firestore rules.
  permissionDenied,

  /// Invalid data or validation error.
  invalidData,

  /// Unknown error.
  unknown,
}
