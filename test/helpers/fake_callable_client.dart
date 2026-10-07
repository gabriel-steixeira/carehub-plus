/*
 * CareHub Plus — Testes / Dublê das Cloud Functions
 *
 * Substitui o `CloudFunctionsService` nos testes: devolve respostas prontas
 * por nome de função e guarda o que foi enviado. Nenhum teste chama o
 * Firebase de verdade.
 *
 * Author: Vitoria Lana
 * Created on: 06/10/2026
 * Version: 1.0.0
 * Squad: CareHub Plus
 */

import 'package:carehub_plus/core/errors/app_exception.dart';
import 'package:carehub_plus/services/cloud_functions_service.dart';

/// Uma chamada registrada pelo dublê.
class FakeCall {
  const FakeCall(this.name, this.data);

  final String name;
  final Map<String, dynamic> data;
}

class FakeCallableClient implements CallableClient {
  FakeCallableClient({Map<String, Object>? responses})
    : responses = responses ?? {};

  /// Resposta por função: um `Map` devolvido ou uma `AppException` lançada.
  final Map<String, Object> responses;
  final List<FakeCall> calls = [];

  @override
  Future<Map<String, dynamic>> call(
    String name, [
    Map<String, dynamic> data = const {},
  ]) async {
    calls.add(FakeCall(name, data));
    final response = responses[name];
    if (response is AppException) throw response;
    if (response is Map<String, dynamic>) return response;
    return const {};
  }
}
