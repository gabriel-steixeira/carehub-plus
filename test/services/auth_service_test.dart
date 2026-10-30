/*
 * CareHub Plus — Test / AuthService reauthentication
 *
 * Verifies the reauthentication flows added to AuthService (password, Google)
 * and the currentProviderIds getter, using mocktail so no real Firebase call
 * is made.
 *
 * Author: Vitoria Lana
 * Created on: 15/10/2026
 * Version: 1.0.0
 * Squad: CareHub Plus
 */

// ignore_for_file: subtype_of_sealed_class
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:mocktail/mocktail.dart';

import 'package:carehub_plus/services/auth_service.dart';

class MockFirebaseAuth extends Mock implements FirebaseAuth {}

class MockGoogleSignIn extends Mock implements GoogleSignIn {}

class MockUser extends Mock implements User {}

class MockUserInfo extends Mock implements UserInfo {}

class FakeAuthCredential extends Fake implements AuthCredential {}

void main() {
  late MockFirebaseAuth mockFirebaseAuth;
  late MockGoogleSignIn mockGoogleSignIn;
  late MockUser mockUser;
  late AuthService authService;

  setUpAll(() {
    registerFallbackValue(FakeAuthCredential());
  });

  setUp(() {
    mockFirebaseAuth = MockFirebaseAuth();
    mockGoogleSignIn = MockGoogleSignIn();
    mockUser = MockUser();

    authService = AuthService(
      firebaseAuth: mockFirebaseAuth,
      googleSignIn: mockGoogleSignIn,
    );
  });

  group('reauthenticateWithPassword', () {
    test('calls reauthenticateWithCredential on the current user', () async {
      when(() => mockFirebaseAuth.currentUser).thenReturn(mockUser);
      when(() => mockUser.email).thenReturn('vitoria@example.com');
      when(() => mockUser.reauthenticateWithCredential(any()))
          .thenAnswer((_) async => MockUserCredential());

      await authService.reauthenticateWithPassword('password123');

      verify(() => mockUser.reauthenticateWithCredential(any())).called(1);
    });

    test('throws FirebaseAuthException when there is no current user',
        () async {
      when(() => mockFirebaseAuth.currentUser).thenReturn(null);

      await expectLater(
        authService.reauthenticateWithPassword('password123'),
        throwsA(
          isA<FirebaseAuthException>()
              .having((e) => e.code, 'code', 'no-current-user'),
        ),
      );
    });
  });

  group('currentProviderIds', () {
    test('reflects the provider ids from the current user providerData', () {
      final passwordInfo = MockUserInfo();
      final googleInfo = MockUserInfo();
      when(() => passwordInfo.providerId).thenReturn('password');
      when(() => googleInfo.providerId).thenReturn('google.com');

      when(() => mockFirebaseAuth.currentUser).thenReturn(mockUser);
      when(() => mockUser.providerData)
          .thenReturn(<UserInfo>[passwordInfo, googleInfo]);

      expect(
        authService.currentProviderIds,
        equals(<String>['password', 'google.com']),
      );
    });

    test('returns an empty list when there is no current user', () {
      when(() => mockFirebaseAuth.currentUser).thenReturn(null);

      expect(authService.currentProviderIds, isEmpty);
    });
  });
}

class MockUserCredential extends Mock implements UserCredential {}
