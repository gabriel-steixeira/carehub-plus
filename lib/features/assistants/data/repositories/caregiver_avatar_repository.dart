/*
 * CareHub Plus — Dados / Foto do Cuidador
 *
 * Fornece a foto do cuidador autenticado para a tela de chat, que a usa em dois
 * lugares: o avatar do `AppHeader` e o avatar das bolhas escritas por ela. Uma
 * única fonte de dado garante que os dois nunca fiquem diferentes.
 *
 * Author: Vitoria Lana
 * Created on: 21/08/2026
 * Version: 1.0.0
 * Squad: CareHub Plus
 */

import 'package:firebase_auth/firebase_auth.dart';

import '../../../../core/errors/app_exception.dart';

/// Acesso à foto de perfil do cuidador logado.
///
/// Fica na camada de dados porque é aqui que o SDK do Firebase pode ser
/// tocado — nem o BLoC nem os widgets falam com o Firebase.
class CaregiverAvatarRepository {
  CaregiverAvatarRepository({FirebaseAuth? firebaseAuth})
    : _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance;

  final FirebaseAuth _firebaseAuth;

  /// URL da foto do cuidador autenticado.
  ///
  /// Retorna `null` quando não há usuário logado ou quando a conta não tem
  /// foto (comum em cadastro por e-mail e senha). Nesse caso a interface
  /// mostra o avatar genérico.
  Future<String?> fetchPhotoUrl() async {
    try {
      final photoUrl = _firebaseAuth.currentUser?.photoURL;
      // String vazia vinda do provedor é tratada como ausência de foto.
      if (photoUrl == null || photoUrl.isEmpty) return null;
      return photoUrl;
    } on FirebaseException catch (e) {
      throw AppException(
        e.message ?? 'Não foi possível carregar a foto do cuidador.',
        code: e.code,
      );
    }
  }
}
