/*
 * CareHub Plus — Testes / Campos de acesso do membro da rede
 *
 * Author: Vitoria Lana
 * Created on: 06/10/2026
 * Version: 1.0.0
 * Squad: CareHub Plus
 */

import 'package:carehub_plus/features/network/data/models/network_member_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

Map<String, dynamic> _json([Map<String, dynamic> extra = const {}]) => {
  'id': 'm1',
  'name': 'Bia',
  'phone': '11988887777',
  ...extra,
};

void main() {
  test('membro antigo recebe alertas pelos dois canais e não tem convite', () {
    final member = NetworkMemberModel.fromJson(_json());
    expect(member.alertChannels, AlertChannel.all);
    expect(member.inviteStatus, MemberInviteStatus.none);
    expect(member.accessDurationHours, isNull);
  });

  test('lê canal, prazo e a situação gravada pelo backend', () {
    final expires = DateTime(2026, 10, 8, 18);
    final member = NetworkMemberModel.fromJson(
      _json({
        'alertChannels': ['app', 'sms'],
        'accessDurationHours': 48,
        'inviteStatus': 'active',
        'accessExpiresAt': Timestamp.fromDate(expires),
      }),
    );
    expect(member.alertChannels, [AlertChannel.app]);
    expect(member.accessDurationHours, 48);
    expect(member.inviteStatus, MemberInviteStatus.active);
    expect(member.accessExpiresAt, expires);
  });

  test('acesso ativo com prazo vencido aparece como expirado', () {
    final member = NetworkMemberModel.fromJson(
      _json({
        'inviteStatus': 'active',
        'accessExpiresAt': Timestamp.fromDate(DateTime(2026, 10, 1)),
      }),
    );
    expect(
      member.effectiveInviteStatus(DateTime(2026, 10, 6)),
      MemberInviteStatus.expired,
    );
  });

  test('toJson grava prazo e canais, nunca os campos do backend', () {
    final json = NetworkMemberModel.fromJson(
      _json({
        'alertChannels': ['whatsapp'],
        'accessDurationHours': 24,
        'inviteStatus': 'active',
      }),
    ).toJson();
    expect(json['alertChannels'], ['whatsapp']);
    expect(json['accessDurationHours'], 24);
    expect(json.containsKey('inviteStatus'), isFalse);
    expect(json.containsKey('accessExpiresAt'), isFalse);
  });
}
