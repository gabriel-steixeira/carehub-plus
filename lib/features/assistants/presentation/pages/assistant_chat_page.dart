/*
 * CareHub Plus — Apresentação / Página de Chat de Assistente
 *
 * Ponto de montagem da conversa: recebe a identidade do agente e o cérebro
 * dele, cria o BLoC e entrega a tela. É a única peça que precisa ser escrita
 * para colocar um assistente novo no ar.
 *
 * Author: Vitoria Lana
 * Created on: 21/08/2026
 * Version: 1.0.0
 * Squad: CareHub Plus
 */

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/repositories/caregiver_avatar_repository.dart';
import '../../domain/repositories/assistant_repository.dart';
import '../bloc/assistant_chat_bloc.dart';
import '../models/assistant_profile.dart';
import '../widgets/assistant_chat_view.dart';

/// Tela de conversa com um assistente.
///
/// ```dart
/// AssistantChatPage(
///   profile: coraProfile,
///   repositoryBuilder: CoraAssistantRepository.new,
///   bottomNavIndex: 2,
/// )
/// ```
class AssistantChatPage extends StatelessWidget {
  const AssistantChatPage({
    super.key,
    required this.profile,
    required this.repositoryBuilder,
    this.bottomNavIndex,
    this.caregiverRepositoryBuilder = CaregiverAvatarRepository.new,
  });

  /// Identidade visual e textual do agente.
  final AssistantProfile profile;

  /// Cria o cérebro do agente.
  ///
  /// Recebe uma fábrica, e não uma instância pronta, para que o repositório
  /// nasça uma única vez junto do BLoC — e não a cada reconstrução da página.
  final AssistantRepository Function() repositoryBuilder;

  /// Item destacado na barra inferior, quando o agente tem um.
  final int? bottomNavIndex;

  /// Cria o acesso à foto do cuidador logado.
  ///
  /// Tem padrão porque é igual para todos os agentes; existe como parâmetro
  /// para que testes possam trocar por um dublê sem tocar no Firebase.
  final CaregiverAvatarRepository Function() caregiverRepositoryBuilder;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => AssistantChatBloc(
        repository: repositoryBuilder(),
        caregiverRepository: caregiverRepositoryBuilder(),
      )..add(const AssistantChatLoadEvent()),
      child: AssistantChatView(
        profile: profile,
        bottomNavIndex: bottomNavIndex,
      ),
    );
  }
}
