part of 'home_bloc.dart';

enum HomeStatus { initial, loading, success, failure }

class HomeState extends Equatable {
  const HomeState({
    this.status = HomeStatus.initial,
    this.caregiver,
    this.profiles = const [],
    this.selectedProfileId,
    this.errorMessage,
    this.isAddingProfile = false,
    this.addProfileSuccess = false,
    this.addProfileError,
    this.isDeletingProfile = false,
    this.deleteProfileSuccess = false,
    this.deleteProfileError,
  });

  final HomeStatus status;
  final CaregiverModel? caregiver;
  final List<CareRecipientModel> profiles;
  final String? selectedProfileId;
  final String? errorMessage;

  // Add profile sub-state
  final bool isAddingProfile;
  final bool addProfileSuccess;
  final String? addProfileError;

  // Delete profile sub-state
  final bool isDeletingProfile;
  final bool deleteProfileSuccess;
  final String? deleteProfileError;

  HomeState copyWith({
    HomeStatus? status,
    CaregiverModel? caregiver,
    List<CareRecipientModel>? profiles,
    String? selectedProfileId,
    String? errorMessage,
    bool? isAddingProfile,
    bool? addProfileSuccess,
    String? addProfileError,
    bool? isDeletingProfile,
    bool? deleteProfileSuccess,
    String? deleteProfileError,
  }) {
    return HomeState(
      status: status ?? this.status,
      caregiver: caregiver ?? this.caregiver,
      profiles: profiles ?? this.profiles,
      selectedProfileId: selectedProfileId ?? this.selectedProfileId,
      errorMessage: errorMessage ?? this.errorMessage,
      isAddingProfile: isAddingProfile ?? this.isAddingProfile,
      addProfileSuccess: addProfileSuccess ?? this.addProfileSuccess,
      addProfileError: addProfileError ?? this.addProfileError,
      isDeletingProfile: isDeletingProfile ?? this.isDeletingProfile,
      deleteProfileSuccess: deleteProfileSuccess ?? this.deleteProfileSuccess,
      deleteProfileError: deleteProfileError ?? this.deleteProfileError,
    );
  }

  @override
  List<Object?> get props => [
        status,
        caregiver,
        profiles,
        selectedProfileId,
        errorMessage,
        isAddingProfile,
        addProfileSuccess,
        addProfileError,
        isDeletingProfile,
        deleteProfileSuccess,
        deleteProfileError,
      ];
}
