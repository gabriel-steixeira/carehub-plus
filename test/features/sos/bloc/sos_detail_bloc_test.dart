/*
 * CareHub Plus — Teste / BLoC do detalhe do SOS
 *
 * Cobre as transições de estado da tela de detalhe: carregar os detalhes do
 * pedido (sucesso e falha) e processar o aceite (sucesso e falha). O
 * repositório é dublado com mocktail — nenhum acesso real ao Firebase.
 *
 * Author: Vitoria Lana
 * Created on: 18/10/2026
 * Version: 1.0.0
 * Squad: CareHub Plus
 */

import 'package:bloc_test/bloc_test.dart';
import 'package:carehub_plus/core/errors/app_exception.dart';
import 'package:carehub_plus/features/sos/data/repositories/sos_repository.dart';
import 'package:carehub_plus/features/sos/domain/entities/sos_alert_snapshot_entity.dart';
import 'package:carehub_plus/features/sos/presentation/bloc/sos_detail_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../helpers/fake_entities.dart';

class _MockSosRepository extends Mock implements SosRepository {}

void main() {
  late _MockSosRepository repository;

  setUp(() => repository = _MockSosRepository());

  group('SosDetailLoadRequested', () {
    blocTest<SosDetailBloc, SosDetailState>(
      'emits [loading, success] when fetchAlertDetail succeeds',
      build: () {
        when(
          () => repository.fetchAlertDetail('sos_1'),
        ).thenAnswer((_) async => fakeSosAlertDetail());
        return SosDetailBloc(repository: repository);
      },
      act: (bloc) => bloc.add(const SosDetailLoadRequested('sos_1')),
      expect: () => [
        const SosDetailState(status: SosDetailStatus.loading),
        SosDetailState(
          status: SosDetailStatus.success,
          detail: fakeSosAlertDetail(),
        ),
      ],
    );

    blocTest<SosDetailBloc, SosDetailState>(
      'emits [loading, failure] when fetchAlertDetail throws',
      build: () {
        when(
          () => repository.fetchAlertDetail('sos_1'),
        ).thenThrow(const AppException('Pedido não encontrado.'));
        return SosDetailBloc(repository: repository);
      },
      act: (bloc) => bloc.add(const SosDetailLoadRequested('sos_1')),
      expect: () => [
        const SosDetailState(status: SosDetailStatus.loading),
        const SosDetailState(
          status: SosDetailStatus.failure,
          errorMessage: 'Pedido não encontrado.',
        ),
      ],
    );
  });

  group('SosDetailAcceptRequested', () {
    blocTest<SosDetailBloc, SosDetailState>(
      'emits [accepting, accepted] when acceptAlert succeeds',
      build: () {
        when(
          () => repository.fetchAlertDetail('sos_1'),
        ).thenAnswer((_) async => fakeSosAlertDetail());
        when(() => repository.acceptAlert('sos_1')).thenAnswer((_) async {});
        when(() => repository.fetchAlertDetail('sos_1')).thenAnswer(
          (_) async => fakeSosAlertDetail(
            status: SosAlertStatus.accepted,
            acceptedByMemberId: 'member_1',
          ),
        );
        return SosDetailBloc(repository: repository);
      },
      // Carrega primeiro para o BLoC guardar o alertId usado no aceite.
      seed: () => SosDetailState(
        status: SosDetailStatus.success,
        detail: fakeSosAlertDetail(),
      ),
      act: (bloc) async {
        bloc.add(const SosDetailLoadRequested('sos_1'));
        await Future<void>.delayed(Duration.zero);
        bloc.add(const SosDetailAcceptRequested());
      },
      skip: 2,
      expect: () => [
        isA<SosDetailState>().having(
          (s) => s.status,
          'status',
          SosDetailStatus.accepting,
        ),
        isA<SosDetailState>()
            .having((s) => s.status, 'status', SosDetailStatus.accepted)
            .having(
              (s) => s.detail?.status,
              'detail.status',
              SosAlertStatus.accepted,
            ),
      ],
    );

    blocTest<SosDetailBloc, SosDetailState>(
      'emits [accepting, failure] when acceptAlert throws',
      build: () {
        when(
          () => repository.fetchAlertDetail('sos_1'),
        ).thenAnswer((_) async => fakeSosAlertDetail());
        when(
          () => repository.acceptAlert('sos_1'),
        ).thenThrow(const AppException('Você não foi acionada neste pedido.'));
        return SosDetailBloc(repository: repository);
      },
      act: (bloc) async {
        bloc.add(const SosDetailLoadRequested('sos_1'));
        await Future<void>.delayed(Duration.zero);
        bloc.add(const SosDetailAcceptRequested());
      },
      skip: 2,
      expect: () => [
        isA<SosDetailState>().having(
          (s) => s.status,
          'status',
          SosDetailStatus.accepting,
        ),
        isA<SosDetailState>()
            .having((s) => s.status, 'status', SosDetailStatus.failure)
            .having(
              (s) => s.errorMessage,
              'errorMessage',
              'Você não foi acionada neste pedido.',
            ),
      ],
    );
  });
}
