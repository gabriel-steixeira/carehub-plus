part of 'home_bloc.dart';

abstract class HomeEvent extends Equatable {
  const HomeEvent();

  @override
  List<Object?> get props => [];
}

class HomeLoadEvent extends HomeEvent {
  const HomeLoadEvent();
}

class HomeSelectProfileEvent extends HomeEvent {
  const HomeSelectProfileEvent({required this.profileId});

  final String profileId;

  @override
  List<Object?> get props => [profileId];
}

class HomeAddProfileEvent extends HomeEvent {
  const HomeAddProfileEvent({
    required this.name,
    required this.recipientType,
    this.dateOfBirth,
    this.imageFile,
  });

  final String name;
  final CareRecipientType recipientType;
  final DateTime? dateOfBirth;
  final File? imageFile;

  @override
  List<Object?> get props => [name, recipientType, dateOfBirth, imageFile];
}

class HomeDeleteProfileEvent extends HomeEvent {
  const HomeDeleteProfileEvent({required this.profileId});

  final String profileId;

  @override
  List<Object?> get props => [profileId];
}
