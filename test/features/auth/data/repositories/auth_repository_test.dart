// ignore_for_file: subtype_of_sealed_class, unused_import
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:carehub_plus/core/errors/app_exception.dart';
import 'package:carehub_plus/core/errors/failures.dart';
import 'package:carehub_plus/features/auth/data/repositories/auth_repository.dart';
import 'package:carehub_plus/services/auth_service.dart';

class MockAuthService extends Mock implements AuthService {}
class MockFirebaseFirestore extends Mock implements FirebaseFirestore {}
class MockCollectionReference extends Mock implements CollectionReference<Map<String, dynamic>> {}
class MockDocumentReference extends Mock implements DocumentReference<Map<String, dynamic>> {}
class MockDocumentSnapshot extends Mock implements DocumentSnapshot<Map<String, dynamic>> {}
class MockUserCredential extends Mock implements UserCredential {}
class MockUser extends Mock implements User {}

void main() {
  late MockAuthService mockAuthService;
  late MockFirebaseFirestore mockFirestore;
  late MockCollectionReference mockCollectionReference;
  late MockDocumentReference mockDocumentReference;
  late MockDocumentSnapshot mockDocumentSnapshot;
  late MockUserCredential mockUserCredential;
  late MockUser mockUser;
  late AuthRepository authRepository;

  setUp(() {
    mockAuthService = MockAuthService();
    mockFirestore = MockFirebaseFirestore();
    mockCollectionReference = MockCollectionReference();
    mockDocumentReference = MockDocumentReference();
    mockDocumentSnapshot = MockDocumentSnapshot();
    mockUserCredential = MockUserCredential();
    mockUser = MockUser();

    authRepository = AuthRepository(
      authService: mockAuthService,
      firestore: mockFirestore,
    );

    // Default setups
    when(() => mockFirestore.collection(any())).thenReturn(mockCollectionReference);
    when(() => mockCollectionReference.doc(any())).thenReturn(mockDocumentReference);
    when(() => mockDocumentReference.get()).thenAnswer((_) async => mockDocumentSnapshot);
    when(() => mockDocumentReference.set(any())).thenAnswer((_) async {});
  });

  group('AuthRepository', () {
    group('signInWithEmail', () {
      test('succeeds when AuthService succeeds', () async {
        when(() => mockAuthService.signInWithEmail(
              email: 'test@example.com',
              password: 'password123',
            )).thenAnswer((_) async => mockUserCredential);

        await expectLater(
          authRepository.signInWithEmail(
            email: 'test@example.com',
            password: 'password123',
          ),
          completes,
        );
      });

      test('throws InvalidCredentialsFailure when wrong-password is thrown', () async {
        when(() => mockAuthService.signInWithEmail(
              email: 'test@example.com',
              password: 'wrongpassword',
            )).thenThrow(FirebaseAuthException(code: 'wrong-password'));

        await expectLater(
          authRepository.signInWithEmail(
            email: 'test@example.com',
            password: 'wrongpassword',
          ),
          throwsA(isA<InvalidCredentialsFailure>()),
        );
      });
    });

    group('signUpWithEmail', () {
      test('succeeds and creates caregiver document when AuthService succeeds', () async {
        when(() => mockAuthService.signUpWithEmail(
              name: 'Test User',
              email: 'test@example.com',
              password: 'password123',
            )).thenAnswer((_) async => mockUserCredential);
        when(() => mockUserCredential.user).thenReturn(mockUser);
        when(() => mockUser.uid).thenReturn('user123');
        when(() => mockUser.photoURL).thenReturn(null);

        await expectLater(
          authRepository.signUpWithEmail(
            name: 'Test User',
            email: 'test@example.com',
            password: 'password123',
          ),
          completes,
        );

        verify(() => mockFirestore.collection('caregivers')).called(1);
        verify(() => mockCollectionReference.doc('user123')).called(1);
        verify(() => mockDocumentReference.set(any())).called(1);
      });
    });

    group('signInWithGoogle', () {
      test('succeeds and ensures caregiver document is created if new', () async {
        when(() => mockAuthService.signInWithGoogle())
            .thenAnswer((_) async => mockUserCredential);
        when(() => mockUserCredential.user).thenReturn(mockUser);
        when(() => mockUser.uid).thenReturn('google123');
        when(() => mockUser.displayName).thenReturn('Google User');
        when(() => mockUser.email).thenReturn('google@example.com');
        when(() => mockUser.photoURL).thenReturn('https://photo.url');
        when(() => mockDocumentSnapshot.exists).thenReturn(false);

        await expectLater(authRepository.signInWithGoogle(), completes);

        verify(() => mockDocumentReference.get()).called(1);
        verify(() => mockDocumentReference.set(any())).called(1);
      });

      test('succeeds and does not set caregiver document if already exists', () async {
        when(() => mockAuthService.signInWithGoogle())
            .thenAnswer((_) async => mockUserCredential);
        when(() => mockUserCredential.user).thenReturn(mockUser);
        when(() => mockUser.uid).thenReturn('google123');
        when(() => mockDocumentSnapshot.exists).thenReturn(true);

        await expectLater(authRepository.signInWithGoogle(), completes);

        verify(() => mockDocumentReference.get()).called(1);
        verifyNever(() => mockDocumentReference.set(any()));
      });
    });

    group('signInWithFacebook', () {
      test('succeeds and ensures caregiver document is created if new', () async {
        when(() => mockAuthService.signInWithFacebook())
            .thenAnswer((_) async => mockUserCredential);
        when(() => mockUserCredential.user).thenReturn(mockUser);
        when(() => mockUser.uid).thenReturn('fb123');
        when(() => mockUser.displayName).thenReturn('FB User');
        when(() => mockUser.email).thenReturn('fb@example.com');
        when(() => mockUser.photoURL).thenReturn(null);
        when(() => mockDocumentSnapshot.exists).thenReturn(false);

        await expectLater(authRepository.signInWithFacebook(), completes);

        verify(() => mockDocumentReference.get()).called(1);
        verify(() => mockDocumentReference.set(any())).called(1);
      });
    });

    group('signOut', () {
      test('succeeds when AuthService succeeds', () async {
        when(() => mockAuthService.signOut()).thenAnswer((_) async {});

        await expectLater(authRepository.signOut(), completes);
      });
    });
  });
}
