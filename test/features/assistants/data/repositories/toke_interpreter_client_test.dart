/*
 * CareHub Plus — Testes / Triagem do Toke pelo backend
 *
 * Author: Vitoria Lana
 * Created on: 06/10/2026
 * Version: 1.0.0
 * Squad: CareHub Plus
 */

import 'package:carehub_plus/features/assistants/data/repositories/toke_interpreter_client.dart';
import 'package:carehub_plus/features/assistants/domain/entities/assistant_message_entity.dart';
import 'package:carehub_plus/features/assistants/domain/entities/support_intent_entity.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/fake_callable_client.dart';

void main() {
  final now = DateTime(2026, 10, 6);

  test('sends history without the current message and reads the intent', () async {
    final client = FakeCallableClient(
      responses: {
        'tokeInterpret': {
          'kind': 'contract_plan',
          'reply': 'Confirma?',
          'planId': 'family',
          'billingCycle': 'annual',
          'paymentType': null,
          'summary': null,
        },
      },
    );
    final history = [
      AssistantMessage.fromAssistant(id: 'a', text: 'Olá!', timestamp: now),
      AssistantMessage.fromUser(id: 'b', text: 'Quanto custa?', timestamp: now),
      AssistantMessage.fromAssistant(id: 'c', text: 'R\$ 50.', timestamp: now),
      AssistantMessage.fromUser(id: 'd', text: 'Quero o anual', timestamp: now),
    ];

    final result = await TokeInterpreterClient(client: client).interpret(
      text: 'Quero o anual',
      history: history,
      context: const {'contextAvailable': true, 'userName': 'Alice'},
      planIds: const ['family'],
    );

    final sent = client.calls.single.data;
    expect(client.calls.single.name, 'tokeInterpret');
    expect(sent['history'], [
      {'role': 'user', 'text': 'Quanto custa?'},
      {'role': 'model', 'text': 'R\$ 50.'},
    ]);
    expect(sent['planIds'], ['family']);
    expect(result.kind, SupportIntentKind.contractPlan);
    expect(result.planId, 'family');
    expect(result.billingCycle, 'annual');
  });

  test('unknown kind becomes conversation with a safe reply', () async {
    final client = FakeCallableClient(
      responses: {
        'tokeInterpret': {'kind': 'hack', 'reply': ''},
      },
    );
    final result = await TokeInterpreterClient(client: client).interpret(
      text: 'Oi',
      history: const [],
      context: const {},
      planIds: const [],
    );
    expect(result.kind, SupportIntentKind.conversation);
    expect(result.reply, 'Desculpe, não consegui entender. Pode reformular?');
  });
}
