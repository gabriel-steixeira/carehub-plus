/*
 * CareHub Plus — Apresentação / BLoC "Ativar Cora no WhatsApp"
 *
 * Pede ao backend um código de 10 minutos para a dona ligar o próprio
 * WhatsApp à conta. Abrir o WhatsApp é efeito de interface e fica com a
 * tela; o BLoC só entrega o link pronto.
 *
 * Author: Vitoria Lana
 * Created on: 06/10/2026
 * Version: 1.0.0
 * Squad: CareHub Plus
 */

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/errors/app_exception.dart';
import '../../data/repositories/invites_repository.dart';
import '../../domain/entities/whatsapp_link_entity.dart';

enum WhatsAppLinkStatus { initial, loading, ready, failure }

abstract class WhatsAppLinkEvent extends Equatable {
  const WhatsAppLinkEvent();

  @override
  List<Object?> get props => [];
}

/// A dona tocou em "Ativar Cora no WhatsApp".
class WhatsAppLinkRequestedEvent extends WhatsAppLinkEvent {
  const WhatsAppLinkRequestedEvent();
}

class WhatsAppLinkState extends Equatable {
  const WhatsAppLinkState({
    this.status = WhatsAppLinkStatus.initial,
    this.link,
    this.errorMessage,
  });

  final WhatsAppLinkStatus status;
  final WhatsAppLinkEntity? link;
  final String? errorMessage;

  @override
  List<Object?> get props => [status, link, errorMessage];
}

class WhatsAppLinkBloc extends Bloc<WhatsAppLinkEvent, WhatsAppLinkState> {
  WhatsAppLinkBloc({required InvitesRepository repository})
    : _repository = repository,
      super(const WhatsAppLinkState()) {
    on<WhatsAppLinkRequestedEvent>(_onRequested);
  }

  final InvitesRepository _repository;

  Future<void> _onRequested(
    WhatsAppLinkRequestedEvent event,
    Emitter<WhatsAppLinkState> emit,
  ) async {
    emit(const WhatsAppLinkState(status: WhatsAppLinkStatus.loading));
    try {
      final link = await _repository.createSelfLinkCode();
      emit(WhatsAppLinkState(status: WhatsAppLinkStatus.ready, link: link));
    } on AppException catch (error) {
      emit(
        WhatsAppLinkState(
          status: WhatsAppLinkStatus.failure,
          errorMessage: error.message,
        ),
      );
    }
  }
}
