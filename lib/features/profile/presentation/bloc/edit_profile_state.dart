part of 'edit_profile_bloc.dart';

/// Estado do carregamento inicial da tela.
enum EditProfileStatus { initial, loading, success, failure }

/// Estado da gravação do formulário, independente do carregamento.
enum EditProfileSaveStatus { idle, saving, success, failure }

class EditProfileState extends Equatable {
  const EditProfileState({
    this.status = EditProfileStatus.initial,
    this.saveStatus = EditProfileSaveStatus.idle,
    this.profile,
    this.plan,
    this.contractedSubscription,
    this.errorMessage,
  });

  final EditProfileStatus status;
  final EditProfileSaveStatus saveStatus;
  final CaregiverProfileEntity? profile;
  final SubscriptionPlanEntity? plan;
  final ContractedSubscriptionEntity? contractedSubscription;
  final String? errorMessage;

  /// `true` enquanto a gravação está em andamento — o botão Salvar mostra
  /// carregamento e não aceita um segundo toque.
  bool get isSaving => saveStatus == EditProfileSaveStatus.saving;

  EditProfileState copyWith({
    EditProfileStatus? status,
    EditProfileSaveStatus? saveStatus,
    CaregiverProfileEntity? profile,
    SubscriptionPlanEntity? plan,
    ContractedSubscriptionEntity? contractedSubscription,
    String? errorMessage,
  }) {
    return EditProfileState(
      status: status ?? this.status,
      saveStatus: saveStatus ?? this.saveStatus,
      profile: profile ?? this.profile,
      plan: plan ?? this.plan,
      contractedSubscription:
          contractedSubscription ?? this.contractedSubscription,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [
    status,
    saveStatus,
    profile,
    plan,
    contractedSubscription,
    errorMessage,
  ];
}
