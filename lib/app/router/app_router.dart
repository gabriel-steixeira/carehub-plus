import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/pages/forgot_password_page.dart';
import '../../features/about/presentation/pages/about_page.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/auth/presentation/pages/register_page.dart';
import '../../features/chat/data/models/chat_room_model.dart';
import '../../features/chat/presentation/pages/chat_list_page.dart';
import '../../features/chat/presentation/pages/chat_room_page.dart';
import '../../features/cora/presentation/pages/cora_chat_page.dart';
import '../../features/dashboard/presentation/pages/dashboard_page.dart';
import '../../features/toke/presentation/pages/toke_chat_page.dart';
import '../../features/home/presentation/pages/home_page.dart';
import '../../features/network/presentation/pages/network_page.dart';
import '../../features/notifications/presentation/pages/notifications_page.dart';
import '../../features/profile/presentation/pages/edit_profile_page.dart';
import '../../features/settings/presentation/pages/settings_page.dart';
import '../../features/sos/presentation/models/sos_request_args.dart';
import '../../features/sos/presentation/pages/sos_page.dart';
import '../../features/splash/presentation/pages/splash_page.dart';
import '../../features/subscriptions/presentation/pages/subscriptions_page.dart';
import '../../features/tasks/presentation/models/tasks_navigation_args.dart';
import '../../features/tasks/presentation/pages/tasks_page.dart';

/// All route paths as static constants.
class AppRoutes {
  AppRoutes._();

  static const String splash = '/';
  static const String login = '/login';
  static const String register = '/register';
  static const String forgotPassword = '/forgot-password';
  static const String home = '/home';
  static const String dashboard = '/dashboard';
  static const String tasks = '/tasks';
  static const String coraChat = '/cora';
  static const String tokeChat = '/toke';
  static const String chat = '/chat';
  static const String chatRoom = '/chat-room';
  static const String network = '/network';
  static const String sos = '/sos';
  static const String settings = '/settings';
  static const String notifications = '/notifications';
  static const String editProfile = '/profile/edit';
  static const String subscriptions = '/subscriptions';
  static const String about = '/about';
}

/// GoRouter configuration — single source of truth for navigation.
class AppRouter {
  AppRouter._();

  static final GoRouter router = GoRouter(
    initialLocation: AppRoutes.splash,
    routes: [
      GoRoute(
        path: AppRoutes.splash,
        builder: (context, state) => const SplashPage(),
      ),
      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) => const LoginPage(),
      ),
      GoRoute(
        path: AppRoutes.register,
        builder: (context, state) => const RegisterPage(),
      ),
      GoRoute(
        path: AppRoutes.forgotPassword,
        builder: (context, state) => const ForgotPasswordPage(),
      ),
      GoRoute(
        path: AppRoutes.home,
        builder: (context, state) => const HomePage(),
      ),
      GoRoute(
        path: AppRoutes.dashboard,
        builder: (context, state) {
          final profileId = state.extra as String?;
          return DashboardPage(initialProfileId: profileId);
        },
      ),
      GoRoute(
        path: AppRoutes.tasks,
        builder: (context, state) {
          final extra = state.extra;
          if (extra is TasksNavigationArgs) {
            return TasksPage(
              careRecipientId: extra.careRecipientId,
              isSosSelectionMode: extra.isSosSelectionMode,
            );
          }
          return TasksPage(careRecipientId: extra as String?);
        },
      ),
      GoRoute(
        path: AppRoutes.coraChat,
        builder: (context, state) => const CoraChatPage(),
      ),
      GoRoute(
        path: AppRoutes.tokeChat,
        builder: (context, state) => const TokeChatPage(),
      ),
      GoRoute(
        path: AppRoutes.chat,
        builder: (context, state) {
          final profileId = state.extra as String?;
          return ChatListPage(careRecipientId: profileId);
        },
      ),
      GoRoute(
        path: AppRoutes.chatRoom,
        builder: (context, state) {
          final room = state.extra as ChatRoomModel;
          return ChatRoomPage(room: room);
        },
      ),
      GoRoute(
        path: AppRoutes.network,
        builder: (context, state) =>
            NetworkPage(careRecipientId: state.extra as String?),
      ),
      GoRoute(
        path: AppRoutes.sos,
        builder: (context, state) {
          // Opcional: vem preenchido quando o SOS nasce de uma tarefa.
          final args = state.extra as SosRequestArgs?;
          return SosPage(args: args);
        },
      ),
      GoRoute(
        path: AppRoutes.settings,
        builder: (context, state) => const SettingsPage(),
      ),
      GoRoute(
        path: AppRoutes.notifications,
        builder: (context, state) => const NotificationsPage(),
      ),
      GoRoute(
        path: AppRoutes.editProfile,
        builder: (context, state) => const EditProfilePage(),
      ),
      GoRoute(
        path: AppRoutes.subscriptions,
        builder: (context, state) => const SubscriptionsPage(),
      ),
      GoRoute(
        path: AppRoutes.about,
        builder: (context, state) => const AboutPage(),
      ),
    ],
  );
}
