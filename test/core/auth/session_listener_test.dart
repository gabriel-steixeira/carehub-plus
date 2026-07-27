// ignore_for_file: subtype_of_sealed_class
import 'package:carehub_plus/features/auth/data/repositories/auth_repository.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:carehub_plus/core/auth/session_listener.dart';

class MockAuthRepository extends Mock implements AuthRepository {}
class MockUser extends Mock implements User {}

void main() {
  late MockAuthRepository mockAuthRepository;
  late MockUser mockUser;

  setUp(() {
    mockAuthRepository = MockAuthRepository();
    mockUser = MockUser();

    when(() => mockAuthRepository.authStateChanges)
        .thenAnswer((_) => Stream.value(mockUser));
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
