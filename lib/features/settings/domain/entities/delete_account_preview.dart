/*
 * CareHub Plus — Domínio / Prévia da exclusão de conta
 *
 * Descreve o impacto de excluir a conta antes de confirmar: qual é o caso de
 * exclusão e, quando a dona tem perfis compartilhados com outras cuidadoras,
 * quem seria afetado. Dart puro para a UI escolher a mensagem certa sem
 * tocar no backend.
 *
 * Author: Vitoria Lana
 * Created on: 15/10/2026
 * Version: 1.0.0
 * Squad: CareHub Plus
 */

import 'package:equatable/equatable.dart';

/// Caso de exclusão resolvido antes de confirmar.
///
/// - [soloOrGrantee]: a conta não é dona de nenhum perfil compartilhado
///   (só os próprios dados saem) ou só participa de perfis de terceiros.
/// - [ownerNoOthers]: a conta é dona de perfis, mas ninguém mais os acessa —
///   tudo relacionado será excluído.
/// - [ownerWithOthers]: a conta é dona de perfis que outras cuidadoras
///   acessam — excluir a conta remove também o acesso dessas pessoas.
enum DeletionCase { soloOrGrantee, ownerNoOthers, ownerWithOthers }

/// Resultado da análise que a tela usa para montar o aviso.
class DeleteAccountPreview extends Equatable {
  const DeleteAccountPreview({
    required this.deletionCase,
    this.affectedNames = const [],
  });

  /// Qual cenário de exclusão se aplica à conta.
  final DeletionCase deletionCase;

  /// Nomes das pessoas que perderiam o acesso (apenas em [ownerWithOthers]).
  final List<String> affectedNames;

  @override
  List<Object?> get props => [deletionCase, affectedNames];
}
