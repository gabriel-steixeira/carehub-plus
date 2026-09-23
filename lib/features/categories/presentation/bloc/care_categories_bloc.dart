/*
 * CareHub Plus — Apresentação / BLoC de Categorias de Cuidado
 *
 * Carrega, cria e exclui categorias compartilhadas por Tasks e Chat. Cada
 * tela cria sua própria instância deste BLoC (nunca compartilhada entre
 * features), injetando o mesmo `CareCategoriesRepository` — assim as duas
 * telas leem/escrevem a mesma coleção do Firestore sem acoplar um BLoC ao
 * outro.
 *
 * Author: Vitoria Lana
 * Created on: 23/08/2026
 * Version: 1.0.0
 * Squad: CareHub Plus
 */

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/errors/app_exception.dart';
import '../../data/repositories/care_categories_repository.dart';
import '../../domain/entities/care_category_entity.dart';

part 'care_categories_event.dart';
part 'care_categories_state.dart';

class CareCategoriesBloc
    extends Bloc<CareCategoriesEvent, CareCategoriesState> {
  CareCategoriesBloc({required CareCategoriesRepository repository})
      : _repository = repository,
        super(const CareCategoriesState()) {
    on<CareCategoriesLoadEvent>(_onLoad);
    on<CareCategoryAddEvent>(_onAdd);
    on<CareCategoryDeleteEvent>(_onDelete);
  }

  final CareCategoriesRepository _repository;

  Future<void> _onLoad(
    CareCategoriesLoadEvent event,
    Emitter<CareCategoriesState> emit,
  ) async {
    emit(state.copyWith(status: CareCategoriesStatus.loading));
    try {
      final categories = await _repository.fetchCategories();
      emit(state.copyWith(
        status: CareCategoriesStatus.success,
        // Conversão explícita: o repositório devolve `List<CareCategoryModel>`,
        // mas os generics do Dart são reificados (o tipo real da lista viaja
        // com o objeto, mesmo depois de atribuído a uma variável declarada
        // como `List<CareCategoryEntity>`). Sem este `List<CareCategoryEntity>.of`,
        // a lista guardada no estado continua sendo, por dentro, uma lista de
        // `CareCategoryModel` — e telas que chamam `firstWhere(orElse: () =>
        // CareCategoryEntity(...))` quebram em tempo de execução, porque o
        // Dart exige que o `orElse` devolva o tipo real da lista.
        categories: List<CareCategoryEntity>.of(categories),
      ));
    } on AppException catch (e) {
      emit(state.copyWith(
        status: CareCategoriesStatus.failure,
        errorMessage: e.message,
      ));
    }
  }

  Future<void> _onAdd(
    CareCategoryAddEvent event,
    Emitter<CareCategoriesState> emit,
  ) async {
    emit(state.copyWith(isMutating: true));
    try {
      final created = await _repository.addCategory(
        label: event.label,
        iconKey: event.iconKey,
        colorKey: event.colorKey,
      );
      emit(state.copyWith(
        categories: [...state.categories, created],
        isMutating: false,
      ));
    } on AppException catch (e) {
      emit(state.copyWith(isMutating: false, errorMessage: e.message));
    }
  }

  Future<void> _onDelete(
    CareCategoryDeleteEvent event,
    Emitter<CareCategoriesState> emit,
  ) async {
    emit(state.copyWith(isMutating: true));
    try {
      await _repository.deleteCategory(event.categoryId);
      final updated = state.categories
          .where((category) => category.id != event.categoryId)
          .toList();
      emit(state.copyWith(categories: updated, isMutating: false));
    } on AppException catch (e) {
      emit(state.copyWith(isMutating: false, errorMessage: e.message));
    }
  }
}
