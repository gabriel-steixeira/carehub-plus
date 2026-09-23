/*
 * CareHub Plus — Domínio / Gênero do Cuidador
 *
 * Opções de gênero do perfil do cuidador. O rótulo em português mora aqui,
 * junto do dado, e não no widget: assim qualquer tela que mostre o gênero
 * escreve exatamente a mesma palavra. A `storageKey` é o que vai para o
 * Firestore, o que permite trocar o rótulo exibido sem migrar o banco.
 *
 * Author: Vitoria Lana
 * Created on: 25/08/2026
 * Version: 1.0.0
 * Squad: CareHub Plus
 */

/// Gênero informado pelo cuidador no próprio perfil.
enum CaregiverGender {
  feminine('Feminino', 'feminine'),
  masculine('Masculino', 'masculine'),
  other('Outro', 'other'),
  undisclosed('Prefiro não informar', 'undisclosed');

  const CaregiverGender(this.label, this.storageKey);

  /// Texto exibido para a cuidadora.
  final String label;

  /// Chave gravada no Firestore.
  final String storageKey;

  /// Converte a chave gravada no banco de volta para o enum.
  ///
  /// Devolve `null` para valor ausente ou desconhecido — um dado antigo ou
  /// inválido deixa o campo vazio em vez de derrubar a tela.
  static CaregiverGender? fromStorageKey(String? key) {
    if (key == null || key.isEmpty) return null;
    for (final gender in CaregiverGender.values) {
      if (gender.storageKey == key) return gender;
    }
    return null;
  }
}
