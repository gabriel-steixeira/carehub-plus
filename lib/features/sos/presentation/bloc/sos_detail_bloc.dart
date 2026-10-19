/*
 * CareHub Plus — SOS / BLoC do detalhe do pedido
 *
 * Coordena a tela aberta ao tocar na notificação de SOS: carrega os detalhes
 * do pedido (`fetchAlertDetail`) e processa o aceite ("Estou a caminho"),
 * delegando ao repositório a chamada ao backend. A tela só desenha o estado e
 * avisa a intenção; nenhuma regra de negócio ou acesso ao Firebase vive aqui.
 *
 * Author: Vitoria Lana
 * Created on: 18/10/2026
 * Version: 1.0.0
 * Squad: CareHub Plus
 */

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/errors/app_exception.dart';
import '../../data/repositories/sos_repository.dart';
import '../../domain/entities/sos_alert_detail_entity.dart';

part 'sos_detail_event.dart';
part 'sos_detail_state.dart';

class SosDetailBloc extends Bloc<SosDetailEvent, SosDetailState> {
  SosDetailBloc({required SosRepository repository})
    : _repository = repository,
      super(const SosDetailState()) {
    on<SosDetailLoadRequested>(_onLoad);
    on<SosDetailAcceptRequested>(_onAccept);
  }

  final SosRepository _repository;

  /// Alerta carregado, guardado para o aceite não depender da tela.
  String? _alertId;

  Future<void> _onLoad(
    SosDetailLoadRequested event,
    Emitter<SosDetailState> emit,
  ) async {
    _alertId = event.alertId;
    emit(
      state.copyWith(status: SosDetailStatus.loading, clearErrorMessage: true),
    );
    try {
      final detail = await _repository.fetchAlertDetail(event.alertId);
      emit(state.copyWith(status: SosDetailStatus.success, detail: detail));
    } on AppException catch (e) {
      emit(
        state.copyWith(
          status: SosDetailStatus.failure,
          errorMessage: e.message,
        ),
      );
    }
  }

  Future<void> _onAccept(
    SosDetailAcceptRequested event,
    Emitter<SosDetailState> emit,
  ) async {
    final alertId = _alertId;
    if (alertId == null) return;

    // Mantém o detalhe já carregado enquanto envia o aceite, para a tela não
    // "piscar" uma tela de carregamento vazia.
    emit(
      state.copyWith(
        status: SosDetailStatus.accepting,
        clearErrorMessage: true,
      ),
    );
    try {
      await _repository.acceptAlert(alertId);
      // Recarrega o detalhe para refletir o novo status e quem aceitou.
      final detail = await _repository.fetchAlertDetail(alertId);
      emit(state.copyWith(status: SosDetailStatus.accepted, detail: detail));
    } on AppException catch (e) {
      emit(
        state.copyWith(
          status: SosDetailStatus.failure,
          errorMessage: e.message,
        ),
      );
    }
  }
}
