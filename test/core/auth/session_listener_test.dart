// ignore_for_file: subtype_of_sealed_class
import 'package:carehub_plus/core/errors/app_exception.dart';
import 'package:carehub_plus/features/auth/data/repositories/auth_repository.dart';
import 'package:carehub_plus/features/invites/data/repositories/invites_repository.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:carehub_plus/core/auth/session_listener.dart';

class MockAuthRepository extends Mock implements AuthRepository {}
class MockUser extends Mock implements User {}
class MockInvitesRepository extends Mock implements InvitesRepository {}

void main() {
  late MockAuthRepository mockAuthRepository;
  late MockUser mockUser;

  setUp(() {
    mockAuthRepository = MockAuthRepository();
    mockUser = MockUser();

    when(() => mockAuthRepository.authStateChanges)
        .thenAnswer((_) => Stream.value(mockUser));
  });

  testWidgets('claims pending invites once when the user signs in', (
    tester,
  ) async {
    final invites = MockInvitesRepository();
    when(() => mockUser.uid).thenReturn('uid-1');
    when(() => invites.claimPendingInvites()).thenAnswer((_) async => []);

    await tester.pumpWidget(
      MaterialApp(
        home: SessionListener(
          repository: mockAuthRepository,
          invitesRepository: invites,
          child: const Text('Test Child Content'),
        ),
      ),
    );
    await tester.pump();

    verify(() => invites.claimPendingInvites()).called(1);
  });

  testWidgets('a failed claim does not break the session', (tester) async {
    final invites = MockInvitesRepository();
    when(() => mockUser.uid).thenReturn('uid-1');
    when(
      () => invites.claimPendingInvites(),
    ).thenThrow(const AppException('offline'));

    await tester.pumpWidget(
      MaterialApp(
        home: SessionListener(
          repository: mockAuthRepository,
          invitesRepository: invites,
          child: const Text('Test Child Content'),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Test Child Content'), findsOneWidget);
  });

  testWidgets('SessionListener renders child widget correctly', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: SessionListener(
          repository: mockAuthRepository,
          child: const Text('Test Child Content'),
        ),
      ),
    );

    expect(find.text('Test Child Content'), findsOneWidget);
  });
}
