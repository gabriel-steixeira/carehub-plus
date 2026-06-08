import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

/// Standard loading indicator — always use this, never raw [CircularProgressIndicator].
class AppLoading extends StatelessWidget {
  const AppLoading({super.key, this.size = 40.0});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox(
        width: size,
        height: size,
        child: const CircularProgressIndicator(
          strokeWidth: 3,
          valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
        ),
      ),
    );
  }
}
