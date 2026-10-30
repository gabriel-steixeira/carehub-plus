/*
 * CareHub Plus — Core / Formatadores de Entrada
 *
 * Máscaras visuais para campos de formulário. Formatam o texto enquanto o
 * usuário digita, sem alterar o valor que será persistido: a tela continua
 * salvando apenas os dígitos (ex.: `onlyDigits`), então o Firestore nunca
 * recebe pontuação. Existe para melhorar o UX/UI mantendo o backend intacto.
 *
 * Author: Vitoria Lana
 * Created on: 18/10/2026
 * Version: 1.0.0
 * Squad: CareHub Plus
 */

import 'package:flutter/services.dart';

/// Máscara visual para telefone brasileiro.
///
/// Formata enquanto o usuário digita, aceitando fixo (10 dígitos) e celular
/// (11 dígitos):
/// - `(11) 1234-5678` para fixo;
/// - `(11) 98765-4321` para celular.
///
/// O valor é apenas visual. A tela deve persistir somente os dígitos
/// (use [onlyDigits]) para não mudar o formato gravado no backend.
class PhoneInputFormatter extends TextInputFormatter {
  const PhoneInputFormatter();

  /// DDD + até 9 dígitos do número.
  static const int _maxDigits = 11;

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = onlyDigits(newValue.text);
    final trimmed = digits.length > _maxDigits
        ? digits.substring(0, _maxDigits)
        : digits;

    final formatted = _mask(trimmed);

    // Mantém o cursor no fim: simples e suficiente para o fluxo de digitação
    // destes formulários, onde o usuário preenche da esquerda para a direita.
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }

  String _mask(String digits) {
    if (digits.isEmpty) return '';

    final buffer = StringBuffer('(');
    for (var i = 0; i < digits.length; i++) {
      buffer.write(digits[i]);

      // Fecha o DDD depois do 2º dígito.
      if (i == 1) buffer.write(') ');

      // Hífen antes dos 4 últimos dígitos: posição 6 no celular (11 dígitos)
      // e posição 5 no fixo (10 dígitos).
      final hyphenAt = digits.length > 10 ? 6 : 5;
      if (i == hyphenAt && i != digits.length - 1) buffer.write('-');
    }
    return buffer.toString();
  }
}

/// Remove tudo que não for dígito. Use no `submit` da tela para persistir o
/// número limpo, independentemente da máscara exibida.
String onlyDigits(String value) => value.replaceAll(RegExp(r'\D'), '');
