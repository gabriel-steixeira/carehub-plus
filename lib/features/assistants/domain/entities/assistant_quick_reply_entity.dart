/*
 * CareHub Plus — Domínio / Sugestão de Resposta Rápida
 *
 * Representa um atalho sugerido pelo assistente ("Resumo da Vovó Lúcia").
 * Separa o texto que a cuidadora lê (`label`) da instrução que o assistente
 * recebe (`intent`): assim é possível reescrever o rótulo sem quebrar a
 * resposta do agente.
 *
 * Author: Vitoria Lana
 * Created on: 21/08/2026
 * Version: 1.0.0
 * Squad: CareHub Plus
 */

import 'package:equatable/equatable.dart';

/// Atalho de conversa sugerido por um assistente.
///
/// ```dart
/// const AssistantQuickReply(
///   label: 'Resumo da Vovó Lúcia',
///   intent: 'cora.summary.care_recipient',
/// )
/// ```
class AssistantQuickReply extends Equatable {
  const AssistantQuickReply({required this.label, required this.intent});

  /// Texto exibido no chip. Pode mudar livremente.
  final String label;

  /// Identificador estável da intenção enviada ao assistente.
  ///
  /// É este valor — não o [label] — que o repositório interpreta.
  final String intent;

  @override
  List<Object?> get props => [label, intent];
}
