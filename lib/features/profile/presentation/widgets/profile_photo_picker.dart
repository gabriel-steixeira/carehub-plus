/*
 * CareHub Plus — Perfil / Avatar com Troca de Foto
 *
 * Avatar redondo do cuidador com o botão de câmera sobreposto, no topo da tela
 * de edição. Suporta exibição de foto via URL (Google Sign-In) ou base64
 * (salva no Firestore). Quando não há foto mostra o avatar genérico.
 *
 * Author: Vitoria Lana
 * Created on: 25/08/2026
 * Version: 1.0.0
 * Squad: CareHub Plus
 */

import 'dart:convert';

import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_responsive.dart';
import '../../../../core/theme/app_shadows.dart';
import '../../../../core/theme/app_spacing.dart';

/// Avatar do cuidador com ação de trocar a foto.
class ProfilePhotoPicker extends StatelessWidget {
  const ProfilePhotoPicker({
    super.key,
    required this.photoUrl,
    this.photoBase64,
    required this.onTap,
  });

  /// Foto atual via URL. `null` ou vazia mostra o avatar genérico.
  final String? photoUrl;

  /// Foto atual em base64 (data URI). Tem prioridade sobre [photoUrl].
  final String? photoBase64;

  /// Ação do botão de câmera.
  final VoidCallback onTap;

  /// 96px — dobro de `xxl`, mantendo o grid de 4px.
  static const double _baseAvatarSize = AppSpacing.xxl * 2;

  /// 40px — grande o suficiente para o toque, pequeno o suficiente para não
  /// competir com o avatar.
  static const double _baseButtonSize = AppSpacing.xl + AppSpacing.sm;

  /// Verifica se há qualquer foto disponível.
  bool get _hasPhoto =>
      photoBase64 != null ||
      (photoUrl != null && photoUrl!.isNotEmpty);

  @override
  Widget build(BuildContext context) {
    final avatarSize = context.scaleSpacing(_baseAvatarSize);
    final buttonSize = context.scaleSpacing(_baseButtonSize);

    return SizedBox(
      width: avatarSize,
      height: avatarSize,
      child: Stack(
        children: [
          Container(
            width: avatarSize,
            height: avatarSize,
            padding: const EdgeInsets.all(AppSpacing.xs),
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.background,
              boxShadow: AppShadows.card,
            ),
            child: ClipOval(child: _buildImage()),
          ),
          Positioned(
            right: 0,
            bottom: 0,
            child: Semantics(
              button: true,
              label: 'Trocar foto do perfil',
              child: Material(
                color: AppColors.primary,
                shape: const CircleBorder(),
                child: InkWell(
                  onTap: onTap,
                  customBorder: const CircleBorder(),
                  child: SizedBox(
                    width: buttonSize,
                    height: buttonSize,
                    child: const Icon(
                      Icons.photo_camera_outlined,
                      size: AppSpacing.md,
                      color: AppColors.textInverse,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImage() {
    if (photoBase64 != null) {
      final raw = photoBase64!;
      final base64Str = raw.contains(',') ? raw.split(',').last : raw;
      return Image.memory(
        base64Decode(base64Str),
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        errorBuilder: (_, __, ___) => const _AvatarFallback(),
      );
    }
    if (_hasPhoto) {
      return Image.network(
        photoUrl!,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        errorBuilder: (_, __, ___) => const _AvatarFallback(),
      );
    }
    return const _AvatarFallback();
  }
}

/// Avatar genérico exibido quando não há foto (ou ela falha ao carregar).
class _AvatarFallback extends StatelessWidget {
  const _AvatarFallback();

  @override
  Widget build(BuildContext context) {
    return const ColoredBox(
      color: AppColors.surfaceVariant,
      child: Icon(
        Icons.person_outline,
        color: AppColors.primary,
        size: AppSpacing.xl,
      ),
    );
  }
}
