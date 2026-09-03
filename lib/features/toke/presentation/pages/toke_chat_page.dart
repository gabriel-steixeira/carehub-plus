/*
 * CareHub Plus — Apresentação / Tela do Toke
 *
 * Composição do concierge Toke sobre a tela genérica de assistentes: declara
 * sua identidade visual azul e conecta o cérebro de suporte correspondente.
 *
 * Author: Vitoria Lana
 * Created on: 25/08/2026
 * Version: 1.0.0
 * Squad: CareHub Plus
 */

import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../assistants/data/repositories/toke_assistant_repository.dart';
import '../../../assistants/presentation/models/assistant_profile.dart';
import '../../../assistants/presentation/pages/assistant_chat_page.dart';

/// Conversa com o Toke, concierge digital do CareHub+.
class TokeChatPage extends StatelessWidget {
  const TokeChatPage({super.key});

  static const AssistantProfile _profile = AssistantProfile(
    name: 'TOKE',
    role: 'Concierge Digital',
    subtitle: 'Cuidado personalizado para você',
    avatarAsset: 'assets/images/Toke_avatar.png',
    tint: AppColors.progressBlue,
    accentColor: AppColors.info,
    inputHint: 'Pergunte algo para o Toke...',
    thinkingLabel: 'Toke está preparando uma resposta...',
    errorMessage: 'Erro ao conversar com o Toke.',
  );

  @override
  Widget build(BuildContext context) {
    return const AssistantChatPage(
      profile: _profile,
      repositoryBuilder: TokeAssistantRepository.new,
    );
  }
}
