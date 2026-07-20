import 'package:flutter/material.dart';

import '../models/emergency_contact_model.dart';
import '../models/sos_protocol_model.dart';

/// Repository for SOS emergency actions and protocols.
class SosRepository {
  final List<EmergencyContactModel> _contacts = const [
    EmergencyContactModel(
      id: 'samu',
      name: 'SAMU - Serviço de Emergência',
      phone: '192',
      relationship: 'Serviço Público de Saúde',
      isPrimary: true,
      isService: true,
    ),
    EmergencyContactModel(
      id: 'bombeiros',
      name: 'Corpo de Bombeiros',
      phone: '193',
      relationship: 'Resgate e Emergência',
      isPrimary: false,
      isService: true,
    ),
    EmergencyContactModel(
      id: 'carlos_family',
      name: 'Carlos (Filho)',
      phone: '(11) 99887-6655',
      relationship: 'Contato Familiar Principal',
      isPrimary: true,
      isService: false,
    ),
    EmergencyContactModel(
      id: 'dr_roberto',
      name: 'Dr. Roberto (Cardiologista)',
      phone: '(11) 91234-5678',
      relationship: 'Médico Responsável',
      isPrimary: false,
      isService: false,
    ),
  ];

  final List<SosProtocolModel> _protocols = const [
    SosProtocolModel(
      id: 'proto_fall',
      title: 'Quedas e Impacto',
      description: 'Como agir caso o idoso ou assistido sofra uma queda.',
      icon: Icons.personal_injury_outlined,
      steps: [
        '1. Não mova a pessoa imediatamente. Verifique se há dor de cabeça ou no pescoço.',
        '2. Pergunte se há tontura ou perda de consciência.',
        '3. Se houver suspeita de fratura, mantenha a pessoa imóvel e chame o SAMU (192).',
        '4. Caso esteja consciente e sem dores agudas, ajude a sentar devagar.',
      ],
    ),
    SosProtocolModel(
      id: 'proto_heart',
      title: 'Suspeita de Infarto',
      description: 'Sinais de dor no peito ou falta de ar aguda.',
      icon: Icons.favorite_border_rounded,
      steps: [
        '1. Mantenha a pessoa sentada e calma em local arejado.',
        '2. Afrouxe roupas apertadas na região do pescoço e tórax.',
        '3. Ligue imediatamente para o SAMU (192).',
        '4. Nunca ofereça alimentos ou bebidas durante o atendimento.',
      ],
    ),
    SosProtocolModel(
      id: 'proto_choking',
      title: 'Engasgo e Obstrução',
      description: 'Manobra de desobstrução de vias aéreas.',
      icon: Icons.air_outlined,
      steps: [
        '1. Incline a pessoa levemente para a frente.',
        '2. Aplique até 5 pancadas firmes nas costas entre as escápulas.',
        '3. Se persistir, posicionar-se atrás e realizar compressões abdominais (Manobra de Heimlich).',
        '4. Ligue para o SAMU (192) se a obstrução persistir.',
      ],
    ),
  ];

  Future<List<EmergencyContactModel>> fetchContacts() async {
    await Future.delayed(const Duration(milliseconds: 300));
    return _contacts;
  }

  Future<List<SosProtocolModel>> fetchProtocols() async {
    await Future.delayed(const Duration(milliseconds: 300));
    return _protocols;
  }

  Future<bool> triggerEmergencyAlert({required String location}) async {
    // Simulates sending an urgent SMS / push alert to all network members
    await Future.delayed(const Duration(milliseconds: 1000));
    return true;
  }
}
