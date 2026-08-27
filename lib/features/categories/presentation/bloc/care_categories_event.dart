part of 'care_categories_bloc.dart';

abstract class CareCategoriesEvent extends Equatable {
  const CareCategoriesEvent();

  @override
  List<Object?> get props => [];
}

/// Carrega as categorias existentes (semeia os padrões na primeira vez).
class CareCategoriesLoadEvent extends CareCategoriesEvent {
  const CareCategoriesLoadEvent();
}

/// Cria uma categoria nova, escolhida pela cuidadora.
class CareCategoryAddEvent extends CareCategoriesEvent {
  const CareCategoryAddEvent({
    required this.label,
    required this.iconKey,
    required this.colorKey,
  });

  final String label;
  final String iconKey;
  final String colorKey;

  @override
  List<Object?> get props => [label, iconKey, colorKey];
}

/// Exclui uma categoria criada pela cuidadora (nunca uma padrão).
class CareCategoryDeleteEvent extends CareCategoriesEvent {
  const CareCategoryDeleteEvent({required this.categoryId});

  final String categoryId;

  @override
  List<Object?> get props => [categoryId];
}
