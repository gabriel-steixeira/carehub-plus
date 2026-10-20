/*
 * CareHub Plus — Teste / SosBloc (dono como destinatário)
 *
 * Cobre a liberação do botão de SOS quando quem pede não é o dono do perfil:
 * mesmo sem membros marcados, o dono será avisado pelo app, então o pedido
 * deve ficar válido. Também confirma o comportamento antigo (exige rede quando
 * quem pede é o dono). Repositório dublado com mocktail — sem Firebase real.
 *
 * Author: Vitoria Lana
 * Created on: 19/10/2026
 * Version: 1.0.0
 * Squad: CareHub Plus
 */

import 'package:bloc_test/bloc_test.dart';
import 'package:carehub_plus/features/home/data/models/care_recipient_model.dart';
import 'package:carehub_plus/features/sos/data/repositories/sos_repository.dart';
import 'package:carehub_plus/features/sos/presentation/bloc/sos_bloc.dart';
import 'package:carehub_plus/features/tasks/data/models/task_model.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockSosRepository extends Mock implements SosRepository {}

CareRecipientModel _profile() =>
    const CareRecipientModel(id: 'care_1', name: 'Belinha');

TaskModel _task() => TaskModel(
      id: 'task_1',
      caregiverId: 'owner_1',
      careRecipientId: 'care_1',
      title: 'Comprar ração',
      scheduledTime: DateTime(2026, 10, 19, 14),
    );

void main() {
  late _MockSosRepository repository;

  setUp(() {
    repository = _MockSosRepository();
    when(() => repository.fetchCaregiverPhotoUrl())
        .thenAnswer((_) async => null);
    when(() => repository.fetchProfiles())
        .thenAnswer((_) async => [_profile()]);
    when(() => repository.fetchSupportNetwork(careRecipientId: 'care_1'))
        .thenAnswer((_) async => []);
    when(() => repository.fetchOpenTasks(careRecipientId: 'care_1'))
        .thenAnswer((_) async => [_task()]);
  });

  group('SosLoadEvent with empty network', () {
    blocTest<SosBloc, SosState>(
      'frees canTriggerAlert when the requester is not the owner',
      build: () {
        when(() => repository.isCurrentUserOwnerOf('care_1'))
            .thenAnswer((_) async => false);
        return SosBloc(repository: repository);
      },
      act: (bloc) => bloc.add(const SosLoadEvent(careRecipientId: 'care_1')),
      verify: (bloc) {
        expect(bloc.state.isRequesterOwner, isFalse);
        expect(bloc.state.ownerWillBeNotified, isTrue);
        expect(bloc.state.notifiedMemberIds, isEmpty);
        expect(bloc.state.canTriggerAlert, isTrue);
      },
    );

    blocTest<SosBloc, SosState>(
      'keeps canTriggerAlert false when the owner asks and has no network',
      build: () {
        when(() => repository.isCurrentUserOwnerOf('care_1'))
            .thenAnswer((_) async => true);
        return SosBloc(repository: repository);
      },
      act: (bloc) => bloc.add(const SosLoadEvent(careRecipientId: 'care_1')),
      verify: (bloc) {
        expect(bloc.state.isRequesterOwner, isTrue);
        expect(bloc.state.ownerWillBeNotified, isFalse);
        expect(bloc.state.notifiedMemberIds, isEmpty);
        expect(bloc.state.canTriggerAlert, isFalse);
      },
    );
  });
}
