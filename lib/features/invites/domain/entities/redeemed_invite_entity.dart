/*
 * CareHub Plus — Domínio / Convite aceito
 *
 * Assistido que passou a ser compartilhado com a conta logada depois de um
 * convite aceito (pelo código ou pelo e-mail verificado).
 *
 * Author: Vitoria Lana
 * Created on: 06/10/2026
 * Version: 1.0.0
 * Squad: CareHub Plus
 */

import 'package:equatable/equatable.dart';

/// Acesso liberado por um convite.
class RedeemedInviteEntity extends Equatable {
  const RedeemedInviteEntity({
    required this.careRecipientId,
    required this.careRecipientName,
  });

  final String careRecipientId;
  final String careRecipientName;

  /// Primeiro nome, para mensagens curtas ("Agora você acompanha Lúcia").
  String get firstName {
    final name = careRecipientName.trim();
    return name.isEmpty ? 'o assistido' : name.split(' ').first;
  }

  @override
  List<Object?> get props => [careRecipientId, careRecipientName];
}
