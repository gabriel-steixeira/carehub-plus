import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../app/router/app_router.dart';
import '../../features/auth/data/repositories/auth_repository.dart';
import '../../shared/widgets/session_expired_bottom_sheet.dart';

/// Global Session Listener widget that monitors authStateChanges from [AuthRepository].
///
/// If an authenticated user becomes unauthenticated while on a protected route,
/// it prompts [SessionExpiredBottomSheet] to inform the user and redirect to login.
class SessionListener extends StatefulWidget {
  const SessionListener({
    super.key,
    required this.child,
    this.repository,
  });

  final Widget child;
  final AuthRepository? repository;

  @override
  State<SessionListener> createState() => _SessionListenerState();
}

class _SessionListenerState extends State<SessionListener> {
  StreamSubscription<User?>? _authSubscription;
  bool _isBottomSheetShowing = false;
  bool _wasAuthenticatedBefore = false;

  static const List<String> _publicRoutes = [
    AppRoutes.splash,
    AppRoutes.login,
    AppRoutes.register,
    AppRoutes.forgotPassword,
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initAuthListener();
    });
  }

  void _initAuthListener() {
    if (!mounted) return;
    try {
      final repo = widget.repository ?? context.read<AuthRepository>();
      _authSubscription = repo.authStateChanges.listen((user) {
        if (user != null) {
          _wasAuthenticatedBefore = true;
          _isBottomSheetShowing = false;
        } else {
          // User logged out or session expired
          if (_wasAuthenticatedBefore) {
            _wasAuthenticatedBefore = false;
            _handleSessionExpired();
          }
        }
      });
    } catch (_) {}
  }

  void _handleSessionExpired() {
    if (!mounted || _isBottomSheetShowing) return;

    final location = GoRouterState.of(context).uri.toString();
    final isPublicRoute =
        _publicRoutes.any((r) => location == r || location.startsWith('$r/'));

    if (!isPublicRoute) {
      _isBottomSheetShowing = true;
      SessionExpiredBottomSheet.show(context).then((_) {
        _isBottomSheetShowing = false;
      });
    }
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
