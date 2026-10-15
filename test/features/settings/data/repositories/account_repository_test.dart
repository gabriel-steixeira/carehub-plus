/*
 * CareHub Plus — Testes / Repositório da conta
 *
 * Confere o disparo da exclusão (callable) e a resolução dos três casos de
 * impacto a partir de snapshots do Firestore, além do caminho de erro que
 * vira AppException. Nenhuma chamada real ao Firebase (mocktail + dublê).
 *
 * Author: Vitoria Lana
 * Created on: 15/10/2026
 * Version: 1.0.0
 * Squad: CareHub Plus
 */

// ignore_for_file: subtype_of_sealed_class
import 'package:carehub_plus/core/errors/app_exception.dart';
import 'package:carehub_plus/features/settings/data/repositories/account_repository.dart';
import 'package:carehub_plus/features/settings/domain/entities/delete_account_preview.dart';
import 'package:carehub_plus/services/cloud_functions_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../helpers/fake_callable_client.dart';

class MockFirebaseFirestore extends Mock implements FirebaseFirestore {}

class MockFirebaseAuth extends Mock implements FirebaseAuth {}

class MockUser extends Mock implements User {}

class MockCollectionReference extends Mock
    implements CollectionReference<Map<String, dynamic>> {}

class MockQuery extends Mock implements Query<Map<String, dynamic>> {}

class MockQuerySnapshot extends Mock
    implements QuerySnapshot<Map<String, dynamic>> {}

class MockQueryDocumentSnapshot extends Mock
    implements QueryDocumentSnapshot<Map<String, dynamic>> {}

void main() {
  late MockFirebaseFirestore firestore;
  late MockFirebaseAuth auth;
  late MockUser user;
  late MockCollectionReference recipientsCollection;
  late MockCollectionReference membersCollection;

  const uid = 'owner_uid';

  setUp(() {
    firestore = MockFirebaseFirestore();
    auth = MockFirebaseAuth();
    user = MockUser();
    recipientsCollection = MockCollectionReference();
    membersCollection = MockCollectionReference();

    when(() => auth.currentUser).thenReturn(user);
    when(() => user.uid).thenReturn(uid);

    when(() => firestore.collection('care_recipients'))
        .thenReturn(recipientsCollection);
    when(() => firestore.collection('network_members'))
        .thenReturn(membersCollection);
  });

  /// Prepara `care_recipients where caregiverId == uid` com os perfis dados.
  void stubOwnedRecipients(
    List<MockQueryDocumentSnapshot> docs, {
    Object? error,
  }) {
    final query = MockQuery();
    final snapshot = MockQuerySnapshot();
    when(() => recipientsCollection.where('caregiverId', isEqualTo: uid))
        .thenReturn(query);
    if (error != null) {
      when(() => query.get()).thenThrow(error);
    } else {
      when(() => query.get()).thenAnswer((_) async => snapshot);
      when(() => snapshot.docs).thenReturn(docs);
    }
  }

  /// Perfil com os `accessUids` e os nomes de membros informados.
  MockQueryDocumentSnapshot recipientDoc(
    String id, {
    required List<String> accessUids,
    List<String> memberNames = const [],
  }) {
    final doc = MockQueryDocumentSnapshot();
    when(() => doc.id).thenReturn(id);
    when(() => doc.data()).thenReturn({'accessUids': accessUids});

    final memberDocs = [for (final name in memberNames) _memberDoc(name)];
    final query = MockQuery();
    final snapshot = MockQuerySnapshot();
    when(() => membersCollection.where('careRecipientId', isEqualTo: id))
        .thenReturn(query);
    when(() => query.get()).thenAnswer((_) async => snapshot);
    when(() => snapshot.docs).thenReturn(memberDocs);

    return doc;
  }

  AccountRepository buildRepository(CallableClient client) =>
      AccountRepository(client: client, firestore: firestore, auth: auth);

  group('deleteAccount', () {
    test('calls the deleteAccount callable', () async {
      final client = FakeCallableClient();
      await buildRepository(client).deleteAccount();

      expect(client.calls.single.name, 'deleteAccount');
    });
  });

  group('resolveDeletionCase', () {
    test('soloOrGrantee when the account owns no profile', () async {
      stubOwnedRecipients(const []);

      final preview =
          await buildRepository(FakeCallableClient()).resolveDeletionCase();

      expect(preview.deletionCase, DeletionCase.soloOrGrantee);
      expect(preview.affectedNames, isEmpty);
    });

    test('ownerNoOthers when nobody else has access', () async {
      stubOwnedRecipients([
        recipientDoc('rid_1', accessUids: const [uid]),
      ]);

      final preview =
          await buildRepository(FakeCallableClient()).resolveDeletionCase();

      expect(preview.deletionCase, DeletionCase.ownerNoOthers);
      expect(preview.affectedNames, isEmpty);
    });

    test('ownerWithOthers names the affected caregivers', () async {
      stubOwnedRecipients([
        recipientDoc(
          'rid_1',
          accessUids: const [uid, 'other_uid'],
          memberNames: const ['Vitor'],
        ),
      ]);

      final preview =
          await buildRepository(FakeCallableClient()).resolveDeletionCase();

      expect(preview.deletionCase, DeletionCase.ownerWithOthers);
      expect(preview.affectedNames, ['Vitor']);
    });

    test('maps a FirebaseException to AppException', () async {
      stubOwnedRecipients(
        const [],
        error: FirebaseException(plugin: 'firestore', message: 'offline'),
      );

      expect(
        buildRepository(FakeCallableClient()).resolveDeletionCase(),
        throwsA(isA<AppException>()),
      );
    });
  });
}

MockQueryDocumentSnapshot _memberDoc(String name) {
  final doc = MockQueryDocumentSnapshot();
  when(() => doc.data()).thenReturn({'name': name});
  return doc;
}
