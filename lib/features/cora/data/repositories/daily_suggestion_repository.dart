/*
 * CareHub Plus — Dados / Sugestão diária da Cora
 *
 * Busca a sugestão proativa do dia para um assistido na Cloud Function
 * `coraDailySuggestion`. O cérebro e o cache diário vivem no backend; aqui só
 * fica a chamada e a conversão em `SuggestionModel`. É best-effort: qualquer
 * falha devolve uma lista vazia, porque uma sugestão que falha nunca pode
 * derrubar o Dashboard.
 *
 * Author: Vitoria Lana
 * Created on: 18/10/2026
 * Version: 1.0.0
 * Squad: CareHub Plus
 */

import '../../../../core/errors/app_exception.dart';
import '../../../../services/cloud_functions_service.dart';
import '../../../dashboard/data/models/suggestion_model.dart';

/// Busca a sugestão diária da Cora para o assistido selecionado.
class DailySuggestionRepository {
  DailySuggestionRepository({CallableClient? client})
    : _client = client ?? CloudFunctionsService();

  static const String _function = 'coraDailySuggestion';

  final CallableClient _client;

  /// Devolve a sugestão do dia do assistido, ou lista vazia quando não há.
  ///
  /// Nunca lança: em qualquer [AppException] devolve `const []`, mantendo o
  /// painel funcional mesmo que o backend ou a rede falhem.
  Future<List<SuggestionModel>> fetchDailySuggestions({
    required String careRecipientId,
  }) async {
    try {
      final data = await _client.call(_function, {
        'careRecipientId': careRecipientId,
      });
      final suggestion = data['suggestion'];
      if (suggestion is! Map<String, dynamic>) return const [];
      return [SuggestionModel.fromJson(suggestion)];
    } on AppException {
      return const [];
    }
  }
}
