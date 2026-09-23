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

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../../core/errors/app_exception.dart';

/// Dados de foto do cuidador (URL remota e/ou base64).
class CaregiverPhoto {
  const CaregiverPhoto({this.photoUrl, this.photoBase64});

  final String? photoUrl;
  final String? photoBase64;

  /// Retorna a melhor representação disponível: prioriza URL, mas usa base64
  /// como fallback.
  String? get effectivePhotoUrl => photoUrl ?? photoBase64;
}

/// Acesso à foto de perfil do cuidador logado.
///
/// Fica na camada de dados porque é aqui que o SDK do Firebase pode ser
/// tocado — nem o BLoC nem os widgets falam com o Firebase.
class CaregiverAvatarRepository {
  CaregiverAvatarRepository({
    FirebaseAuth? firebaseAuth,
    FirebaseFirestore? firestore,
  }) : _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance,
       _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseAuth _firebaseAuth;
  final FirebaseFirestore _firestore;

  /// Foto do cuidador autenticado (URL e/ou base64).
  ///
  /// Busca primeiro no Firestore (onde pode ter tanto `photoUrl` quanto
  /// `photoBase64`). Se não houver documento, usa o `photoURL` do Firebase
  /// Auth como fallback.
  ///
  /// Retorna ambos os campos nulos quando não há usuário logado ou quando a
  /// conta não tem foto. Nesse caso a interface mostra o avatar genérico.
  Future<CaregiverPhoto> fetchPhoto() async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user == null) return const CaregiverPhoto();

      // Tenta buscar do Firestore primeiro
      final doc = await _firestore
          .collection('caregivers')
          .doc(user.uid)
          .get();

      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;
        final photoUrl = _normalize(data['photoUrl']);
        final photoBase64 = _normalize(data['photoBase64']);
        return CaregiverPhoto(photoUrl: photoUrl, photoBase64: photoBase64);
      }

      // Fallback: usa a foto do Firebase Auth
      final authPhotoUrl = _normalize(user.photoURL);
      return CaregiverPhoto(photoUrl: authPhotoUrl);
    } on FirebaseException catch (e) {
      throw AppException(
        e.message ?? 'Não foi possível carregar a foto do cuidador.',
        code: e.code,
      );
    }
  }

  /// URL da foto do cuidador autenticado (compatibilidade com código antigo).
  ///
  /// **Deprecated:** Use [fetchPhoto] para ter acesso tanto a URL quanto a
  /// base64. Este método será removido em versões futuras.
  @Deprecated('Use fetchPhoto() para suporte completo a URL e base64')
  Future<String?> fetchPhotoUrl() async {
    final photo = await fetchPhoto();
    return photo.effectivePhotoUrl;
  }

  /// String vazia vinda do provedor ou do Firestore significa ausência de dado.
  static String? _normalize(dynamic value) {
    if (value is! String || value.isEmpty) return null;
    return value;
  }
}
