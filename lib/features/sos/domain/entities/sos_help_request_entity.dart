/*
 * CareHub Plus — Domínio SOS / Pedido de ajuda
 *
 * Representa um pedido de ajuda disparado pela cuidadora: uma tarefa concreta
 * do cuidado e as pessoas da rede de apoio que devem ser avisadas. É Dart puro
 * (sem Firebase e sem Flutter) para que a regra "um pedido só é válido com
 * tarefa e pelo menos um avisado" possa ser testada sozinha.
 *
 * Author: Vitoria Lana
 * Created on: 23/08/2026
 * Version: 1.0.0
 * Squad: CareHub Plus
 */

import 'package:equatable/equatable.dart';

/// Pedido de ajuda enviado à rede de apoio para uma tarefa específica.
class SosHelpRequestEntity extends Equatable {
  const SosHelpRequestEntity({
    required this.careRecipientId,
    required this.taskId,
    required this.taskTitle,
    required this.notifiedMemberIds,
  });

  /// Perfil cuidado ao qual a tarefa pertence.
  final String careRecipientId;

  /// Tarefa para a qual a ajuda foi pedida.
  final String taskId;

  /// Título da tarefa, guardado junto para o alerta ser legível sem consultar
  /// a tarefa de novo.
  final String taskTitle;

  /// Ids dos membros da rede de apoio avisados neste pedido.
  final List<String> notifiedMemberIds;

  /// Um pedido só faz sentido com uma tarefa e alguém para avisar.
  bool get isValid => taskId.isNotEmpty && notifiedMemberIds.isNotEmpty;

  @override
  List<Object?> get props => [
        careRecipientId,
        taskId,
        taskTitle,
        notifiedMemberIds,
      ];
}
