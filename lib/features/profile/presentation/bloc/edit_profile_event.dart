part of 'edit_profile_bloc.dart';

abstract class EditProfileEvent extends Equatable {
  const EditProfileEvent();

  @override
  List<Object?> get props => [];
}

/// Carrega o perfil e o plano do cuidador logado.
class EditProfileLoadEvent extends EditProfileEvent {
  const EditProfileLoadEvent();
}

/// Grava os campos editados no formulário.
///
/// Os opcionais chegam `null` quando a cuidadora deixou o campo em branco —
/// isso é uma edição válida, não "não mexeu".
class EditProfileSubmitEvent extends EditProfileEvent {
  const EditProfileSubmitEvent({
    required this.name,
    required this.email,
    this.phone,
    this.birthDate,
    this.gender,
    this.photoBase64,
  });

  final String name;
  final String email;
  final String? phone;
  final DateTime? birthDate;
  final CaregiverGender? gender;
  final String? photoBase64;

  @override
  List<Object?> get props => [name, email, phone, birthDate, gender, photoBase64];
}

/// Atualiza a foto de perfil do cuidador (com um File do dispositivo).
class EditProfilePhotoChangedEvent extends EditProfileEvent {
  const EditProfilePhotoChangedEvent({required this.imageFile});

  final File imageFile;

  @override
  List<Object?> get props => [imageFile];
}
