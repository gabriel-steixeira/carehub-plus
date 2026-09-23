import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/router/app_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../features/profile/data/repositories/caregiver_profile_repository.dart';

/// Standard top header bar for main app screens (Home, Dashboard, etc.).
class AppHeader extends StatefulWidget {
  const AppHeader({
    super.key,
    this.photoUrl,
    this.photoBase64,
    this.onSettingsPressed,
    this.showProfile = true,
    this.showSettings = true,
    this.leading,
  });

  /// URL of the caregiver's profile photo.
  final String? photoUrl;

  /// Base64 data of the caregiver's profile photo.
  final String? photoBase64;

  /// Callback when settings button is pressed. Defaults to navigating to settings route.
  final VoidCallback? onSettingsPressed;

  /// Whether the caregiver profile avatar is visible.
  final bool showProfile;

  /// Whether the settings button is visible.
  final bool showSettings;

  /// Optional leading widget (e.g. a back button) shown before the avatar.
  ///
  /// `null` by default so every existing screen keeps its current layout —
  /// only screens pushed on top of another (like a chat room) need it.
  final Widget? leading;

  /// Height of the header content, excluding the status bar area.
  ///
  /// Keeps the header identical on every screen, whether or not the page
  /// already consumes the safe area through `AppPageFrame`.
  static const double contentHeight = AppSpacing.xxl + AppSpacing.sm;

  @override
  State<AppHeader> createState() => _AppHeaderState();
}

class _AppHeaderState extends State<AppHeader> {
  late Future<_CaregiverPhoto> _photoFuture;

  @override
  void initState() {
    super.initState();
    _photoFuture = _loadPhoto();
  }

  @override
  void didUpdateWidget(covariant AppHeader oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.photoUrl != widget.photoUrl ||
        oldWidget.photoBase64 != widget.photoBase64 ||
        oldWidget.showProfile != widget.showProfile) {
      _photoFuture = _loadPhoto();
    }
  }

  Future<_CaregiverPhoto> _loadPhoto() async {
    final explicitPhoto = _photoFromWidget();
    if (explicitPhoto.hasValue || !widget.showProfile) return explicitPhoto;

    try {
      final snapshot = await CaregiverProfileRepository().fetchProfileWithPlan();
      return _CaregiverPhoto(
        photoUrl: _normalize(widget.photoUrl ?? snapshot.profile.photoUrl),
        photoBase64: _normalize(snapshot.profile.photoBase64),
      );
    } catch (_) {
      // A falha ao carregar o avatar não deve impedir o uso da tela.
      return const _CaregiverPhoto();
    }
  }

  _CaregiverPhoto _photoFromWidget() {
    return _CaregiverPhoto(
      photoUrl: _normalize(widget.photoUrl),
      photoBase64: _normalize(widget.photoBase64),
    );
  }

  static String? _normalize(String? value) {
    if (value == null || value.isEmpty) return null;
    return value;
  }

  static Uint8List? _decodeBase64(String? value) {
    if (value == null) return null;

    final separatorIndex = value.indexOf(',');
    final encoded = separatorIndex >= 0
        ? value.substring(separatorIndex + 1)
        : value;

    try {
      return base64Decode(encoded);
    } on FormatException {
      return null;
    }
  }

  Widget _buildHeader(BuildContext context, _CaregiverPhoto photo) {
    // Zero when an ancestor (AppPageFrame) already reserved the status bar area.
    final statusBarHeight = MediaQuery.paddingOf(context).top;
    final photoBytes = _decodeBase64(photo.photoBase64);
    final hasPhoto = photoBytes != null || photo.photoUrl != null;

    return Container(
      color: AppColors.background,
      padding: EdgeInsets.only(
        left: AppSpacing.md,
        right: AppSpacing.md,
        top: statusBarHeight,
      ),
      height: statusBarHeight + AppHeader.contentHeight,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              if (widget.leading != null) ...[
                widget.leading!,
                const SizedBox(width: AppSpacing.xs),
              ],
              if (widget.showProfile) ...[
                // Caregiver Avatar
                CircleAvatar(
                  radius: 18,
                  backgroundColor: AppColors.primaryLight.withValues(
                    alpha: 0.2,
                  ),
                  backgroundImage: photoBytes != null
                      ? MemoryImage(photoBytes)
                      : photo.photoUrl == null
                      ? null
                      : NetworkImage(photo.photoUrl!),
                  child: hasPhoto
                      ? null
                      : const Icon(
                          Icons.person,
                          size: 20,
                          color: AppColors.primary,
                        ),
                ),
                const SizedBox(width: AppSpacing.sm),
              ],

              // Logo Pequeno
              Image.asset(
                'assets/images/logo_pequeno.png',
                height: 28,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  return Text(
                    'CareHub+',
                    style: AppTypography.averiaTitleLarge.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  );
                },
              ),
            ],
          ),

          if (widget.showSettings)
            // Right side: Settings gear
            IconButton(
              icon: const Icon(
                Icons.settings_outlined,
                color: AppColors.textSecondary,
                size: 24,
              ),
              onPressed:
                  widget.onSettingsPressed ??
                  () {
                    context.push(AppRoutes.settings);
                  },
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final explicitPhoto = _photoFromWidget();
    if (explicitPhoto.hasValue || !widget.showProfile) {
      return _buildHeader(context, explicitPhoto);
    }

    return FutureBuilder<_CaregiverPhoto>(
      future: _photoFuture,
      builder: (context, snapshot) => _buildHeader(
        context,
        snapshot.data ?? const _CaregiverPhoto(),
      ),
    );
  }
}

class _CaregiverPhoto {
  const _CaregiverPhoto({this.photoUrl, this.photoBase64});

  final String? photoUrl;
  final String? photoBase64;

  bool get hasValue => photoUrl != null || photoBase64 != null;
}
