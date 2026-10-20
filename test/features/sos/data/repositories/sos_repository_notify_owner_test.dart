/*
 * CareHub Plus — Teste / SosRepository.notifySupportNetwork (dono)
 *
 * Confere que o documento gravado em `sos_alerts` carrega os campos do
 * contrato (`notifyOwner` e `ownerChannel`) conforme quem pede: um membro de
 * um perfil cuja contraparte é a dona grava `notifyOwner: true` com o canal
 * lido de `caregivers/{dono}`, enquanto o dono abrindo o próprio SOS não se
 * auto-notifica. O Firestore é dublado com mocktail — sem acesso real.
 *
 * Author: Vitoria Lana
 * Created on: 19/10/2026
 * Version: 1.0.0
 * Squad: CareHub Plus
 */

// Os dublês abaixo implementam tipos selados do cloud_firestore
// (CollectionReference/DocumentReference/DocumentSnapshot). É o padrão de mock
// com mocktail para isolar o Firestore — por isso suprimimos o aviso do lint.
// ignore_for_file: subtype_of_sealed_class

import 'package:carehub_plus/features/assistants/data/repositories/caregiver_avatar_repository.dart';
import 'package:carehub_plus/features/home/data/repositories/home_repository.dart';
import 'package:carehub_plus/features/network/data/repositories/network_repository.dart';
import 'package:carehub_plus/features/sos/data/repositories/sos_repository.dart';
import 'package:carehub_plus/features/sos/domain/entities/sos_help_request_entity.dart';
import 'package:carehub_plus/features/tasks/data/repositories/tasks_repository.dart';
import 'package:carehub_plus/services/cloud_functions_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockCallableClient extends Mock implements CallableClient {}

class _MockFirestore extends Mock implements FirebaseFirestore {}

class _MockAuth extends Mock implements FirebaseAuth {}

class _MockUser extends Mock implements User {}

class _MockHomeRepository extends Mock implements HomeRepository {}

class _MockTasksRepository extends Mock implements TasksRepository {}

class _MockNetworkRepository extends Mock implements NetworkRepository {}

class _MockCaregiverAvatarRepository extends Mock
    implements CaregiverAvatarRepository {}

class _MockCollection extends Mock
    implements CollectionReference<Map<String, dynamic>> {}

class _MockDoc extends Mock
    implements DocumentReference<Map<String, dynamic>> {}

class _MockSnapshot extends Mock
    implements DocumentSnapshot<Map<String, dynamic>> {}

void main() {
  late _MockFirestore firestore;
  late _MockAuth auth;
  late _MockUser user;
  late SosRepository repository;

  // Documentos usados nas leituras/escrita.
  late _MockCollection careRecipients;
  late _MockCollection caregivers;
  late _MockCollection sosAlerts;
  late _MockDoc careRecipientDoc;
  late _MockDoc caregiverDoc;
  late _MockDoc alertDoc;

  setUpAll(() {
    registerFallbackValue(<String, dynamic>{});
  });

  setUp(() {
    firestore = _MockFirestore();
    auth = _MockAuth();
    user = _MockUser();
    careRecipients = _MockCollection();
    caregivers = _MockCollection();
    sosAlerts = _MockCollection();
    careRecipientDoc = _MockDoc();
    caregiverDoc = _MockDoc();
    alertDoc = _MockDoc();

    when(() => auth.currentUser).thenReturn(user);
    when(() => user.displayName).thenReturn('Vitoria');

    when(() => firestore.collection('care_recipients'))
        .thenReturn(careRecipients);
    when(() => firestore.collection('caregivers')).thenReturn(caregivers);
    when(() => firestore.collection('sos_alerts')).thenReturn(sosAlerts);

    when(() => careRecipients.doc('care_1')).thenReturn(careRecipientDoc);
    when(() => sosAlerts.doc(any())).thenReturn(alertDoc);
    when(() => alertDoc.set(any())).thenAnswer((_) async {});

    repository = SosRepository(
      client: _MockCallableClient(),
      firestore: firestore,
      auth: auth,
      homeRepository: _MockHomeRepository(),
      tasksRepository: _MockTasksRepository(),
      networkRepository: _MockNetworkRepository(),
      caregiverAvatarRepository: _MockCaregiverAvatarRepository(),
    );
  });

  SosHelpRequestEntity request({
    List<String> notifiedMemberIds = const ['member_1'],
    bool notifyOwner = true,
  }) =>
      SosHelpRequestEntity(
        careRecipientId: 'care_1',
        taskId: 'task_1',
        taskTitle: 'Comprar ração',
        notifiedMemberIds: notifiedMemberIds,
        notifyOwner: notifyOwner,
      );

  void stubOwner(String ownerUid) {
    final snapshot = _MockSnapshot();
    when(() => careRecipientDoc.get()).thenAnswer((_) async => snapshot);
    when(() => snapshot.data()).thenReturn({'caregiverId': ownerUid});
  }

  void stubOwnerChannel(String ownerUid, Object? channelValue) {
    when(() => caregivers.doc(ownerUid)).thenReturn(caregiverDoc);
    final snapshot = _MockSnapshot();
    when(() => caregiverDoc.get()).thenAnswer((_) async => snapshot);
    when(() => snapshot.data())
        .thenReturn({'sosAlertChannel': channelValue});
  }

  Map<String, dynamic> capturedWrite() {
    final captured = verify(() => alertDoc.set(captureAny())).captured;
    return captured.last as Map<String, dynamic>;
  }

  group('notifySupportNetwork', () {
    test('writes notifyOwner true and ownerChannel app by default', () async {
      when(() => user.uid).thenReturn('member_uid');
      stubOwner('owner_1');
      stubOwnerChannel('owner_1', null); // ausente => app

      await repository.notifySupportNetwork(
        request(notifiedMemberIds: const []),
      );

      final data = capturedWrite();
      expect(data['notifyOwner'], isTrue);
      expect(data['ownerChannel'], 'app');
    });

    test('writes ownerChannel whatsapp when the owner prefers it', () async {
      when(() => user.uid).thenReturn('member_uid');
      stubOwner('owner_1');
      stubOwnerChannel('owner_1', 'whatsapp');

      await repository.notifySupportNetwork(request());

      final data = capturedWrite();
      expect(data['notifyOwner'], isTrue);
      expect(data['ownerChannel'], 'whatsapp');
    });

    test('does not set notifyOwner when the owner opens the own SOS', () async {
      when(() => user.uid).thenReturn('owner_1');
      stubOwner('owner_1');

      await repository.notifySupportNetwork(
        request(notifyOwner: false),
      );

      final data = capturedWrite();
      expect(data.containsKey('notifyOwner'), isFalse);
      expect(data.containsKey('ownerChannel'), isFalse);
      // O canal do dono não é consultado quando ele mesmo abre o SOS.
      verifyNever(() => caregivers.doc(any()));
    });
  });
}
