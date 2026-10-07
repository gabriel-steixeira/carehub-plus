/*
 * CareHub Plus — Domínio / Canal do convite
 *
 * Por onde a pessoa convidada vai aceitar o convite. A explicação de cada
 * canal mora no enum, junto do dado, para que qualquer tela mostre a mesma
 * frase (padrão do design system para escolhas com consequência).
 *
 * Author: Vitoria Lana
 * Created on: 06/10/2026
 * Version: 1.0.0
 * Squad: CareHub Plus
 */

/// Canal de aceite do convite.
enum InviteChannel {
  app(
    'Pelo app',
    'app',
    'A pessoa cria a conta no CareHub e usa o código em "Tenho um convite".',
  ),
  whatsapp(
    'Pelo WhatsApp',
    'whatsapp',
    'A pessoa toca no link, envia a mensagem pronta e já fala com a Cora.',
  );

  const InviteChannel(this.label, this.value, this.description);

  final String label;

  /// Valor esperado pelo backend.
  final String value;

  /// Frase que explica o efeito da escolha.
  final String description;

  static InviteChannel fromValue(String? value) {
    return InviteChannel.values.firstWhere(
      (channel) => channel.value == value,
      orElse: () => InviteChannel.app,
    );
  }
}
