// ignore_for_file: subtype_of_sealed_class
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:carehub_plus/features/home/data/repositories/home_repository.dart';

class MockFirebaseFirestore extends Mock implements FirebaseFirestore {}
class MockFirebaseAuth extends Mock implements FirebaseAuth {}
class MockCollectionReference extends Mock implements CollectionReference<Map<String, dynamic>> {}
class MockDocumentReference extends Mock implements DocumentReference<Map<String, dynamic>> {}
class MockDocumentSnapshot extends Mock implements DocumentSnapshot<Map<String, dynamic>> {}
class MockQuerySnapshot extends Mock implements QuerySnapshot<Map<String, dynamic>> {}
class MockQuery extends Mock implements Query<Map<String, dynamic>> {}
class MockUser extends Mock implements User {}

void main() {
  late MockFirebaseFirestore mockFirestore;
  late MockFirebaseAuth mockAuth;
  late MockCollectionReference mockCollectionReference;
  late MockDocumentReference mockDocumentReference;
  late MockDocumentSnapshot mockDocumentSnapshot;
  late MockQuerySnapshot mockQuerySnapshot;
  late MockQuery mockQuery;
  late MockUser mockUser;
  late HomeRepository repository;

  setUp(() {
    mockFirestore = MockFirebaseFirestore();
    mockAuth = MockFirebaseAuth();
    mockCollectionReference = MockCollectionReference();
    mockDocumentReference = MockDocumentReference();
    mockDocumentSnapshot = MockDocumentSnapshot();
    mockQuerySnapshot = MockQuerySnapshot();
    mockQuery = MockQuery();
    mockUser = MockUser();

    when(() => mockAuth.currentUser).thenReturn(mockUser);
    when(() => mockUser.uid).thenReturn('user_123');
    when(() => mockUser.displayName).thenReturn('Gabriel');
    when(() => mockUser.email).thenReturn('gabriel@example.com');
    when(() => mockUser.photoURL).thenReturn(null);

    when(() => mockFirestore.collection(any())).thenReturn(mockCollectionReference);
    when(() => mockCollectionReference.doc(any())).thenReturn(mockDocumentReference);
    when(() => mockDocumentReference.get()).thenAnswer((_) async => mockDocumentSnapshot);
    when(() => mockCollectionReference.where(any(), isEqualTo: any(named: 'isEqualTo'))).thenReturn(mockQuery);
    when(() => mockQuery.get()).thenAnswer((_) async => mockQuerySnapshot);
    when(() => mockQuerySnapshot.docs).thenReturn([]);

    repository = HomeRepository(
      firestore: mockFirestore,
      auth: mockAuth,
    );
  });

  group('HomeRepository', () {
    test('fetchCaregiver returns caregiver profile from currentUser when doc does not exist', () async {
      when(() => mockDocumentSnapshot.exists).thenReturn(false);

      final caregiver = await repository.fetchCaregiver();

      expect(caregiver.id, equals('user_123'));
      expect(caregiver.name, equals('Gabriel'));
      expect(caregiver.email, equals('gabriel@example.com'));
    });

    test('fetchCareRecipients returns empty list when no documents in Firestore', () async {
      final recipients = await repository.fetchCareRecipients();

      expect(recipients, isEmpty);
    });
  });
}
