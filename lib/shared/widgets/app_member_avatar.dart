/*
 * CareHub Plus — Widget compartilhado / Avatar de membro
 *
 * Exibe a foto de uma pessoa da rede de apoio a partir de uma URL ou do data
 * URI base64 usado pelo fluxo atual do Firebase, mantendo um fallback visual
 * único para SOS, tarefas, chat e cadastro da rede.
 *
 * Author: Vitoria Lana
 * Created on: 27/08/2026
 * Version: 1.0.0
 * Squad: CareHub Plus
 */

import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

/// Avatar de um membro da rede de apoio com suporte a URL e base64.
class AppMemberAvatar extends StatelessWidget {
  const AppMemberAvatar({
    super.key,
    required this.photo,
    required this.diameter,
    this.fallbackIcon = Icons.person_outline_rounded,
  });

  /// URL HTTP ou data URI base64 persistido no Firebase.
  final String? photo;

  /// Diâmetro do avatar.
  final double diameter;

  /// Ícone mostrado quando a pessoa ainda não tem uma foto válida.
  final IconData fallbackIcon;

  Uint8List? _decodeBase64() {
    final value = photo;
    if (value == null || !value.contains('base64,')) return null;

    final encoded = value.substring(value.indexOf('base64,') + 7);
    try {
      return base64Decode(encoded);
    } on FormatException {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final bytes = _decodeBase64();
    final value = photo;

    return Container(
      width: diameter,
      height: diameter,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.surfaceVariant,
      ),
      clipBehavior: Clip.antiAlias,
      child: bytes != null
          ? Image.memory(
              bytes,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => _buildFallback(),
            )
          : value != null && value.isNotEmpty
          ? Image.network(
              value,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => _buildFallback(),
            )
          : _buildFallback(),
    );
  }

  Widget _buildFallback() {
    return Icon(fallbackIcon, size: diameter * 0.5, color: AppColors.primary);
  }
}
