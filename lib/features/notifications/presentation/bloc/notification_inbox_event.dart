part of 'notification_inbox_bloc.dart';

abstract class NotificationInboxEvent extends Equatable {
  const NotificationInboxEvent();

  @override
  List<Object?> get props => [];
}

/// Começa a seguir a conta logada (ou refaz a escuta depois de um erro).
class NotificationInboxStartedEvent extends NotificationInboxEvent {
  const NotificationInboxStartedEvent();
}

/// A conta logada mudou. Evento interno do BLoC.
class NotificationInboxUserChangedEvent extends NotificationInboxEvent {
  const NotificationInboxUserChangedEvent({required this.uid});

  final String? uid;

  @override
  List<Object?> get props => [uid];
}

/// Nova lista lida do Firestore. Evento interno do BLoC.
class NotificationInboxUpdatedEvent extends NotificationInboxEvent {
  const NotificationInboxUpdatedEvent({required this.items});

  final List<AppNotificationEntity> items;

  @override
  List<Object?> get props => [items];
}

/// A escuta falhou. Evento interno do BLoC.
class NotificationInboxFailedEvent extends NotificationInboxEvent {
  const NotificationInboxFailedEvent({required this.message});

  final String message;

  @override
  List<Object?> get props => [message];
}

/// A pessoa abriu um aviso.
class NotificationInboxMarkAsReadEvent extends NotificationInboxEvent {
  const NotificationInboxMarkAsReadEvent({required this.notificationId});

  final String notificationId;

  @override
  List<Object?> get props => [notificationId];
}

/// "Marcar todas como lidas".
class NotificationInboxMarkAllAsReadEvent extends NotificationInboxEvent {
  const NotificationInboxMarkAllAsReadEvent();
}
