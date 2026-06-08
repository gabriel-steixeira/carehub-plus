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
