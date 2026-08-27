/*
 * CareHub Plus — Domínio / Perfil do Cuidador
 *
 * Dados cadastrais do cuidador autenticado (o dono da conta), usados na tela
 * de edição de perfil. É Dart puro: não conhece Firestore nem Flutter, então
 * a mesma entidade serve para a tela, para o BLoC e para os testes.
 *
 * Nome e e-mail são obrigatórios porque vêm do login. Telefone, nascimento,
 * gênero e foto são opcionais: uma conta nova simplesmente não tem esses
 * dados ainda, e a tela precisa saber a diferença entre "vazio" e "zero".
 *
 * Author: Vitoria Lana
 * Created on: 25/08/2026
 * Version: 1.0.0
 * Squad: CareHub Plus
 */

import 'package:equatable/equatable.dart';

import 'caregiver_gender.dart';

/// Perfil cadastral do cuidador logado.
class CaregiverProfileEntity extends Equatable {
  const CaregiverProfileEntity({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
    this.birthDate,
    this.gender,
    this.photoUrl,
    this.photoBase64,
  });

  /// UID da conta no Firebase Auth.
  final String id;

  /// Nome completo exibido no app.
  final String name;

  /// E-mail de contato.
  final String email;

  /// Telefone de contato. `null` quando nunca foi informado.
  final String? phone;

  /// Data de nascimento. `null` quando nunca foi informada.
  final DateTime? birthDate;

  /// Gênero informado. `null` quando nunca foi informado.
  final CaregiverGender? gender;

  /// Foto de perfil (URL). `null` quando a conta não tem foto — nesse caso a
  /// interface mostra o avatar genérico, nunca uma foto de outra pessoa.
  final String? photoUrl;

  /// Foto de perfil em base64. Alternativa local ao Storage.
  final String? photoBase64;

  /// `true` quando há foto para exibir (URL ou base64).
  bool get hasPhoto =>
      (photoUrl != null && photoUrl!.isNotEmpty) || photoBase64 != null;

  /// Cópia com os campos editáveis substituídos.
  ///
  /// Os opcionais são intencionalmente sobrescritos mesmo quando vêm `null`:
  /// limpar o telefone ou o gênero é uma edição válida, e um `??` silencioso
  /// faria a tela "esquecer" de apagar o dado.
  CaregiverProfileEntity copyWithEditableFields({
    required String name,
    required String email,
    required String? phone,
    required DateTime? birthDate,
    required CaregiverGender? gender,
    String? photoBase64,
  }) {
    return CaregiverProfileEntity(
      id: id,
      name: name,
      email: email,
      phone: phone,
      birthDate: birthDate,
      gender: gender,
      photoUrl: photoUrl,
      photoBase64: photoBase64 ?? this.photoBase64,
    );
  }

  @override
  List<Object?> get props => [
    id,
    name,
    email,
    phone,
    birthDate,
    gender,
    photoUrl,
    photoBase64,
  ];
}
