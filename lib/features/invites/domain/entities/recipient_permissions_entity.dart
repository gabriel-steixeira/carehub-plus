/*
 * CareHub Plus — Domínio / O que a conta pode fazer num perfil
 *
 * Usado pelas telas para esconder ações que o nível de acesso não permite.
 * É só conforto de interface: quem garante de verdade são as regras do
 * Firestore, que recusam a gravação de qualquer jeito.
 *
 * Author: Vitoria Lana
 * Created on: 06/10/2026
 * Version: 1.0.0
 * Squad: CareHub Plus
 */

import 'package:equatable/equatable.dart';

class RecipientPermissionsEntity extends Equatable {
  const RecipientPermissionsEntity({
    required this.canEditTasks,
    required this.canUseChat,
  });

  /// Dona do perfil ou acesso total.
  static const full = RecipientPermissionsEntity(
    canEditTasks: true,
    canUseChat: true,
  );

  /// Criar, concluir e excluir tarefas.
  final bool canEditTasks;

  /// Criar assuntos e enviar mensagens no chat.
  final bool canUseChat;

  @override
  List<Object?> get props => [canEditTasks, canUseChat];
}
