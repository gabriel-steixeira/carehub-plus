/*
 * CareHub Plus — Widget Compartilhado / Card de Identidade
 *
 * Cartão de apresentação usado no topo de telas que têm um "dono" visual
 * (assistente, perfil, serviço): avatar redondo, nome, função e uma frase
 * curta. Reaproveita o AppCard na variante `filled` para herdar o fundo lilás
 * e os cantos arredondados do design system, sem recriar decoração na tela.
 *
 * Author: Vitoria Lana
 * Created on: 21/08/2026
 * Version: 1.0.0
 * Squad: CareHub Plus
 */

import 'dart:convert';

import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_responsive.dart';
import '../../core/theme/app_shadows.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import 'app_tinted_card.dart';

/// Cartão de identidade com avatar, nome, função e frase de apoio.
///
/// ```dart
/// AppIdentityCard(
///   imageAsset: 'assets/images/cora_avatar.png',
///   title: 'CORA',
///   role: 'Assistente digital',
///   subtitle: 'Simplificando o cuidado, todos os dias',
/// )
/// ```
class AppIdentityCard extends StatelessWidget {
  const AppIdentityCard({
    super.key,
    this.imageAsset,
    required this.title,
    this.role,
    this.subtitle,
    this.tint = AppColors.primaryLight,
    this.margin,
    this.imageUrl,
    this.showAvatar = true,
  });

  /// Caminho do avatar dentro de `assets/`. Ignorado quando [imageUrl] é
  /// informado. Quando nulo e sem [imageUrl], mostra o ícone de fallback —
  /// evita usar imagens genéricas (como o logo) no lugar de um avatar.
  final String? imageAsset;

  /// Foto remota do avatar (ex.: rede de apoio). Quando presente, tem
  /// prioridade sobre [imageAsset] — permite reaproveitar este cartão em
  /// telas cujo avatar vem da rede, e não de um asset local.
  final String? imageUrl;

  /// Nome exibido em destaque.
  final String title;

  /// Função ou papel, exibido ao lado do nome depois de um separador.
  final String? role;

  /// Frase curta de apoio, exibida abaixo do nome.
  final String? subtitle;

  /// Cor base do painel. Só a cor muda de tela para tela.
  final Color tint;

  /// Espaçamento externo do cartão.
  final EdgeInsetsGeometry? margin;

  /// Define se o avatar deve ser exibido no cartão.
  ///
  /// Mantém o avatar visível por padrão para preservar o comportamento das
  /// telas existentes.
  final bool showAvatar;

  @override
  Widget build(BuildContext context) {
    return AppTintedCard(
      tint: tint,
      margin: margin,
      child: Row(
        children: [
          if (showAvatar) ...[
            _IdentityAvatar(imageAsset: imageAsset, imageUrl: imageUrl),
            const SizedBox(width: AppSpacing.md),
          ],
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildTitleRow(context),
                if (subtitle != null) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    subtitle!,
                    style: AppTypography.bodyMedium.copyWith(
                      color: AppColors.textSecondary,
                      fontSize: context.scaleFont(14),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTitleRow(BuildContext context) {
    return Row(
      children: [
        Text(
          title,
          style: AppTypography.averiaTitleLarge.copyWith(
            color: AppColors.textPrimary,
            fontSize: context.scaleFont(18),
            fontWeight: FontWeight.bold,
          ),
        ),
        if (role != null) ...[
          const SizedBox(width: AppSpacing.sm),
          Container(
            width: AppSpacing.xs,
            height: AppSpacing.xs,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.textHint,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              role!,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.bodyLarge.copyWith(
                color: AppColors.textSecondary,
                fontSize: context.scaleFont(16),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

/// Avatar redondo com anel branco, usado apenas pelo [AppIdentityCard].
class _IdentityAvatar extends StatelessWidget {
  const _IdentityAvatar({this.imageAsset, this.imageUrl});

  final String? imageAsset;
  final String? imageUrl;

  Widget _buildImage(BuildContext context, double size) {
    final value = imageUrl;
    if (value != null && value.contains('base64,')) {
      final encoded = value.substring(value.indexOf('base64,') + 7);
      try {
        return Image.memory(
          base64Decode(encoded),
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => _fallback,
        );
      } on FormatException {
        return _fallback;
      }
    }

    if (value != null && value.isNotEmpty) {
      return Image.network(
        value,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => _fallback,
      );
    }

    // Sem foto remota: usa o asset apenas se houver um; caso contrário, mostra
    // o ícone de avatar em vez de uma imagem genérica.
    final asset = imageAsset;
    if (asset == null || asset.isEmpty) return _fallback;

    return Image.asset(
      asset,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) => _fallback,
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = context.scaleSpacing(AppSpacing.xxl);

    return Container(
      width: size,
      height: size,
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.background,
        boxShadow: AppShadows.card,
      ),
      child: ClipOval(child: _buildImage(context, size)),
    );
  }

  Widget get _fallback => const ColoredBox(
    color: AppColors.surfaceVariant,
    child: Icon(
      Icons.person_outline,
      color: AppColors.primary,
      size: AppSpacing.lg,
    ),
  );
}
