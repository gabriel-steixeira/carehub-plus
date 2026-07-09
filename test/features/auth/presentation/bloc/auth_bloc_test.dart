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

    group('AuthPasswordResetRequested', () {
      blocTest<AuthBloc, AuthState>(
        'emits [loading, success] when sendPasswordResetEmail succeeds',
        build: () {
          when(
            () => authRepository.sendPasswordResetEmail(any()),
          ).thenAnswer((_) async {});
          return authBloc;
        },
        act: (bloc) => bloc.add(
          const AuthPasswordResetRequested(email: 'test@example.com'),
        ),
        expect: () => const [
          AuthState(status: AuthStatus.loading),
          AuthState(status: AuthStatus.success),
        ],
        verify: (_) {
          verify(
            () => authRepository.sendPasswordResetEmail('test@example.com'),
          ).called(1);
        },
      );

      blocTest<AuthBloc, AuthState>(
        'emits [loading, failure] when sendPasswordResetEmail throws',
        build: () {
          when(
            () => authRepository.sendPasswordResetEmail(any()),
          ).thenThrow(const AppException('E-mail inválido'));
          return authBloc;
        },
        act: (bloc) =>
            bloc.add(const AuthPasswordResetRequested(email: 'invalid-email')),
        expect: () => const [
          AuthState(status: AuthStatus.loading),
          AuthState(
            status: AuthStatus.failure,
            errorMessage: 'AppException(null): E-mail inválido',
          ),
        ],
        verify: (_) {
          verify(
            () => authRepository.sendPasswordResetEmail('invalid-email'),
          ).called(1);
        },
      );
    });
  });
}
