/*
 * CareHub Plus — Apresentação / BLoC Sobre
 *
 * Coordena o carregamento do conteúdo institucional e expõe estados simples
 * para a página renderizar carregamento, erro e conteúdo disponível.
 *
 * Author: Vitoria Lana
 * Created on: 27/08/2026
 * Version: 1.0.0
 * Squad: CareHub Plus
 */

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/errors/app_exception.dart';
import '../../data/repositories/about_repository.dart';
import '../../domain/entities/about_content_entity.dart';

part 'about_event.dart';
part 'about_state.dart';

class AboutBloc extends Bloc<AboutEvent, AboutState> {
  AboutBloc({required AboutRepository repository})
    : _repository = repository,
      super(const AboutState()) {
    on<AboutLoadEvent>(_onLoad);
  }

  final AboutRepository _repository;

  Future<void> _onLoad(AboutLoadEvent event, Emitter<AboutState> emit) async {
    emit(state.copyWith(status: AboutStatus.loading, errorMessage: null));

    try {
      final content = await _repository.fetchContent();
      emit(
        state.copyWith(
          status: AboutStatus.success,
          content: content,
          errorMessage: null,
        ),
      );
    } on AppException catch (error) {
      emit(
        state.copyWith(
          status: AboutStatus.failure,
          errorMessage: error.message,
        ),
      );
    }
  }
}
