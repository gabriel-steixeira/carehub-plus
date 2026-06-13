import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../app/router/app_router.dart';

/// Splash screen with animated official logo and gradient background.
///
/// Navigates to login screen after the progress bar animation finishes.
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
    _scaleUp = Tween<double>(begin: 0.9, end: 1.0).animate(
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

    // To prevent the initial shader compilation jank from skipping the splash screen,
    // we start the animation and the timer AFTER the first frame is fully rendered.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _controller.forward();

      Future.delayed(
        AppConstants.splashDuration + const Duration(milliseconds: 300),
        () {
          if (mounted) {
            context.go(AppRoutes.login);
          }
        },
      );
    });
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
    return Image.asset(
      'assets/images/logo_oficial.png',
      width: 280,
      fit: BoxFit.contain,
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
