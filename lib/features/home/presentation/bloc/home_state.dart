part of 'home_bloc.dart';

enum HomeStatus { initial, loading, success, failure }

class HomeState extends Equatable {
  const HomeState({
    this.status = HomeStatus.initial,
    this.caregiver,
    this.profiles = const [],
    this.selectedProfileId,
    this.errorMessage,
  });

  final HomeStatus status;
  final CaregiverModel? caregiver;
  final List<CareRecipientModel> profiles;
  final String? selectedProfileId;
  final String? errorMessage;

  HomeState copyWith({
    HomeStatus? status,
    CaregiverModel? caregiver,
    List<CareRecipientModel>? profiles,
    String? selectedProfileId,
    String? errorMessage,
  }) {
    return HomeState(
      status: status ?? this.status,
      caregiver: caregiver ?? this.caregiver,
      profiles: profiles ?? this.profiles,
      selectedProfileId: selectedProfileId ?? this.selectedProfileId,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [
        status,
        caregiver,
        profiles,
        selectedProfileId,
        errorMessage,
      ];
}
