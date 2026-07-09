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
