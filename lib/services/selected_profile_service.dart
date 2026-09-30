/*
 * CareHub Plus — Serviço de Perfil Selecionado
 *
 * Gerencia o dependente (care recipient) atualmente selecionado pelo usuário.
 * Armazena em SharedPreferences para persistir entre sessões.
 *
 * Author: Vitoria Lana
 * Created on: 23/09/2026
 * Version: 1.0.0
 * Squad: CareHub Plus
 */

import 'package:shared_preferences/shared_preferences.dart';

/// Gerencia o perfil de dependente selecionado no app.
class SelectedProfileService {
  static const String _selectedProfileKey = 'selected_care_recipient_id';
  static const String _selectedProfileNameKey = 'selected_care_recipient_name';

  final SharedPreferences _prefs;

  SelectedProfileService(this._prefs);

  /// Factory para criar instância do serviço.
  static Future<SelectedProfileService> create() async {
    final prefs = await SharedPreferences.getInstance();
    return SelectedProfileService(prefs);
  }

  /// Define o perfil atualmente selecionado.
  Future<void> setSelectedProfile({
    required String careRecipientId,
    required String careRecipientName,
  }) async {
    await _prefs.setString(_selectedProfileKey, careRecipientId);
    await _prefs.setString(_selectedProfileNameKey, careRecipientName);
  }

  /// Retorna o ID do perfil selecionado, ou null se nenhum estiver selecionado.
  String? getSelectedProfileId() {
    return _prefs.getString(_selectedProfileKey);
  }

  /// Retorna o nome do perfil selecionado, ou null se nenhum estiver selecionado.
  String? getSelectedProfileName() {
    return _prefs.getString(_selectedProfileNameKey);
  }

  /// Remove a seleção atual (logout ou troca de conta).
  Future<void> clearSelectedProfile() async {
    await _prefs.remove(_selectedProfileKey);
    await _prefs.remove(_selectedProfileNameKey);
  }

  /// Verifica se há um perfil selecionado.
  bool hasSelectedProfile() {
    return _prefs.containsKey(_selectedProfileKey);
  }
}
