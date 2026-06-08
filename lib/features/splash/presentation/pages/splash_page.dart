import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../app/router/app_router.dart';

/// Splash screen with animated logo and gradient background.
///
/// No BLoC needed — purely visual with auto-navigation to login.
class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fadeIn;
  late final Animation<double> _scaleUp;
  late final Animation<double> _progressAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: AppConstants.splashDuration,
    );

    // Logo fades in during first 40% of animation
    _fadeIn = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.4, curve: Curves.easeOut),
      ),
    );

    // Logo scales up slightly during first 40%
    _scaleUp = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.4, curve: Curves.easeOut),
      ),
    );

    // Progress bar fills during 30%–90%
    _progressAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.3, 0.9, curve: Curves.easeInOut),
      ),
    );

    _controller.forward();

    // Navigate to login after splash
    Future.delayed(
      AppConstants.splashDuration + const Duration(milliseconds: 300),
      () {
        if (mounted) {
          context.go(AppRoutes.login);
        }
      },
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(gradient: AppColors.splashGradient),
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Spacer(flex: 3),

                // Logo with fade + scale
                FadeTransition(
                  opacity: _fadeIn,
                  child: ScaleTransition(scale: _scaleUp, child: _buildLogo()),
                ),

                const Spacer(flex: 3),

                // Progress bar
                FadeTransition(
                  opacity: _fadeIn,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.xxxl,
                    ),
                    child: _buildProgressBar(),
                  ),
                ),

                const SizedBox(height: AppSpacing.xxl),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildLogo() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Logo icon — 5 circles in a ring
        SizedBox(
          width: 72,
          height: 72,
          child: CustomPaint(painter: _LogoCirclesPainter()),
        ),
        const SizedBox(height: AppSpacing.md),
        // App name
        Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              'Carehub',
              style: AppTypography.headlineMedium.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
            Text(
              '+',
              style: AppTypography.headlineMedium.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        // Tagline
        Text(
          'Cuidar com leveza, juntos',
          style: AppTypography.bodyMedium.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildProgressBar() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
      child: SizedBox(
        height: 6,
        child: Stack(
          children: [
            // Background
            Container(
              decoration: BoxDecoration(
                color: AppColors.border.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
              ),
            ),
            // Animated fill
            FractionallySizedBox(
              widthFactor: _progressAnimation.value,
              child: Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.primary, Color(0xFFFACFE8)],
                  ),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Custom painter that draws the CareHub+ logo — 5 colored circles in a ring.
class _LogoCirclesPainter extends CustomPainter {
  static const List<Color> _colors = [
    Color(0xFF7B61C8), // Purple
    Color(0xFFE91E8C), // Pink
    Color(0xFFF5C842), // Yellow
    Color(0xFF4FC3F7), // Blue
    Color(0xFF66BB6A), // Green
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width * 0.35;
    const circleRadius = 7.0;
    const ringStroke = 2.0;

    // Draw connecting ring
    final ringPaint = Paint()
      ..color = const Color(0xFF7B61C8).withValues(alpha: 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = ringStroke;
    canvas.drawCircle(center, radius, ringPaint);

    // Draw 5 colored circles
    for (var i = 0; i < 5; i++) {
      final angle = (i * 72 - 90) * math.pi / 180;
      final x = center.dx + radius * math.cos(angle);
      final y = center.dy + radius * math.sin(angle);

      final paint = Paint()
        ..color = _colors[i]
        ..style = PaintingStyle.fill;

      canvas.drawCircle(Offset(x, y), circleRadius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
