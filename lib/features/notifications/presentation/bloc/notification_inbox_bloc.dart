/*
 * CareHub Plus — Notificações / BLoC da caixa de notificações
 *
 * Vive na raiz do app (um só para todas as telas): segue a conta logada,
 * troca a escuta do Firestore quando alguém entra ou sai e expõe a lista e a
 * contagem de não lidas. O sino do `AppHeader` e a tela de notificações leem
 * daqui, então os dois nunca ficam diferentes.
 *
 * Author: Vitoria Lana
 * Created on: 03/10/2026
 * Version: 1.0.0
 * Squad: CareHub Plus
 */

import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/errors/app_exception.dart';
import '../../data/repositories/notification_inbox_repository.dart';
import '../../domain/entities/app_notification_entity.dart';

part 'notification_inbox_event.dart';
part 'notification_inbox_state.dart';

class NotificationInboxBloc
    extends Bloc<NotificationInboxEvent, NotificationInboxState> {
  NotificationInboxBloc({required NotificationInboxRepository repository})
    : _repository = repository,
      super(const NotificationInboxState()) {
    on<NotificationInboxStartedEvent>(_onStarted);
    on<NotificationInboxUserChangedEvent>(_onUserChanged);
    on<NotificationInboxUpdatedEvent>(_onUpdated);
    on<NotificationInboxFailedEvent>(_onFailed);
    on<NotificationInboxMarkAsReadEvent>(_onMarkAsRead);
    on<NotificationInboxMarkAllAsReadEvent>(_onMarkAllAsRead);
  }

  final NotificationInboxRepository _repository;

  StreamSubscription<String?>? _userSubscription;
  StreamSubscription<List<AppNotificationEntity>>? _inboxSubscription;

  @override
  Future<void> close() async {
    await _userSubscription?.cancel();
    await _inboxSubscription?.cancel();
    return super.close();
  }

  /// Passa a seguir a conta logada. Chamado de novo, refaz a escuta (usado
  /// pelo "Tentar novamente" depois de um erro).
  Future<void> _onStarted(
    NotificationInboxStartedEvent event,
    Emitter<NotificationInboxState> emit,
  ) async {
    await _userSubscription?.cancel();
    _userSubscription = _repository.watchUserId().listen(
      (uid) => add(NotificationInboxUserChangedEvent(uid: uid)),
    );
  }

  Future<void> _onUserChanged(
    NotificationInboxUserChangedEvent event,
    Emitter<NotificationInboxState> emit,
  ) async {
    // Troca de conta: a escuta anterior não pode vazar avisos de outra pessoa.
    await _inboxSubscription?.cancel();
    _inboxSubscription = null;

    final uid = event.uid;
    if (uid == null) {
      emit(const NotificationInboxState());
      return;
    }

    emit(
      NotificationInboxState(status: NotificationInboxStatus.loading, uid: uid),
    );
    _inboxSubscription = _repository
        .watchInbox(uid)
        .listen(
          (items) => add(NotificationInboxUpdatedEvent(items: items)),
          onError: (Object error) => add(
            NotificationInboxFailedEvent(
              message: error is AppException
                  ? error.message
                  : 'Não foi possível carregar suas notificações.',
            ),
          ),
        );
  }

  void _onUpdated(
    NotificationInboxUpdatedEvent event,
    Emitter<NotificationInboxState> emit,
  ) {
    emit(
      state.copyWith(
        status: NotificationInboxStatus.ready,
        items: event.items,
        clearErrorMessage: true,
      ),
    );
  }

  void _onFailed(
    NotificationInboxFailedEvent event,
    Emitter<NotificationInboxState> emit,
  ) {
    emit(
      state.copyWith(
        status: NotificationInboxStatus.failure,
        errorMessage: event.message,
      ),
    );
  }

  Future<void> _onMarkAsRead(
    NotificationInboxMarkAsReadEvent event,
    Emitter<NotificationInboxState> emit,
  ) async {
    final isUnread = state.items.any(
      (item) => item.id == event.notificationId && item.isUnread,
    );
    if (!isUnread) return;
    await _markAsRead([event.notificationId], emit);
  }

  Future<void> _onMarkAllAsRead(
    NotificationInboxMarkAllAsReadEvent event,
    Emitter<NotificationInboxState> emit,
  ) async {
    final unreadIds = state.items
        .where((item) => item.isUnread)
        .map((item) => item.id)
        .toList();
    await _markAsRead(unreadIds, emit);
  }

  /// A lista se corrige sozinha pela escuta; aqui só se trata a falha.
  Future<void> _markAsRead(
    List<String> ids,
    Emitter<NotificationInboxState> emit,
  ) async {
    try {
      await _repository.markAsRead(ids);
    } on AppException catch (e) {
      emit(state.copyWith(errorMessage: e.message));
    }
  }
}
