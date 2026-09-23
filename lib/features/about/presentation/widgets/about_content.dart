/*
 * CareHub Plus — Sobre / Conteúdo Institucional
 *
 * Renderiza o conteúdo institucional recebido pelo BLoC com os componentes e
 * tokens visuais compartilhados do aplicativo.
 *
 * Author: Vitoria Lana
 * Created on: 27/08/2026
 * Version: 1.0.0
 * Squad: CareHub Plus
 */

import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_responsive.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/widgets/app_responsive_body.dart';
import '../../domain/entities/about_content_entity.dart';

class AboutContent extends StatelessWidget {
  const AboutContent({super.key, required this.content});

  final AboutContentEntity content;

  @override
  Widget build(BuildContext context) {
    return AppResponsiveBody(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            content.title,
            style: AppTypography.averiaHeadlineMedium.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            content.appName,
            style: AppTypography.titleMedium.copyWith(
              color: AppColors.primaryDark,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: context.sectionSpacing),
          AppCard(
            variant: AppCardVariant.elevated,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.favorite_outline_rounded,
                  color: AppColors.primary,
                  size: AppSpacing.xl,
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  content.description,
                  style: AppTypography.bodyLarge.copyWith(
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          if (content.version.isNotEmpty) ...[
            SizedBox(height: context.sectionSpacing),
            Center(
              child: Text(
                'Versão ${content.version}',
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
