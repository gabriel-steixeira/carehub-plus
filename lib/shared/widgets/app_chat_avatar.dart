/*
 * CareHub Plus — Widget Compartilhado / Avatar de Chat
 *
 * Avatar redondo usado nas bolhas de qualquer conversa do app: chat com a
 * Cora (`assistants/`) e chat entre pessoas reais (`chat/`). Nasceu dentro de
 * `assistants/` como `AssistantAvatar`; foi promovido para aqui porque as
 * duas conversas compartilham a mesma necessidade — um avatar redondo com
 * imagem remota ou de asset e um ícone de fallback.
 *
 * Author: Vitoria Lana
 * Created on: 23/08/2026
 * Version: 1.0.0
 * Squad: CareHub Plus
 */

import 'dart:convert';

import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_responsive.dart';
import '../../core/theme/app_spacing.dart';

/// Avatar das mensagens de chat, com imagem de asset ou de rede.
///
/// ```dart
/// AppChatAvatar.asset(path: profile.avatarAsset); // ex.: a Cora
/// AppChatAvatar.photo(url: sender.avatarUrl);      // ex.: pessoa da rede
/// ```
class AppChatAvatar extends StatelessWidget {
  /// Avatar de uma imagem local (ex.: o mascote de um assistente). Mostra um
  /// anel em degradê e o ícone [fallbackIcon] quando a imagem falha.
  const AppChatAvatar.asset({
    super.key,
    required String this.assetPath,
    this.fallbackIcon = Icons.auto_awesome_outlined,
  }) : photoUrl = null;

  /// Avatar de uma foto remota (ex.: cuidador ou membro da rede de apoio).
  /// Sem [photoUrl], mostra direto o ícone [fallbackIcon].
  const AppChatAvatar.photo({
    super.key,
    this.photoUrl,
    this.fallbackIcon = Icons.person_rounded,
  }) : assetPath = null;

  /// Imagem local do avatar. `null` no construtor `.photo`.
  final String? assetPath;

  /// Foto remota do avatar. `null` no construtor `.asset`, ou quando a
  /// pessoa ainda não tem foto cadastrada.
  final String? photoUrl;

  /// Ícone mostrado quando não há imagem, ou quando ela falha ao carregar.
  final IconData fallbackIcon;

  /// Diâmetro base do avatar, antes da escala responsiva.
  static const double baseSize = AppSpacing.xl;

  /// Largura total ocupada pela coluna do avatar, incluindo o respiro até a
  /// bolha. As bolhas usam este valor para alinhar quem fala de cada lado.
  static double columnWidth(BuildContext context) =>
      context.scaleSpacing(baseSize) + AppSpacing.xs;

  @override
  Widget build(BuildContext context) {
    final size = context.scaleSpacing(baseSize);
    final asset = assetPath;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: asset == null ? AppColors.background : null,
        gradient: asset == null ? null : AppColors.primaryGradient,
      ),
      child: ClipOval(
        child: asset != null
            ? Image.asset(
                asset,
                width: size,
                height: size,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => _buildFallback(),
              )
            : _buildPhoto(size),
      ),
    );
  }

  /// Foto remota, com o ícone de fallback como rede de segurança.
  ///
  /// A foto vem da internet, então pode faltar (perfil sem foto) ou falhar
  /// (offline, URL inválida). Os dois casos caem no mesmo ícone.
  Widget _buildPhoto(double size) {
    final value = photoUrl;
    if (value == null || value.isEmpty) return _buildFallback();

    if (value.contains('base64,')) {
      final encoded = value.substring(value.indexOf('base64,') + 7);
      try {
        final bytes = base64Decode(encoded);
        return Image.memory(
          bytes,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => _buildFallback(),
        );
      } on FormatException {
        return _buildFallback();
      }
    }

    return Image.network(
      value,
      width: size,
      height: size,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) => _buildFallback(),
    );
  }

  Widget _buildFallback() {
    return ColoredBox(
      color: AppColors.surfaceVariant,
      child: Icon(fallbackIcon, color: AppColors.primary, size: AppSpacing.md),
    );
  }
}
