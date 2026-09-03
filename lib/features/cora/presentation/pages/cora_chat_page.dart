/*
 * CareHub Plus — Apresentação / Tela da Cora
 *
 * Composição da assistente Cora sobre a tela genérica de assistentes: declara
 * a identidade dela e aponta para o cérebro correspondente. Todo o esqueleto
 * da conversa vive em `lib/features/assistants/`, compartilhado com os demais
 * agentes.
 *
 * Author: Vitoria Lana
 * Created on: 21/08/2026
 * Version: 2.0.0
 * Squad: CareHub Plus
 */

import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../assistants/data/repositories/cora_assistant_repository.dart';
import '../../../assistants/presentation/models/assistant_profile.dart';
import '../../../assistants/presentation/pages/assistant_chat_page.dart';

/// Conversa com a Cora, a assistente digital do CareHub+.
class CoraChatPage extends StatelessWidget {
  const CoraChatPage({super.key});

  /// Índice da Cora na barra de navegação inferior.
  static const int _bottomNavIndex = 2;

  static const AssistantProfile _profile = AssistantProfile(
    name: 'CORA',
    role: 'Assistente digital',
    subtitle: 'Simplificando o cuidado, todos os dias',
    avatarAsset: 'assets/images/cora_avatar.png',
    tint: AppColors.tintPink,
    inputHint: 'Pergunte algo para a Cora...',
    thinkingLabel: 'Cora está analisando...',
    errorMessage: 'Erro ao conversar com a Cora.',
  );

  @override
  Widget build(BuildContext context) {
    return const AssistantChatPage(
      profile: _profile,
      repositoryBuilder: CoraAssistantRepository.new,
      bottomNavIndex: _bottomNavIndex,
    );
  }
}
