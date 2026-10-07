/*
 * CareHub Plus — Testes / BLoC "Ativar Cora no WhatsApp"
 *
 * Author: Vitoria Lana
 * Created on: 06/10/2026
 * Version: 1.0.0
 * Squad: CareHub Plus
 */

import 'package:bloc_test/bloc_test.dart';
import 'package:carehub_plus/core/errors/app_exception.dart';
import 'package:carehub_plus/features/invites/data/repositories/invites_repository.dart';
import 'package:carehub_plus/features/invites/domain/entities/whatsapp_link_entity.dart';
import 'package:carehub_plus/features/invites/presentation/bloc/whatsapp_link_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockInvitesRepository extends Mock implements InvitesRepository {}

void main() {
  late MockInvitesRepository repository;
  final link = WhatsAppLinkEntity(
    code: 'ABC234',
    expiresAt: DateTime(2026, 10, 6, 12, 10),
    link: 'https://wa.me/5511900001111?text=ENTRAR%20ABC234',
  );

  setUp(() => repository = MockInvitesRepository());

  blocTest<WhatsAppLinkBloc, WhatsAppLinkState>(
    'emits [loading, ready] with the link',
    build: () {
      when(() => repository.createSelfLinkCode()).thenAnswer((_) async => link);
      return WhatsAppLinkBloc(repository: repository);
    },
    act: (bloc) => bloc.add(const WhatsAppLinkRequestedEvent()),
    expect: () => [
      const WhatsAppLinkState(status: WhatsAppLinkStatus.loading),
      WhatsAppLinkState(status: WhatsAppLinkStatus.ready, link: link),
    ],
  );

  blocTest<WhatsAppLinkBloc, WhatsAppLinkState>(
    'emits [loading, failure] with the backend message',
    build: () {
      when(() => repository.createSelfLinkCode()).thenThrow(
        const AppException('O WhatsApp do CareHub ainda não foi configurado.'),
      );
      return WhatsAppLinkBloc(repository: repository);
    },
    act: (bloc) => bloc.add(const WhatsAppLinkRequestedEvent()),
    expect: () => [
      const WhatsAppLinkState(status: WhatsAppLinkStatus.loading),
      const WhatsAppLinkState(
        status: WhatsAppLinkStatus.failure,
        errorMessage: 'O WhatsApp do CareHub ainda não foi configurado.',
      ),
    ],
  );
}
