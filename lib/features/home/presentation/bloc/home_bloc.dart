import 'dart:io';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/errors/failures.dart';
import '../../../../services/image_upload_service.dart';
import '../../data/models/care_recipient_type.dart';
import '../../data/models/caregiver_model.dart';
import '../../data/models/care_recipient_model.dart';
import '../../data/repositories/home_repository.dart';

part 'home_event.dart';
part 'home_state.dart';

class HomeBloc extends Bloc<HomeEvent, HomeState> {
  HomeBloc({
    required HomeRepository repository,
    ImageUploadService? imageUploadService,
  })  : _repository = repository,
        _imageUploadService = imageUploadService ?? ImageUploadService(),
        super(const HomeState()) {
    on<HomeLoadEvent>(_onLoad);
    on<HomeSelectProfileEvent>(_onSelectProfile);
    on<HomeAddProfileEvent>(_onAddProfile);
    on<HomeDeleteProfileEvent>(_onDeleteProfile);
  }

  final HomeRepository _repository;
  final ImageUploadService _imageUploadService;

  /// Extracts user-friendly error message from any exception.
  /// Prioritizes RepositoryFailure messages over generic error strings.
  String _extractErrorMessage(Object error) {
    if (error is RepositoryFailure) {
      return error.message;
    }
    return error.toString();
  }

  Future<void> _onLoad(
    HomeLoadEvent event,
    Emitter<HomeState> emit,
  ) async {
    emit(state.copyWith(status: HomeStatus.loading));
    try {
      final caregiver = await _repository.fetchCaregiver();
      final profiles = await _repository.fetchCareRecipients();
      emit(state.copyWith(
        status: HomeStatus.success,
        caregiver: caregiver,
        profiles: profiles,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: HomeStatus.failure,
        errorMessage: _extractErrorMessage(e),
      ));
    }
  }

  void _onSelectProfile(
    HomeSelectProfileEvent event,
    Emitter<HomeState> emit,
  ) {
    emit(state.copyWith(selectedProfileId: event.profileId));
  }

  Future<void> _onAddProfile(
    HomeAddProfileEvent event,
    Emitter<HomeState> emit,
  ) async {
    emit(state.copyWith(isAddingProfile: true, addProfileError: null));
    try {
      // Encode image as base64 if provided.
      String? photoBase64;
      if (event.imageFile != null) {
        photoBase64 = await _imageUploadService.fileToBase64(event.imageFile!);
      }

      final newProfile = await _repository.addCareRecipient(
        name: event.name,
        recipientType: event.recipientType,
        dateOfBirth: event.dateOfBirth,
        photoBase64: photoBase64,
      );
      final updatedProfiles = List<CareRecipientModel>.from(state.profiles)
        ..add(newProfile);
      emit(state.copyWith(
        profiles: updatedProfiles,
        isAddingProfile: false,
        addProfileSuccess: true,
      ));
      
      // Reset success flag after a short delay to allow UI to react
      await Future.delayed(const Duration(milliseconds: 500));
      emit(state.copyWith(addProfileSuccess: false));
    } catch (e) {
      emit(state.copyWith(
        isAddingProfile: false,
        addProfileError: _extractErrorMessage(e),
      ));
    }
  }

  Future<void> _onDeleteProfile(
    HomeDeleteProfileEvent event,
    Emitter<HomeState> emit,
  ) async {
    emit(state.copyWith(isDeletingProfile: true, deleteProfileError: null));
    try {
      await _repository.deleteProfile(event.profileId);
      final updatedProfiles = state.profiles
          .where((p) => p.id != event.profileId)
          .toList();
      emit(state.copyWith(
        profiles: updatedProfiles,
        isDeletingProfile: false,
        deleteProfileSuccess: true,
      ));
    } catch (e) {
      emit(state.copyWith(
        isDeletingProfile: false,
        deleteProfileError: _extractErrorMessage(e),
      ));
    }
  }
}
