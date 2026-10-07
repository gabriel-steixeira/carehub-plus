import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../core/auth/session_listener.dart';
import '../core/theme/app_theme.dart';
import '../features/auth/data/repositories/auth_repository.dart';
import '../features/notifications/data/repositories/notification_inbox_repository.dart';
import '../features/notifications/presentation/bloc/notification_inbox_bloc.dart';
import 'router/app_router.dart';

/// Root [MaterialApp] widget.
class App extends StatelessWidget {
  const App({super.key, this.authRepository, this.notificationInboxRepository});

  final AuthRepository? authRepository;

  /// Injetável para testes. Sem valor, usa o Firestore real.
  final NotificationInboxRepository? notificationInboxRepository;

  @override
  Widget build(BuildContext context) {
    return RepositoryProvider<AuthRepository>(
      create: (context) => authRepository ?? AuthRepository(),
      // Caixa de notificações única para o app inteiro: o sino de qualquer
      // tela e a lista leem o mesmo estado. Criada só quando o primeiro sino
      // aparece (lazy), então telas sem cabeçalho não abrem a escuta.
      child: BlocProvider<NotificationInboxBloc>(
        create: (context) => NotificationInboxBloc(
          repository:
              notificationInboxRepository ?? NotificationInboxRepository(),
        )..add(const NotificationInboxStartedEvent()),
        child: MaterialApp.router(
          title: 'CareHub+',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light,
          routerConfig: AppRouter.router,
          builder: (context, child) =>
              SessionListener(child: child ?? const SizedBox.shrink()),
        ),
      ),
    );
  }
}
