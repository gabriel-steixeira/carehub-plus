part of 'care_categories_bloc.dart';

enum CareCategoriesStatus { initial, loading, success, failure }

class CareCategoriesState extends Equatable {
  const CareCategoriesState({
    this.status = CareCategoriesStatus.initial,
    this.categories = const [],
    this.isMutating = false,
    this.errorMessage,
  });

  final CareCategoriesStatus status;
  final List<CareCategoryEntity> categories;

  /// `true` enquanto uma criação/exclusão está em andamento — desabilita os
  /// botões correspondentes sem esconder a lista já carregada.
  final bool isMutating;
  final String? errorMessage;

  CareCategoriesState copyWith({
    CareCategoriesStatus? status,
    List<CareCategoryEntity>? categories,
    bool? isMutating,
    String? errorMessage,
  }) {
    return CareCategoriesState(
      status: status ?? this.status,
      categories: categories ?? this.categories,
      isMutating: isMutating ?? this.isMutating,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, categories, isMutating, errorMessage];
}
