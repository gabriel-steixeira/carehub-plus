/*
 * CareHub Plus — SOS / Argumentos da rota
 *
 * Dados opcionais que a rota `/sos` aceita quando o pedido de ajuda nasce em
 * outra tela (por exemplo, ao arrastar um card na tela de Tarefas). Existe para
 * a navegação não depender de um `Map` solto no `extra` do GoRouter: aqui os
 * campos têm nome e tipo.
 *
 * Author: Vitoria Lana
 * Created on: 23/08/2026
 * Version: 1.0.0
 * Squad: CareHub Plus
 */

import 'package:equatable/equatable.dart';

/// Pré-seleção opcional recebida pela tela de SOS.
class SosRequestArgs extends Equatable {
  const SosRequestArgs({this.careRecipientId, this.taskId});

  /// Perfil cuidado que já deve vir selecionado.
  final String? careRecipientId;

  /// Tarefa que já deve vir selecionada.
  final String? taskId;

  @override
  List<Object?> get props => [careRecipientId, taskId];
}
