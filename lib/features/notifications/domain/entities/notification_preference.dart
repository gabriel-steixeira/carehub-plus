/*
 * CareHub Plus — Domínio / Catálogo de Preferências de Notificação
 *
 * Descreve quais alertas a cuidadora pode ligar ou desligar. O rótulo, a
 * explicação, a seção e a chave de gravação moram junto do dado, no enum: assim
 * qualquer tela que mostre uma preferência usa exatamente o mesmo texto, e a
 * apresentação não precisa conhecer o formato do Firestore.
 *
 * É Dart puro — nenhuma dependência de Flutter ou de Firebase.
 *
 * Author: Vitoria Lana
 * Created on: 25/08/2026
 * Version: 1.0.0
 * Squad: CareHub Plus
 */

/// Bloco temático que agrupa preferências na tela de Notificações.
///
/// O rótulo é guardado em caixa normal; deixar em maiúsculas é decisão de
/// apresentação, não do domínio.
enum NotificationSection {
  criticalAlerts('Alertas críticos'),
  careRoutine('Rotina de cuidados'),
  communication('Comunicação'),
  deliveryPreferences('Preferências de envio');

  const NotificationSection(this.label);

  /// Nome exibido para a cuidadora.
  final String label;
}

/// Um alerta que a cuidadora pode ligar ou desligar.
///
/// A ordem de declaração é a ordem exibida dentro de cada seção.
enum NotificationPreference {
  sosAlerts(
    storageKey: 'sosAlerts',
    section: NotificationSection.criticalAlerts,
    label: 'Alertas SOS',
    description: 'Notificações de emergência da sua rede.',
  ),
  todayTasks(
    storageKey: 'todayTasks',
    section: NotificationSection.careRoutine,
    label: 'Tarefas de Hoje',
    description: 'Lembretes de atividades agendadas.',
  ),
  upcomingTasks(
    storageKey: 'upcomingTasks',
    section: NotificationSection.careRoutine,
    label: 'Tarefas Futuras',
    description: 'Lembretes de atividades agendadas.',
  ),
  createdTasks(
    storageKey: 'createdTasks',
    section: NotificationSection.careRoutine,
    label: 'Tarefas Criadas',
    description: 'Lembretes de atividades recém criadas.',
  ),
  chatMessages(
    storageKey: 'chatMessages',
    section: NotificationSection.communication,
    label: 'Mensagens no Chat',
    description: 'Novas mensagens nos assuntos.',
  ),
  newChats(
    storageKey: 'newChats',
    section: NotificationSection.communication,
    label: 'Criação de Novos Chats',
    description: 'Notificação de chat recém criado.',
  ),
  soundAndVibration(
    storageKey: 'soundAndVibration',
    section: NotificationSection.deliveryPreferences,
    label: 'Som e Vibração',
  ),
  pushNotifications(
    storageKey: 'pushNotifications',
    section: NotificationSection.deliveryPreferences,
    label: 'Notificações Push',
  );

  const NotificationPreference({
    required this.storageKey,
    required this.section,
    required this.label,
    this.description,
  });

  /// Chave usada para gravar e ler no Firestore. Nunca use o `name` do enum
  /// direto na persistência: renomear o valor no código quebraria os dados.
  final String storageKey;

  /// Seção em que a preferência aparece na tela.
  final NotificationSection section;

  /// Nome exibido para a cuidadora.
  final String label;

  /// Frase curta explicando o que a pessoa recebe ao manter isso ligado.
  ///
  /// `null` quando o próprio rótulo já se explica (ex.: "Notificações Push").
  final String? description;

  /// Valor usado enquanto a cuidadora nunca escolheu nada.
  ///
  /// Hoje toda preferência nasce ligada: é mais seguro avisar demais do que
  /// deixar um alerta de emergência desligado sem a pessoa saber. Se algum dia
  /// um alerta precisar nascer desligado, isto volta a ser um campo do
  /// construtor — quem usa o enum não muda.
  bool get defaultValue => true;

  /// Preferências de uma seção, na ordem de declaração.
  static List<NotificationPreference> ofSection(NotificationSection section) {
    return values
        .where((preference) => preference.section == section)
        .toList(growable: false);
  }

  /// Devolve `null` para chaves desconhecidas, para que um campo antigo ou
  /// escrito por outra versão do app seja ignorado em vez de quebrar a leitura.
  static NotificationPreference? fromStorageKey(String key) {
    for (final preference in values) {
      if (preference.storageKey == key) return preference;
    }
    return null;
  }
}
