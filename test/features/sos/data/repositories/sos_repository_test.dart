/*
 * CareHub Plus — Teste / Repositório de SOS (aceite)
 *
 * Cobre a chamada ao backend feita por `SosRepository.acceptAlert`: garante
 * que a Cloud Function certa é chamada com o `alertId` e que o erro do client
 * (já convertido em `AppException`) sobe sem ser re-embrulhado. Sem Firebase
 * real — o `CallableClient` é dublado com mocktail.
 *
 * Author: Vitoria Lana
 * Created on: 18/10/2026
 * Version: 1.0.0
 * Squad: CareHub Plus
 */

import 'package:carehub_plus/core/errors/app_exception.dart';
import 'package:carehub_plus/features/assistants/data/repositories/caregiver_avatar_repository.dart';
import 'package:carehub_plus/features/home/data/repositories/home_repository.dart';
import 'package:carehub_plus/features/network/data/repositories/network_repository.dart';
import 'package:carehub_plus/features/sos/data/repositories/sos_repository.dart';
import 'package:carehub_plus/features/tasks/data/repositories/tasks_repository.dart';
import 'package:carehub_plus/services/cloud_functions_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockCallableClient extends Mock implements CallableClient {}

class _MockFirestore extends Mock implements FirebaseFirestore {}

class _MockAuth extends Mock implements FirebaseAuth {}

class _MockHomeRepository extends Mock implements HomeRepository {}

class _MockTasksRepository extends Mock implements TasksRepository {}

class _MockNetworkRepository extends Mock implements NetworkRepository {}

class _MockCaregiverAvatarRepository extends Mock
    implements CaregiverAvatarRepository {}

void main() {
  late _MockCallableClient client;
  late SosRepository repository;

  setUp(() {
    client = _MockCallableClient();
    // As sub-dependências são dubladas só para evitar que o construtor
    // padrão toque o Firebase; `acceptAlert` usa apenas o `CallableClient`.
    repository = SosRepository(
      client: client,
      firestore: _MockFirestore(),
      auth: _MockAuth(),
      homeRepository: _MockHomeRepository(),
      tasksRepository: _MockTasksRepository(),
      networkRepository: _MockNetworkRepository(),
      caregiverAvatarRepository: _MockCaregiverAvatarRepository(),
    );
  });

  group('acceptAlert', () {
    test('calls acceptSosAlert with the alertId', () async {
      when(
        () => client.call('acceptSosAlert', {'alertId': 'sos_1'}),
      ).thenAnswer((_) async => const {'status': 'accepted_first'});

      await repository.acceptAlert('sos_1');

      verify(
        () => client.call('acceptSosAlert', {'alertId': 'sos_1'}),
      ).called(1);
    });

    test('propagates the AppException raised by the client', () async {
      when(
        () => client.call('acceptSosAlert', {'alertId': 'sos_1'}),
      ).thenThrow(const AppException('Você não foi acionada neste pedido.'));

      expect(
        () => repository.acceptAlert('sos_1'),
        throwsA(isA<AppException>()),
      );
    });
  });
}
