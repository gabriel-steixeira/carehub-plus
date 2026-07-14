import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../core/theme/app_theme.dart';
import '../features/auth/data/repositories/auth_repository.dart';
import 'router/app_router.dart';

/// Root [MaterialApp] widget.
class App extends StatelessWidget {
  const App({super.key, this.authRepository});

  final AuthRepository? authRepository;

  @override
  Widget build(BuildContext context) {
    return RepositoryProvider<AuthRepository>(
      create: (context) => authRepository ?? AuthRepository(),
      child: MaterialApp.router(
        title: 'CareHub+',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        routerConfig: AppRouter.router,
      ),
    );
  }
}

