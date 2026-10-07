/*
 * CareHub Plus — Testes / Conversa com a Cora pelo backend
 *
 * O app só envia a mensagem para `coraChat` e desenha a resposta. Estes
 * testes garantem o que é enviado (perfil selecionado, sessão, intenção e
 * categorias) e o tratamento de sem perfil, sem acesso e erro.
 *
 * Author: Vitoria Lana
 * Created on: 06/10/2026
 * Version: 1.0.0
 * Squad: CareHub Plus
 */

import 'package:carehub_plus/core/errors/app_exception.dart';
import 'package:carehub_plus/features/assistants/data/repositories/cora_assistant_repository.dart';
import 'package:carehub_plus/features/categories/data/models/care_category_model.dart';
import 'package:carehub_plus/features/categories/data/repositories/care_categories_repository.dart';
import 'package:carehub_plus/services/selected_profile_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../helpers/fake_callable_client.dart';

class MockSelectedProfileService extends Mock
    implements SelectedProfileService {}

class MockCareCategoriesRepository extends Mock
    implements CareCategoriesRepository {}

void main() {
  late MockSelectedProfileService profiles;
  late MockCareCategoriesRepository categories;

  setUp(() {
    profiles = MockSelectedProfileService();
    categories = MockCareCategoriesRepository();
    when(() => profiles.getSelectedProfileId()).thenReturn('r1');
    when(() => profiles.getSelectedProfileName()).thenReturn('Lúcia');
    when(() => categories.fetchCategories()).thenAnswer(
      (_) async => const [
        CareCategoryModel(
          id: 'food',
          label: 'Alimentação',
          iconKey: 'food',
          colorKey: 'blue',
          isDefault: true,
        ),
      ],
    );
  });

  CoraAssistantRepository build(FakeCallableClient client) =>
      CoraAssistantRepository(
        client: client,
        categoriesRepository: categories,
        profileServiceFactory: () async => profiles,
        sessionId: 'sessao-1',
      );

  test('greets with the selected profile name', () async {
    final messages = await build(FakeCallableClient()).fetchInitialMessages();
    expect(messages.single.text, contains('cuidados de Lúcia'));
    expect(messages.single.quickReplies, hasLength(4));
  });

  test('sends profile, session, intent and categories to coraChat', () async {
    final client = FakeCallableClient(
      responses: {
        'coraChat': {
          'text': 'Quer que eu registre "Dar ração"?',
          'quickReplies': [
            {'label': '✅ Confirmar tarefa', 'intent': 'cora.task.create.confirm'},
            {'label': 'Cancelar', 'intent': 'cora.task.create.cancel'},
          ],
        },
      },
    );
    final reply = await build(client).sendMessage(
      text: 'lembra da ração',
      history: const [],
      intent: 'cora.tasks',
    );

    expect(client.calls.single.name, 'coraChat');
    expect(client.calls.single.data, {
      'careRecipientId': 'r1',
      'sessionId': 'sessao-1',
      'text': 'lembra da ração',
      'intent': 'cora.tasks',
      'categories': {'food': 'Alimentação'},
    });
    expect(reply.text, 'Quer que eu registre "Dar ração"?');
    expect(reply.quickReplies.map((r) => r.intent), [
      'cora.task.create.confirm',
      'cora.task.create.cancel',
    ]);
  });

  test('omits intent when the message was typed', () async {
    final client = FakeCallableClient(responses: {'coraChat': {'text': 'Oi'}});
    await build(client).sendMessage(text: 'Oi', history: const []);
    expect(client.calls.single.data.containsKey('intent'), isFalse);
  });

  test('asks for a profile without calling the backend', () async {
    when(() => profiles.getSelectedProfileId()).thenReturn(null);
    final client = FakeCallableClient();
    final reply = await build(client).sendMessage(text: 'Oi', history: const []);
    expect(reply.text, startsWith('Selecione primeiro o perfil'));
    expect(client.calls, isEmpty);
  });

  test('explains when the account has no access to the profile', () async {
    final client = FakeCallableClient(
      responses: {
        'coraChat': const AppException(
          'Você não tem acesso a este perfil.',
          code: 'permission-denied',
        ),
      },
    );
    final reply = await build(client).sendMessage(text: 'Oi', history: const []);
    expect(reply.text, startsWith('Você não tem acesso a este perfil'));
  });

  test('shows the backend message on other errors', () async {
    final client = FakeCallableClient(
      responses: {
        'coraChat': const AppException(
          'Não consegui consultar a Cora agora. Tente novamente em instantes.',
          code: 'internal',
        ),
      },
    );
    final reply = await build(client).sendMessage(text: 'Oi', history: const []);
    expect(reply.text, contains('Não consegui consultar a Cora agora'));
    expect(reply.quickReplies, isNotEmpty);
  });

  test('works without categories when they cannot be loaded', () async {
    when(() => categories.fetchCategories()).thenThrow(Exception('prefs'));
    final client = FakeCallableClient(responses: {'coraChat': {'text': 'Oi'}});
    await build(client).sendMessage(text: 'Oi', history: const []);
    expect(client.calls.single.data.containsKey('categories'), isFalse);
  });
}
