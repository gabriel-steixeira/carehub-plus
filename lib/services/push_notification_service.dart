/*
 * CareHub Plus — Serviço de Notificações Push (FCM)
 *
 * Liga o aparelho ao Firebase Cloud Messaging: pede a permissão de
 * notificação (Android 13+), grava o token do aparelho em
 * `push_tokens/{token}` para a conta logada — é por ele que o backend sabe
 * para onde mandar o push — e invalida o token quando a pessoa sai da conta,
 * para o aparelho não receber avisos de quem já saiu.
 *
 * Com o app fechado ou em segundo plano, o Android mostra o push sozinho.
 * Com o app aberto, quem avisa é o sino do `AppHeader`.
 *
 * Author: Vitoria Lana
 * Created on: 03/10/2026
 * Version: 1.0.0
 * Squad: CareHub Plus
 */

import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

/// Registro do aparelho para receber notificações push.
class PushNotificationService {
  PushNotificationService({
    FirebaseMessaging? messaging,
    FirebaseAuth? firebaseAuth,
    FirebaseFirestore? firestore,
  }) : _messaging = messaging ?? FirebaseMessaging.instance,
       _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance,
       _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseMessaging _messaging;
  final FirebaseAuth _firebaseAuth;
  final FirebaseFirestore _firestore;

  static const String _collection = 'push_tokens';

  StreamSubscription<User?>? _authSubscription;
  StreamSubscription<String>? _tokenRefreshSubscription;

  /// Conta que estava logada, para saber quando houve uma saída de verdade
  /// (e não só o app abrindo sem ninguém logado).
  String? _lastUid;

  /// Começa a acompanhar a conta logada. Chamar uma vez, na abertura do app.
  ///
  /// [onNotificationData] recebe o `type`/`relatedId` do push quando ambos
  /// vierem preenchidos, permitindo abrir a tela certa (ex.: o detalhe do
  /// SOS). Sem esses dados, cai no [onNotificationOpened] (comportamento
  /// antigo).
  void start({
    void Function()? onNotificationOpened,
    void Function(String type, String relatedId)? onNotificationData,
  }) {
    // Push só no Android por enquanto (iOS exige chave APNs).
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return;

    _authSubscription ??= _firebaseAuth.authStateChanges().listen(
      _onUserChanged,
    );

    _tokenRefreshSubscription ??= _messaging.onTokenRefresh.listen((token) {
      final uid = _firebaseAuth.currentUser?.uid;
      if (uid != null) unawaited(_saveToken(token, uid));
    });

    if (onNotificationOpened != null || onNotificationData != null) {
      // Toque na notificação com o app em segundo plano.
      FirebaseMessaging.onMessageOpenedApp.listen(
        (message) => _route(message, onNotificationOpened, onNotificationData),
      );

      // App encerrado: a mensagem que o abriu chega por aqui.
      unawaited(_handleInitialMessage(onNotificationOpened, onNotificationData));
    }
  }

  /// Trata o push que abriu o app quando ele estava encerrado.
  Future<void> _handleInitialMessage(
    void Function()? onNotificationOpened,
    void Function(String type, String relatedId)? onNotificationData,
  ) async {
    try {
      final initial = await _messaging.getInitialMessage();
      if (initial != null) {
        _route(initial, onNotificationOpened, onNotificationData);
      }
    } catch (error) {
      // Push é complemento: falhar aqui não pode travar o app.
      debugPrint('PushNotificationService: $error');
    }
  }

  /// Decide para onde levar a pessoa a partir dos dados do push.
  void _route(
    RemoteMessage message,
    void Function()? onNotificationOpened,
    void Function(String type, String relatedId)? onNotificationData,
  ) {
    try {
      final type = message.data['type'] as String?;
      final relatedId = message.data['relatedId'] as String?;
      if (onNotificationData != null &&
          type != null &&
          type.isNotEmpty &&
          relatedId != null &&
          relatedId.isNotEmpty) {
        onNotificationData(type, relatedId);
        return;
      }
      onNotificationOpened?.call();
    } catch (error) {
      // Push é complemento: falhar aqui não pode travar o app.
      debugPrint('PushNotificationService: $error');
    }
  }

  Future<void> _onUserChanged(User? user) async {
    try {
      if (user == null) {
        if (_lastUid != null) {
          // Sem login não dá para apagar o documento (regras do Firestore).
          // Invalidar o token resolve: o backend recebe "token não
          // registrado" no próximo envio e apaga o registro.
          await _messaging.deleteToken();
        }
        _lastUid = null;
        return;
      }

      _lastUid = user.uid;
      await _messaging.requestPermission();
      final token = await _messaging.getToken();
      if (token != null) await _saveToken(token, user.uid);
    } catch (error) {
      // Push é complemento: falhar aqui não pode travar o app.
      debugPrint('PushNotificationService: $error');
    }
  }

  Future<void> _saveToken(String token, String uid) async {
    try {
      await _firestore.collection(_collection).doc(token).set({
        'uid': uid,
        'platform': 'android',
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } on FirebaseException catch (error) {
      debugPrint('PushNotificationService: token não salvo (${error.code}).');
    }
  }

  /// Para de acompanhar a conta. Usado em testes.
  Future<void> dispose() async {
    await _authSubscription?.cancel();
    await _tokenRefreshSubscription?.cancel();
    _authSubscription = null;
    _tokenRefreshSubscription = null;
  }
}
