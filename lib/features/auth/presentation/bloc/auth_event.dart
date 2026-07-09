part of 'auth_bloc.dart';

/// Base event class for authentication.
abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

/// Submitted email + password login form.
class AuthLoginSubmitted extends AuthEvent {
  const AuthLoginSubmitted({required this.email, required this.password});

  final String email;
  final String password;

  @override
  List<Object?> get props => [email, password];
}

/// Requested Google sign-in.
class AuthGoogleSignInRequested extends AuthEvent {
  const AuthGoogleSignInRequested();
}

/// Requested Facebook sign-in.
class AuthFacebookSignInRequested extends AuthEvent {
  const AuthFacebookSignInRequested();
}

/// Submitted email + password + name sign up form.
class AuthSignUpSubmitted extends AuthEvent {
  const AuthSignUpSubmitted({
    required this.name,
    required this.email,
    required this.password,
  });

  final String name;
  final String email;
  final String password;

  @override
  List<Object?> get props => [name, email, password];
}
