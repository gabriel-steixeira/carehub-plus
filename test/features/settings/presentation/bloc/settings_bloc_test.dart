/*
 * CareHub Plus — Testes / SettingsBloc (exclusão de conta)
 *
 * Cobre os handlers novos do fluxo de exclusão: resolver o caso de impacto
 * (os três cenários) e excluir a conta (sucesso e falha). Usa mocktail para
 * os repositórios, sem chamada real ao Firebase.
 *
 * Author: Vitoria Lana
 * Created on: 15/10/2026
 * Version: 1.0.0
 * Squad: CareHub Plus
 */

import 'package:bloc_test/bloc_test.dart';
import 'package:carehub_plus/core/errors/app_exception.dart';
import 'package:carehub_plus/features/settings/data/repositories/account_repository.dart';
import 'package:carehub_plus/features/settings/data/repositories/settings_repository.dart';
import 'package:carehub_plus/features/settings/domain/entities/delete_account_preview.dart';
import 'package:carehub_plus/features/settings/presentation/bloc/settings_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockSettingsRepository extends Mock implements SettingsRepository {}

class MockAccountRepository extends Mock implements AccountRepository {}

void main() {
  late MockSettingsRepository settingsRepository;
  late MockAccountRepository accountRepository;

  setUp(() {
    settingsRepository = MockSettingsRepository();
    accountRepository = MockAccountRepository();
  });

  SettingsBloc buildBloc() => SettingsBloc(
        repository: settingsRepository,
        accountRepository: accountRepository,
      );

  group('SettingsResolveDeletionEvent', () {
    for (final preview in const [
      DeleteAccountPreview(deletionCase: DeletionCase.soloOrGrantee),
      DeleteAccountPreview(deletionCase: DeletionCase.ownerNoOthers),
      DeleteAccountPreview(
        deletionCase: DeletionCase.ownerWithOthers,
        affectedNames: ['Vitor'],
      ),
    ]) {
      blocTest<SettingsBloc, SettingsState>(
        'emits resolving then ready for ${preview.deletionCase}',
        build: () {
          when(() => accountRepository.resolveDeletionCase())
              .thenAnswer((_) async => preview);
          return buildBloc();
        },
        act: (bloc) => bloc.add(const SettingsResolveDeletionEvent()),
        expect: () => [
          isA<SettingsState>().having(
            (s) => s.deletionStatus,
            'deletionStatus',
            SettingsDeletionStatus.resolving,
          ),
          isA<SettingsState>()
              .having(
                (s) => s.deletionStatus,
                'deletionStatus',
                SettingsDeletionStatus.ready,
              )
              .having((s) => s.deletionPreview, 'deletionPreview', preview),
        ],
      );
    }

    blocTest<SettingsBloc, SettingsState>(
      'emits resolving then failure when resolve throws',
      build: () {
        when(() => accountRepository.resolveDeletionCase())
            .thenThrow(const AppException('offline'));
        return buildBloc();
      },
      act: (bloc) => bloc.add(const SettingsResolveDeletionEvent()),
      expect: () => [
        isA<SettingsState>().having(
          (s) => s.deletionStatus,
          'deletionStatus',
          SettingsDeletionStatus.resolving,
        ),
        isA<SettingsState>().having(
          (s) => s.deletionStatus,
          'deletionStatus',
          SettingsDeletionStatus.failure,
        ),
      ],
    );
  });

  group('SettingsDeleteAccountEvent', () {
    blocTest<SettingsBloc, SettingsState>(
      'emits deleting then deleted on success',
      build: () {
        when(() => accountRepository.deleteAccount())
            .thenAnswer((_) async {});
        return buildBloc();
      },
      act: (bloc) => bloc.add(const SettingsDeleteAccountEvent()),
      expect: () => [
        isA<SettingsState>().having(
          (s) => s.deletionStatus,
          'deletionStatus',
          SettingsDeletionStatus.deleting,
        ),
        isA<SettingsState>().having(
          (s) => s.deletionStatus,
          'deletionStatus',
          SettingsDeletionStatus.deleted,
        ),
      ],
    );

    blocTest<SettingsBloc, SettingsState>(
      'emits deleting then failure on error',
      build: () {
        when(() => accountRepository.deleteAccount())
            .thenThrow(const AppException('falha'));
        return buildBloc();
      },
      act: (bloc) => bloc.add(const SettingsDeleteAccountEvent()),
      expect: () => [
        isA<SettingsState>().having(
          (s) => s.deletionStatus,
          'deletionStatus',
          SettingsDeletionStatus.deleting,
        ),
        isA<SettingsState>()
            .having(
              (s) => s.deletionStatus,
              'deletionStatus',
              SettingsDeletionStatus.failure,
            )
            .having((s) => s.deletionError, 'deletionError', 'falha'),
      ],
    );
  });
}
