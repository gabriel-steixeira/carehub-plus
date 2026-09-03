/*
 * CareHub Plus — Dados / Repositório de Categorias de Cuidado
 *
 * Único ponto de acesso à persistência de categorias. Compartilhado por
 * Tasks e Chat: cada tela injeta a mesma classe no seu próprio BLoC — nunca
 * um BLoC entre as duas features, como manda `architecture.md`.
 *
 * Armazenamento temporário: `shared_preferences` (local no dispositivo), não
 * Firestore. A conta usada para autenticar o Firebase CLI neste ambiente
 * não tem permissão para publicar a regra de segurança da coleção
 * `care_categories`, então a escrita no Firestore ficava bloqueada em
 * silêncio. Local resolve agora sem depender de acesso ao console.
 * Quando o acesso ao Firebase for resolvido, é só reescrever o corpo dos
 * três métodos públicos para usar `FirebaseFirestore` — a assinatura da
 * classe e o contrato usado por `CareCategoriesBloc` não mudam.
 *
 * Author: Vitoria Lana
 * Created on: 23/08/2026
 * Version: 2.0.0
 * Squad: CareHub Plus
 */

import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/errors/app_exception.dart';
import '../models/care_category_model.dart';

/// Chave única do valor salvo em `shared_preferences`.
const String _storageKey = 'care_categories';

/// Categorias semeadas no primeiro acesso, para que a lista nunca comece
/// vazia. Ficam marcadas como `isDefault` e não podem ser excluídas — tarefas
/// e assuntos antigos continuam com uma categoria válida.
final List<CareCategoryModel> _seedCategories = [
  const CareCategoryModel(
    id: 'health',
    label: 'Saúde',
    iconKey: 'health',
    colorKey: 'green',
    isDefault: true,
  ),
  const CareCategoryModel(
    id: 'food',
    label: 'Alimentação',
    iconKey: 'food',
    colorKey: 'blue',
    isDefault: true,
  ),
  const CareCategoryModel(
    id: 'medication',
    label: 'Medicamento',
    iconKey: 'medication',
    colorKey: 'red',
    isDefault: true,
  ),
  const CareCategoryModel(
    id: 'appointment',
    label: 'Consulta',
    iconKey: 'appointment',
    colorKey: 'blue',
    isDefault: true,
  ),
  const CareCategoryModel(
    id: 'activity',
    label: 'Atividade',
    iconKey: 'activity',
    colorKey: 'purple',
    isDefault: true,
  ),
  const CareCategoryModel(
    id: 'other',
    label: 'Outro',
    iconKey: 'other',
    colorKey: 'grey',
    isDefault: true,
  ),
];

/// Repositório de categorias de cuidado, com `shared_preferences` como fonte
/// temporária.
class CareCategoriesRepository {
  CareCategoriesRepository({SharedPreferencesAsync? preferences})
      : _preferences = preferences ?? SharedPreferencesAsync();

  final SharedPreferencesAsync _preferences;

  /// Busca as categorias existentes, semeando os padrões na primeira vez.
  Future<List<CareCategoryModel>> fetchCategories() async {
    try {
      final stored = await _readAll();
      if (stored.isNotEmpty) return stored;

      await _writeAll(_seedCategories);
      return _seedCategories;
    } catch (e) {
      throw AppException('Erro ao carregar categorias: $e');
    }
  }

  /// Cria uma nova categoria escolhida pela cuidadora.
  Future<CareCategoryModel> addCategory({
    required String label,
    required String iconKey,
    required String colorKey,
  }) async {
    try {
      final current = await _readAll();
      final category = CareCategoryModel(
        id: 'cat_${DateTime.now().millisecondsSinceEpoch}',
        label: label,
        iconKey: iconKey,
        colorKey: colorKey,
      );
      await _writeAll([...current, category]);
      return category;
    } catch (e) {
      throw AppException('Erro ao criar categoria: $e');
    }
  }

  /// Remove uma categoria criada pela cuidadora.
  ///
  /// Categorias padrão (`isDefault`) nunca chegam a este método — a interface
  /// não oferece a opção de excluí-las (ver `CareCategoriesBloc`).
  Future<void> deleteCategory(String categoryId) async {
    try {
      final current = await _readAll();
      final updated = current.where((c) => c.id != categoryId).toList();
      await _writeAll(updated);
    } catch (e) {
      throw AppException('Erro ao excluir categoria: $e');
    }
  }

  Future<List<CareCategoryModel>> _readAll() async {
    final raw = await _preferences.getString(_storageKey);
    if (raw == null || raw.isEmpty) return const [];

    final decoded = jsonDecode(raw) as List<dynamic>;
    return decoded
        .map((item) => CareCategoryModel.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<void> _writeAll(List<CareCategoryModel> categories) async {
    final encoded = jsonEncode(categories.map((c) => c.toJson()).toList());
    await _preferences.setString(_storageKey, encoded);
  }
}
