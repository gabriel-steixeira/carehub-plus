/*
 * CareHub Plus — Dados / Repositório Sobre
 *
 * Lê o conteúdo institucional compartilhado do Firestore. A página e o BLoC
 * dependem apenas deste contrato, mantendo o acesso ao Firebase nesta camada.
 *
 * Author: Vitoria Lana
 * Created on: 27/08/2026
 * Version: 1.0.0
 * Squad: CareHub Plus
 */

import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/errors/app_exception.dart';
import '../models/about_content_model.dart';
import '../../domain/entities/about_content_entity.dart';

/// Fonte remota do conteúdo da página Sobre.
class AboutRepository {
  AboutRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  static const String _collection = 'about_content';
  static const String _document = 'app';

  final FirebaseFirestore _firestore;

  Future<AboutContentEntity> fetchContent() async {
    try {
      final snapshot = await _firestore
          .collection(_collection)
          .doc(_document)
          .get();
      final data = snapshot.data();

      if (data == null) {
        throw const AppException('O conteúdo Sobre ainda não está disponível.');
      }

      final content = AboutContentModel.fromJson(data);
      if (!content.hasContent) {
        throw const AppException(
          'O conteúdo Sobre está incompleto no momento.',
        );
      }

      return content;
    } on FirebaseException catch (error) {
      throw AppException(
        'Não foi possível carregar o conteúdo Sobre.',
        code: error.code,
      );
    }
  }
}
