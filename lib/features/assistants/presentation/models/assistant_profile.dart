/*
 * CareHub Plus — Apresentação / Identidade de Assistente
 *
 * Reúne tudo o que muda de um assistente para outro na interface: nome,
 * avatar, cor do painel e textos da tela. Fica na camada de apresentação (e
 * não em `domain/entities/`) porque carrega decisões visuais — uma `Color` e
 * um caminho de asset — e entidades de domínio são Dart puro.
 *
 * Author: Vitoria Lana
 * Created on: 21/08/2026
 * Version: 1.0.0
 * Squad: CareHub Plus
 */

import 'package:flutter/painting.dart';

import '../../../../core/theme/app_colors.dart';

/// Identidade visual e textual de um assistente na tela de chat.
///
/// Trocar de agente é trocar este objeto e o repositório correspondente —
/// nenhuma linha da tela precisa mudar.
///
/// ```dart
/// const AssistantProfile(
///   name: 'CORA',
///   role: 'Assistente digital',
///   subtitle: 'Simplificando o cuidado, todos os dias',
///   avatarAsset: 'assets/images/cora_avatar.png',
///   inputHint: 'Pergunte algo para a Cora...',
///   thinkingLabel: 'Cora está analisando...',
///   errorMessage: 'Erro ao conversar com a Cora.',
/// );
/// ```
class AssistantProfile {
  const AssistantProfile({
    required this.name,
    required this.role,
    required this.subtitle,
    required this.avatarAsset,
    required this.inputHint,
    required this.thinkingLabel,
    required this.errorMessage,
    this.tint = AppColors.tintPink,
    this.accentColor,
  });

  /// Nome em destaque no cartão de identidade. Ex.: `CORA`.
  final String name;

  /// Função exibida ao lado do nome. Ex.: `Assistente digital`.
  final String role;

  /// Frase curta de apoio, abaixo do nome.
  final String subtitle;

  /// Caminho do avatar dentro de `assets/`.
  final String avatarAsset;

  /// Texto de dica do campo de mensagem.
  final String inputHint;

  /// Texto exibido enquanto o assistente prepara a resposta.
  final String thinkingLabel;

  /// Mensagem de erro genérica da tela, usada quando o repositório não
  /// informa um motivo específico.
  final String errorMessage;

  /// Cor base do painel de identidade, sempre um token de [AppColors].
  final Color tint;

  /// Cor opcional dos elementos interativos da conversa.
  ///
  /// Quando ausente, o chat mantém a identidade roxa padrão.
  final Color? accentColor;
}
