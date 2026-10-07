/*
 * CareHub Plus — Testes / Permissão de tarefas por perfil
 *
 * Na visão "Todos os perfis", cada tarefa segue o acesso do próprio perfil;
 * o botão "Nova" segue o perfil em que a tarefa seria criada.
 *
 * Author: Vitoria Lana
 * Created on: 06/10/2026
 * Version: 1.0.0
 * Squad: CareHub Plus
 */

import 'package:carehub_plus/features/home/data/models/care_recipient_model.dart';
import 'package:carehub_plus/features/tasks/presentation/bloc/tasks_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('perfil só de visualização bloqueia; os outros seguem liberados', () {
    const state = TasksState(
      selectedProfileId: 'all',
      careRecipientId: 'proprio',
      readOnlyProfileIds: {'compartilhado'},
    );
    expect(state.canEditTasksOf('compartilhado'), isFalse);
    expect(state.canEditTasksOf('proprio'), isTrue);
    expect(state.canEditTasksOf(null), isTrue);
    expect(state.canEditTasks, isTrue, reason: '"Nova" cria no perfil próprio');
  });

  test('"Nova" segue o perfil selecionado', () {
    const state = TasksState(
      selectedProfileId: 'compartilhado',
      careRecipientId: 'compartilhado',
      readOnlyProfileIds: {'compartilhado'},
    );
    expect(state.canEditTasks, isFalse);
  });

  test('perfil compartilhado não vai para o Firestore como campo', () {
    const profile = CareRecipientModel(id: 'r1', name: 'Lúcia', isShared: true);
    expect(profile.toJson().containsKey('isShared'), isFalse);
    expect(
      CareRecipientModel.fromJson(profile.toJson()).isShared,
      isFalse,
      reason: 'só o repositório marca o compartilhado',
    );
  });
}
