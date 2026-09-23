part of 'notifications_bloc.dart';

enum NotificationsStatus { initial, loading, success, failure }

class NotificationsState extends Equatable {
  const NotificationsState({
    this.status = NotificationsStatus.initial,
    this.preferences,
    this.caregiverPhotoUrl,
    this.errorMessage,
  });

  final NotificationsStatus status;

  /// `null` enquanto o primeiro carregamento não terminou.
  final NotificationPreferencesEntity? preferences;

  /// Foto do cuidador exibida no `AppHeader`. `null` mostra o avatar genérico.
  final String? caregiverPhotoUrl;

  final String? errorMessage;

  /// [clearErrorMessage] existe porque `errorMessage ?? this.errorMessage`
  /// nunca conseguiria voltar o campo para `null`: sem isso, um erro antigo
  /// ficaria preso no estado e reapareceria no próximo toque.
  NotificationsState copyWith({
    NotificationsStatus? status,
    NotificationPreferencesEntity? preferences,
    String? caregiverPhotoUrl,
    String? errorMessage,
    bool clearErrorMessage = false,
  }) {
    return NotificationsState(
      status: status ?? this.status,
      preferences: preferences ?? this.preferences,
      caregiverPhotoUrl: caregiverPhotoUrl ?? this.caregiverPhotoUrl,
      errorMessage:
          clearErrorMessage ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => [
        status,
        preferences,
        caregiverPhotoUrl,
        errorMessage,
      ];
}
