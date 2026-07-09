import 'package:flutter_test/flutter_test.dart';
import 'package:carehub_plus/core/errors/app_exception.dart';
import 'package:carehub_plus/features/auth/data/repositories/auth_repository.dart';

void main() {
  late AuthRepository authRepository;

  setUp(() {
    authRepository = AuthRepository();
  });

  group('AuthRepository', () {
    group('sendPasswordResetEmail', () {
      test('succeeds when email is not empty', () async {
        expect(
          authRepository.sendPasswordResetEmail('test@example.com'),
          completes,
        );
      });

      test('throws AppException when email is empty', () async {
        expect(
          authRepository.sendPasswordResetEmail(''),
          throwsA(isA<AppException>()),
        );
      });
    });
  });
}
