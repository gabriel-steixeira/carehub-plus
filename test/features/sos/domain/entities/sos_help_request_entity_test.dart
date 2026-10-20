/*
 * CareHub Plus — Teste / Entidade de pedido de ajuda (SOS)
 *
 * Cobre a regra de validade do pedido: além do caso clássico (tarefa + membro
 * marcado), o pedido passa a ser válido quando o dono do perfil é o
 * destinatário especial (`notifyOwner`), mesmo sem membros na lista. Dart puro,
 * sem Firebase.
 *
 * Author: Vitoria Lana
 * Created on: 19/10/2026
 * Version: 1.0.0
 * Squad: CareHub Plus
 */

import 'package:carehub_plus/features/sos/domain/entities/sos_help_request_entity.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SosHelpRequestEntity.isValid', () {
    test('is valid with a task and at least one member', () {
      const request = SosHelpRequestEntity(
        careRecipientId: 'care_1',
        taskId: 'task_1',
        taskTitle: 'Dar o remédio',
        notifiedMemberIds: ['member_1'],
      );

      expect(request.isValid, isTrue);
    });

    test('is valid with no members when notifyOwner is true', () {
      const request = SosHelpRequestEntity(
        careRecipientId: 'care_1',
        taskId: 'task_1',
        taskTitle: 'Comprar ração',
        notifiedMemberIds: [],
        notifyOwner: true,
      );

      expect(request.isValid, isTrue);
    });

    test('is invalid with no members and notifyOwner false (default)', () {
      const request = SosHelpRequestEntity(
        careRecipientId: 'care_1',
        taskId: 'task_1',
        taskTitle: 'Comprar ração',
        notifiedMemberIds: [],
      );

      expect(request.isValid, isFalse);
    });

    test('is invalid without a task even when notifyOwner is true', () {
      const request = SosHelpRequestEntity(
        careRecipientId: 'care_1',
        taskId: '',
        taskTitle: '',
        notifiedMemberIds: [],
        notifyOwner: true,
      );

      expect(request.isValid, isFalse);
    });
  });
}
