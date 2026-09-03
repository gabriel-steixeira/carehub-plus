/*
 * CareHub Plus — Tarefas / Atalho de SOS por arraste
 *
 * Revela a ação de SOS quando o card da tarefa é arrastado para a direita, no
 * mesmo gesto que apps de mensagem usam para responder. Não remove o card da
 * lista: ao soltar, ele volta ao lugar e a tela de SOS abre com essa tarefa já
 * escolhida.
 *
 * Author: Vitoria Lana
 * Created on: 23/08/2026
 * Version: 1.0.0
 * Squad: CareHub Plus
 */

import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';

/// Envolve um card de tarefa com o atalho de pedir ajuda (SOS).
class TaskSosSwipeAction extends StatelessWidget {
  const TaskSosSwipeAction({
    super.key,
    required this.taskId,
    required this.onRequestSos,
    required this.child,
  });

  /// Usado apenas para dar uma chave estável ao gesto de arraste.
  final String taskId;

  /// Disparado quando o arraste passa do limite.
  final VoidCallback onRequestSos;

  /// Card da tarefa.
  final Widget child;

  /// Fração da largura que precisa ser arrastada para acionar o SOS. Baixo o
  /// bastante para ser fácil, alto o bastante para não disparar sem intenção.
  static const double _threshold = 0.25;

  /// Compensa a margem inferior do card, para o fundo vermelho ter exatamente
  /// a altura da parte visível.
  static const EdgeInsets _backgroundInset = EdgeInsets.only(
    bottom: AppSpacing.md,
  );

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: ValueKey('task_sos_$taskId'),
      direction: DismissDirection.startToEnd,
      dismissThresholds: const {DismissDirection.startToEnd: _threshold},
      // Devolver `false` mantém o card na lista: o arraste é um atalho de
      // navegação, não uma exclusão.
      confirmDismiss: (_) async {
        onRequestSos();
        return false;
      },
      background: const _SosSwipeBackground(inset: _backgroundInset),
      child: child,
    );
  }
}

/// Painel vermelho revelado atrás do card durante o arraste.
class _SosSwipeBackground extends StatelessWidget {
  const _SosSwipeBackground({required this.inset});

  final EdgeInsets inset;

  static const double _width = 84.0;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: inset,
      child: Align(
        alignment: Alignment.centerLeft,
        child: Container(
          width: _width,
          height: double.infinity,
          decoration: BoxDecoration(
            color: AppColors.error,
            borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Symbols.shield_with_heart_rounded,
                size: 24,
                fill: 1,
                color: AppColors.textInverse,
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'SOS',
                style: AppTypography.labelSmall.copyWith(
                  color: AppColors.textInverse,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
