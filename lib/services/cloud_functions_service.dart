/*
 * CareHub Plus — Serviços / Chamadas às Cloud Functions
 *
 * Único ponto do app que conhece o SDK `cloud_functions`. Os repositórios
 * dependem do contrato `CallableClient`, então testes trocam por um dublê
 * sem tocar no Firebase. Erros do backend chegam como `AppException`, com a
 * mensagem já pronta para mostrar e o código (ex.: `permission-denied`).
 *
 * Author: Vitoria Lana
 * Created on: 06/10/2026
 * Version: 1.0.0
 * Squad: CareHub Plus
 */

import 'package:cloud_functions/cloud_functions.dart';

import '../core/errors/app_exception.dart';

/// Contrato de uma chamada a uma função do backend.
abstract interface class CallableClient {
  /// Chama a função [name] e devolve o corpo da resposta como mapa.
  ///
  /// Lança [AppException] com a mensagem do backend quando a chamada falha.
  Future<Map<String, dynamic>> call(
    String name, [
    Map<String, dynamic> data = const {},
  ]);
}

/// Implementação real, na mesma região do Firestore e das Functions.
class CloudFunctionsService implements CallableClient {
  CloudFunctionsService({FirebaseFunctions? functions})
    : _functions =
          functions ??
          FirebaseFunctions.instanceFor(region: _region);

  static const String _region = 'southamerica-east1';

  /// As respostas da Cora podem levar mais que o padrão de 60s quando o
  /// Gemini repete uma tentativa.
  static const Duration _timeout = Duration(seconds: 90);

  final FirebaseFunctions _functions;

  @override
  Future<Map<String, dynamic>> call(
    String name, [
    Map<String, dynamic> data = const {},
  ]) async {
    try {
      final result = await _functions
          .httpsCallable(name, options: HttpsCallableOptions(timeout: _timeout))
          .call<Object?>(data);
      return _asMap(result.data);
    } on FirebaseFunctionsException catch (error) {
      throw AppException(
        error.message?.trim().isNotEmpty == true
            ? error.message!
            : 'Não foi possível concluir agora. Tente novamente.',
        code: error.code,
      );
    } catch (_) {
      throw const AppException(
        'Não foi possível conectar ao CareHub. Verifique sua internet.',
      );
    }
  }

  /// O SDK devolve `Map<Object?, Object?>`; converte para chaves `String`.
  static Map<String, dynamic> _asMap(Object? value) {
    if (value is Map) {
      return value.map((key, item) => MapEntry(key.toString(), _normalize(item)));
    }
    return const {};
  }

  static Object? _normalize(Object? value) {
    if (value is Map) return _asMap(value);
    if (value is List) return value.map(_normalize).toList();
    return value;
  }
}
