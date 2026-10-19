import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app/app.dart';
import 'app/router/app_router.dart';
import 'firebase_options.dart';
import 'services/push_notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Enable Firestore offline persistence
  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: true,
  );

  // Push (FCM): registra o aparelho da conta logada. Tocar na notificação
  // com o app em segundo plano abre a caixa de notificações.
  PushNotificationService().start(
    onNotificationOpened: () =>
        AppRouter.router.push(AppRoutes.notificationInbox),
    onNotificationData: (type, relatedId) {
      if (type == 'sos') {
        AppRouter.router.push(AppRoutes.sosDetail, extra: relatedId);
      } else {
        AppRouter.router.push(AppRoutes.notificationInbox);
      }
    },
  );

  // Lock orientation to portrait
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Transparent status bar
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );

  runApp(const App());
}

