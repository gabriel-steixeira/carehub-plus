/*
 * CareHub Plus — SOS / Botão de disparo
 *
 * Botão circular que dispara o pedido de ajuda. Pulsa devagar quando está
 * liberado, para puxar o olhar em um momento de tensão, e fica cinza e imóvel
 * quando ainda falta escolher a tarefa ou quem avisar — o próprio botão
 * comunica que a ação não está disponível.
 *
 * Author: Vitoria Lana
 * Created on: 23/08/2026
 * Version: 1.0.0
 * Squad: CareHub Plus
 */

import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_responsive.dart';
import '../../../../core/theme/app_shadows.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';

/// Botão de emergência da tela de SOS.
class SosButton extends StatefulWidget {
  const SosButton({super.key, required this.onPressed, this.caption});

  /// Ação de disparo. `null` desabilita o botão e interrompe a pulsação.
  final VoidCallback? onPressed;

  /// Texto de apoio abaixo do botão.
  final String? caption;

  @override
  State<SosButton> createState() => _SosButtonState();
}

class _SosButtonState extends State<SosButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;
  late final Animation<double> _pulse;

  /// Diâmetro do círculo. Não vem de `AppSpacing` porque não é espaçamento:
  /// é a dimensão própria do componente, vinda do Figma.
  static const double _diameterMobile = 128.0;
  static const double _diameterTablet = 144.0;
  static const double _nearRingStrokeWidth = 2.0;
  static const double _farRingStrokeWidth = 1.0;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _pulse = Tween<double>(begin: 1.0, end: 1.06).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _syncPulse();
  }

  @override
  void didUpdateWidget(SosButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncPulse();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  /// Anima só quando o botão pode ser acionado — animação em elemento inativo
  /// gasta bateria e engana o usuário.
  void _syncPulse() {
    final isEnabled = widget.onPressed != null;
    if (isEnabled && !_pulseController.isAnimating) {
      _pulseController.repeat(reverse: true);
    } else if (!isEnabled && _pulseController.isAnimating) {
      _pulseController.stop();
      _pulseController.value = 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEnabled = widget.onPressed != null;
    final diameter = context.responsive<double>(
      mobile: _diameterMobile,
      tablet: _diameterTablet,
    );
    final nearRingDiameter = diameter + (AppSpacing.smMd * 2);
    final farRingDiameter = diameter + (AppSpacing.md * 2);

    return Column(
      children: [
        AnimatedBuilder(
          animation: _pulse,
          builder: (context, child) => Transform.scale(
            scale: isEnabled ? _pulse.value : 1.0,
            child: child,
          ),
          child: Semantics(
            button: true,
            enabled: isEnabled,
            label: 'Pedir ajuda à rede de apoio',
            child: SizedBox(
              width: farRingDiameter,
              height: farRingDiameter,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: farRingDiameter,
                    height: farRingDiameter,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.sosRingFar,
                        width: _farRingStrokeWidth,
                      ),
                    ),
                  ),
                  Container(
                    width: nearRingDiameter,
                    height: nearRingDiameter,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.sosRingNear,
                        width: _nearRingStrokeWidth,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: widget.onPressed,
                    child: Container(
                      width: diameter,
                      height: diameter,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isEnabled ? null : AppColors.border,
                        gradient: isEnabled
                            ? AppColors.sosButtonGradient
                            : null,
                        border: Border.all(
                          color: AppColors.background,
                          width: AppSpacing.sm,
                        ),
                        boxShadow: isEnabled
                            ? AppShadows.accent(AppColors.sosGradientStart)
                            : AppShadows.card,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.notifications_active_rounded,
                            size: AppSpacing.xxl,
                            color: isEnabled
                                ? AppColors.textInverse
                                : AppColors.textSecondary,
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            'SOS',
                            style: AppTypography.averiaDisplayLarge.copyWith(
                              color: isEnabled
                                  ? AppColors.textInverse
                                  : AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        if (widget.caption != null) ...[
          const SizedBox(height: AppSpacing.smMd),
          Text(
            widget.caption!,
            textAlign: TextAlign.center,
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ],
    );
  }
}
