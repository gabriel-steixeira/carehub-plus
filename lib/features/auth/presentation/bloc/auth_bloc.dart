import 'dart:io';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../services/image_upload_service.dart';
import '../../data/repositories/auth_repository.dart';

part 'auth_event.dart';
part 'auth_state.dart';

/// BLoC for authentication — handles login via email or social providers.
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  AuthBloc({
    required AuthRepository repository,
    ImageUploadService? imageUploadService,
  })  : _repository = repository,
        _imageUploadService = imageUploadService ?? ImageUploadService(),
        super(const AuthState()) {
    on<AuthLoginSubmitted>(_onLoginSubmitted);
    on<AuthGoogleSignInRequested>(_onGoogleSignIn);
    on<AuthFacebookSignInRequested>(_onFacebookSignIn);
    on<AuthSignUpSubmitted>(_onSignUpSubmitted);
    on<AuthPasswordResetRequested>(_onPasswordResetRequested);
  }

  final AuthRepository _repository;
  final ImageUploadService _imageUploadService;

  Future<void> _onPasswordResetRequested(
    AuthPasswordResetRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(state.copyWith(status: AuthStatus.loading));
    try {
      await _repository.sendPasswordResetEmail(event.email);
      emit(state.copyWith(status: AuthStatus.success));
    } catch (e) {
      emit(
        state.copyWith(status: AuthStatus.failure, errorMessage: e.toString()),
      );
    }
  }

  Future<void> _onSignUpSubmitted(
    AuthSignUpSubmitted event,
    Emitter<AuthState> emit,
  ) async {
    emit(state.copyWith(status: AuthStatus.loading));
    try {
      // Convert photo to base64 if provided.
      String? photoBase64;
      if (event.imageFile != null) {
        photoBase64 = await _imageUploadService.fileToBase64(event.imageFile!);
      }

      await _repository.signUpWithEmail(
        name: event.name,
        email: event.email,
        password: event.password,
        photoBase64: photoBase64,
      );
      emit(state.copyWith(status: AuthStatus.success));
    } catch (e) {
      emit(
        state.copyWith(status: AuthStatus.failure, errorMessage: e.toString()),
      );
    }
  }

  Future<void> _onLoginSubmitted(
    AuthLoginSubmitted event,
    Emitter<AuthState> emit,
  ) async {
    emit(state.copyWith(status: AuthStatus.loading));
    try {
      await _repository.signInWithEmail(
        email: event.email,
        password: event.password,
      );
      emit(state.copyWith(status: AuthStatus.success));
    } catch (e) {
      emit(
        state.copyWith(status: AuthStatus.failure, errorMessage: e.toString()),
      );
    }
  }

  Future<void> _onGoogleSignIn(
    AuthGoogleSignInRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(state.copyWith(status: AuthStatus.loading));
    try {
      await _repository.signInWithGoogle();
      emit(state.copyWith(status: AuthStatus.success));
    } catch (e) {
      emit(
        state.copyWith(status: AuthStatus.failure, errorMessage: e.toString()),
      );
    }
  }

  Future<void> _onFacebookSignIn(
    AuthFacebookSignInRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(state.copyWith(status: AuthStatus.loading));
    try {
      await _repository.signInWithFacebook();
      emit(state.copyWith(status: AuthStatus.success));
    } catch (e) {
      emit(
        state.copyWith(status: AuthStatus.failure, errorMessage: e.toString()),
      );
    }
  }
}
