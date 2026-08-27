/*
 * CareHub Plus — Domínio / Categoria de Cuidado
 *
 * Uma categoria criada pela cuidadora para organizar tarefas e assuntos de
 * chat (ex.: Saúde, Alimentação). É Dart puro: guarda apenas as chaves do
 * ícone e da cor (`iconKey`/`colorKey`), nunca um `IconData` ou `Color` — a
 * tradução para Flutter é responsabilidade da camada de apresentação. Assim a
 * mesma categoria pode ser usada por Tasks e por Chat sem que o domínio
 * dependa do Flutter.
 *
 * Author: Vitoria Lana
 * Created on: 23/08/2026
 * Version: 1.0.0
 * Squad: CareHub Plus
 */

import 'package:equatable/equatable.dart';

/// Categoria de cuidado compartilhada entre Tarefas e Chat.
class CareCategoryEntity extends Equatable {
  const CareCategoryEntity({
    required this.id,
    required this.label,
    required this.iconKey,
    required this.colorKey,
    this.isDefault = false,
  });

  /// Identificador único, usado como `categoryId` em tarefas e assuntos.
  final String id;

  /// Nome exibido para a cuidadora (ex.: "Saúde").
  final String label;

  /// Chave do ícone, resolvida em `CategoryVisuals` (camada de apresentação).
  final String iconKey;

  /// Chave da cor, resolvida em `AppColors.categoryPalette`.
  final String colorKey;

  /// Categorias padrão (semeadas no primeiro acesso) não podem ser excluídas,
  /// para que tarefas e assuntos antigos nunca fiquem sem categoria.
  final bool isDefault;

  @override
  List<Object?> get props => [id, label, iconKey, colorKey, isDefault];
}
