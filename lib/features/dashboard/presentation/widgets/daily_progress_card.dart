/*
 * CareHub Plus — Dashboard / Daily Progress Card
 *
 * Cartão de boas-vindas e progresso do dia. Exibe saudação contextual com o
 * primeiro nome da cuidadora, data de hoje e barra de progresso das tarefas.
 * Quando todas as tarefas do dia estão concluídas, exibe mensagem positiva
 * no lugar da barra.
 *
 * Author: Vitoria Lana
 * Created on: 26/08/2026
 * Version: 1.0.0
 * Squad: CareHub Plus
 */

import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';

/// Cartão de saudação + progresso diário de tarefas.
///
/// Recebe dados já calculados pelo BLoC — não acessa repositório nem BLoC
/// diretamente, seguindo a regra de widgets sem lógica de negócio.
class DailyProgressCard extends StatelessWidget {
  const DailyProgressCard({
    super.key,
    required this.caregiverName,
    required this.completedToday,
    required this.totalToday,
    required this.progress,
    required this.allDone,
    this.onTap,
  });

  /// Nome completo da cuidadora — exibe apenas o primeiro nome.
  final String caregiverName;
  final int completedToday;
  final int totalToday;

  /// Progresso já calculado como fração [0.0, 1.0].
  final double progress;

  /// Quando verdadeiro, exibe mensagem de parabenização no lugar da barra.
  final bool allDone;

  /// Navega para a tela de tarefas ao tocar no cartão.
  final VoidCallback? onTap;

  String get _firstName {
    final parts = caregiverName.trim().split(' ');
    return parts.isNotEmpty ? parts.first : caregiverName;
  }

  String get _greeting {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Bom dia';
    if (hour < 18) return 'Boa tarde';
    return 'Boa noite';
  }

  String get _greetingEmoji {
    final hour = DateTime.now().hour;
    if (hour < 12) return '☀️';
    if (hour < 18) return '🌤️';
    return '🌙';
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.primary, AppColors.primaryDark],
          ),
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.35),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Saudação
            Row(
              children: [
                Text(
                  '$_greetingEmoji  $_greeting, $_firstName!',
                  style: AppTypography.titleMedium.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),

            // Subtítulo
            Text(
              _buildSubtitle(),
              style: AppTypography.bodyMedium.copyWith(
                color: Colors.white.withValues(alpha: 0.85),
              ),
            ),

            const SizedBox(height: AppSpacing.md),

            if (allDone) ...[
              // Estado positivo — todas as tarefas concluídas
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.sm,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  borderRadius:
                      BorderRadius.circular(AppSpacing.radiusMd),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.check_circle_outline_rounded,
                      color: Colors.white,
                      size: 18,
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Text(
                      'Todas as tarefas de hoje concluídas!',
                      style: AppTypography.labelSmall.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ] else ...[
              // Barra de progresso
              Row(
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius:
                          BorderRadius.circular(AppSpacing.radiusFull),
                      child: LinearProgressIndicator(
                        value: progress,
                        minHeight: 8,
                        backgroundColor:
                            Colors.white.withValues(alpha: 0.25),
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          Colors.white,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    '$completedToday/$totalToday',
                    style: AppTypography.labelSmall.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                totalToday == 0
                    ? 'Nenhuma tarefa agendada para hoje'
                    : '$completedToday de $totalToday tarefas concluídas hoje',
                style: AppTypography.bodyMedium.copyWith(
                  color: Colors.white.withValues(alpha: 0.75),
                  fontSize: 12,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _buildSubtitle() {
    final now = DateTime.now();
    final weekdays = [
      'segunda-feira',
      'terça-feira',
      'quarta-feira',
      'quinta-feira',
      'sexta-feira',
      'sábado',
      'domingo',
    ];
    final months = [
      'jan', 'fev', 'mar', 'abr', 'mai', 'jun',
      'jul', 'ago', 'set', 'out', 'nov', 'dez',
    ];
    final weekday = weekdays[now.weekday - 1];
    final month = months[now.month - 1];
    return '${now.day} de $month — $weekday';
  }
}
