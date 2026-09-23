/*
 * CareHub Plus — Apresentação / Visual de Categoria
 *
 * Traduz as chaves Dart-puro da entidade (`iconKey`/`colorKey`) para
 * `IconData`/`Color` do Flutter. Fica na apresentação — e não no domínio —
 * pela mesma razão de `AssistantProfile`: ícone e cor são decisões visuais.
 * O conjunto de opções é fechado de propósito: a cuidadora escolhe de uma
 * paleta pronta (`AppColors.categoryPalette`) em vez de informar um hex livre,
 * então nenhuma categoria nova pode fugir do design system.
 *
 * Author: Vitoria Lana
 * Created on: 23/08/2026
 * Version: 1.0.0
 * Squad: CareHub Plus
 */

import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/care_category_entity.dart';

/// Ícones selecionáveis ao criar ou editar uma categoria.
///
/// Mapa e não enum: novas chaves não exigem recompilar o domínio, só este
/// arquivo de apresentação.
const Map<String, IconData> categoryIcons = {
  'health': Icons.health_and_safety_outlined,
  'food': Icons.restaurant_outlined,
  'medication': Icons.medication_outlined,
  'appointment': Icons.calendar_today_outlined,
  'activity': Icons.fitness_center_outlined,
  'hygiene': Icons.bathtub_outlined,
  'sleep': Icons.bedtime_outlined,
  'transport': Icons.directions_car_outlined,
  'other': Icons.task_outlined,
};

/// Resolve o [IconData] de uma categoria, com fallback seguro.
IconData iconForCategory(CareCategoryEntity category) =>
    categoryIcons[category.iconKey] ?? categoryIcons['other']!;

/// Resolve a [Color] de uma categoria, com fallback seguro.
Color colorForCategory(CareCategoryEntity category) =>
    AppColors.categoryPalette[category.colorKey] ?? AppColors.categoryGrey;
