/*
 * CareHub Plus — App / Ponte entre Stream e Listenable do roteador
 *
 * Adapta um Stream (como o authStateChanges do Firebase) para o Listenable
 * que o go_router espera em refreshListenable. Assim o roteador reavalia as
 * rotas sempre que o estado de autenticação muda — por exemplo, quando a
 * conta é excluída e a sessão deixa de existir.
 *
 * Author: Vitoria Lana
 * Created on: 15/10/2026
 * Version: 1.0.0
 * Squad: CareHub Plus
 */

import 'dart:async';

import 'package:flutter/foundation.dart';

/// Notifica os ouvintes a cada evento emitido pelo [stream].
///
/// Pensado para o `refreshListenable` do go_router: emite uma vez na criação
/// e depois a cada novo evento, forçando o roteador a reavaliar o `redirect`.
class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    notifyListeners();
    _subscription = stream.asBroadcastStream().listen(
      (_) => notifyListeners(),
    );
  }

  late final StreamSubscription<dynamic> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
