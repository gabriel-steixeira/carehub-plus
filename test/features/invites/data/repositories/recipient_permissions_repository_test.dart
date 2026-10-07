/*
 * CareHub Plus — Testes / Permissões da conta num perfil
 *
 * Author: Vitoria Lana
 * Created on: 06/10/2026
 * Version: 1.0.0
 * Squad: CareHub Plus
 */

import 'package:carehub_plus/features/invites/data/repositories/recipient_permissions_repository.dart';
import 'package:carehub_plus/features/invites/domain/entities/recipient_permissions_entity.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  RecipientPermissionsEntity check(Map<String, dynamic>? data) =>
      RecipientPermissionsRepository.fromRecipientData(data, 'bia');

  test('dona pode tudo', () {
    expect(check({'caregiverId': 'bia'}), RecipientPermissionsEntity.full);
  });

  test('Acesso Total pode tudo', () {
    expect(
      check({
        'caregiverId': 'alice',
        'access': {
          'bia': {'level': 'full', 'permissions': []},
        },
      }),
      RecipientPermissionsEntity.full,
    );
  });

  test('Apenas Visualização não edita tarefas nem usa o chat', () {
    expect(
      check({
        'caregiverId': 'alice',
        'access': {
          'bia': {'level': 'readonly', 'permissions': []},
        },
      }),
      const RecipientPermissionsEntity(canEditTasks: false, canUseChat: false),
    );
  });

  test('Parcial segue as áreas marcadas', () {
    expect(
      check({
        'caregiverId': 'alice',
        'access': {
          'bia': {
            'level': 'partial',
            'permissions': ['task', 'cora'],
          },
        },
      }),
      const RecipientPermissionsEntity(canEditTasks: true, canUseChat: false),
    );
  });

  test('sem dados de acesso libera (as regras continuam barrando)', () {
    expect(check(null), RecipientPermissionsEntity.full);
    expect(check({'caregiverId': 'alice'}), RecipientPermissionsEntity.full);
  });
}
