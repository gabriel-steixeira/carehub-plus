import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:carehub_plus/core/errors/app_exception.dart';
import 'package:carehub_plus/features/auth/data/repositories/auth_repository.dart';
import 'package:carehub_plus/features/auth/presentation/bloc/auth_bloc.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late AuthRepository authRepository;
  late AuthBloc authBloc;

  setUp(() {
    authRepository = MockAuthRepository();
    authBloc = AuthBloc(repository: authRepository);
  });

  tearDown(() {
    authBloc.close();
  });

  group('AuthBloc', () {
    test('initial state is correct', () {
      expect(authBloc.state, const AuthState());
    });

    group('AuthLoginSubmitted', () {
      blocTest<AuthBloc, AuthState>(
        'emits [loading, success] when signInWithEmail succeeds',
        build: () {
          when(() => authRepository.signInWithEmail(
                email: 'test@example.com',
                password: 'password123',
              )).thenAnswer((_) async {});
          return authBloc;
        },
        act: (bloc) => bloc.add(
          const AuthLoginSubmitted(
            email: 'test@example.com',
            password: 'password123',
          ),
        ),
        expect: () => const [
          AuthState(status: AuthStatus.loading),
          AuthState(status: AuthStatus.success),
        ],
      );

      blocTest<AuthBloc, AuthState>(
        'emits [loading, failure] when signInWithEmail throws',
        build: () {
          when(() => authRepository.signInWithEmail(
                email: 'test@example.com',
                password: 'password123',
              )).thenThrow(const AppException('E-mail ou senha inválidos'));
          return authBloc;
        },
        act: (bloc) => bloc.add(
          const AuthLoginSubmitted(
            email: 'test@example.com',
            password: 'password123',
          ),
        ),
        expect: () => const [
          AuthState(status: AuthStatus.loading),
          AuthState(
            status: AuthStatus.failure,
            errorMessage: 'E-mail ou senha inválidos',
          ),
        ],
      );
    });

    group('AuthSignUpSubmitted', () {
      blocTest<AuthBloc, AuthState>(
        'emits [loading, success] when signUpWithEmail succeeds',
        build: () {
          when(() => authRepository.signUpWithEmail(
                name: 'User Test',
                email: 'test@example.com',
                password: 'password123',
              )).thenAnswer((_) async {});
          return authBloc;
        },
        act: (bloc) => bloc.add(
          const AuthSignUpSubmitted(
            name: 'User Test',
            email: 'test@example.com',
            password: 'password123',
          ),
        ),
        expect: () => const [
          AuthState(status: AuthStatus.loading),
          AuthState(status: AuthStatus.success),
        ],
      );
    });

    group('AuthGoogleSignInRequested', () {
      blocTest<AuthBloc, AuthState>(
        'emits [loading, success] when signInWithGoogle succeeds',
        build: () {
          when(() => authRepository.signInWithGoogle()).thenAnswer((_) async {});
          return authBloc;
        },
        act: (bloc) => bloc.add(const AuthGoogleSignInRequested()),
        expect: () => const [
          AuthState(status: AuthStatus.loading),
          AuthState(status: AuthStatus.success),
        ],
      );
    });

    group('AuthFacebookSignInRequested', () {
      blocTest<AuthBloc, AuthState>(
        'emits [loading, success] when signInWithFacebook succeeds',
        build: () {
          when(() => authRepository.signInWithFacebook()).thenAnswer((_) async {});
          return authBloc;
        },
        act: (bloc) => bloc.add(const AuthFacebookSignInRequested()),
        expect: () => const [
          AuthState(status: AuthStatus.loading),
          AuthState(status: AuthStatus.success),
        ],
      );
    });

    group('AuthPasswordResetRequested', () {
      blocTest<AuthBloc, AuthState>(
        'emits [loading, success] when sendPasswordResetEmail succeeds',
        build: () {
          when(() => authRepository.sendPasswordResetEmail(any()))
              .thenAnswer((_) async {});
          return authBloc;
        },
        act: (bloc) => bloc.add(
          const AuthPasswordResetRequested(email: 'test@example.com'),
        ),
        expect: () => const [
          AuthState(status: AuthStatus.loading),
          AuthState(status: AuthStatus.success),
        ],
      );
    });
  });
}
