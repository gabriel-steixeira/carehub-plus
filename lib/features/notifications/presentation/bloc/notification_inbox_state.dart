part of 'notification_inbox_bloc.dart';

/// Situação da caixa. `initial` também significa "ninguém logado".
enum NotificationInboxStatus { initial, loading, ready, failure }

class NotificationInboxState extends Equatable {
  const NotificationInboxState({
    this.status = NotificationInboxStatus.initial,
    this.uid,
    this.items = const [],
    this.errorMessage,
  });

  final NotificationInboxStatus status;

  /// Conta cujos avisos estão carregados. `null` quando ninguém está logado.
  final String? uid;
  final List<AppNotificationEntity> items;
  final String? errorMessage;

  bool get isSignedIn => uid != null;

  int get unreadCount => items.where((item) => item.isUnread).length;

  NotificationInboxState copyWith({
    NotificationInboxStatus? status,
    List<AppNotificationEntity>? items,
    String? errorMessage,
    bool clearErrorMessage = false,
  }) {
    return NotificationInboxState(
      status: status ?? this.status,
      uid: uid,
      items: items ?? this.items,
      errorMessage: clearErrorMessage
          ? null
          : errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, uid, items, errorMessage];
}
