/*
 * CareHub Plus — Core Utils / Date Format Helper
 *
 * Utilitários para formatação humanizada de datas em português brasileiro.
 * Usado para exibir datas de forma amigável em toda a aplicação.
 *
 * Author: Vitoria Lana
 * Created on: 23/09/2026
 * Version: 1.0.0
 * Squad: CareHub Plus
 */

import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';

/// Helpers para formatação de datas de forma humanizada.
class DateFormatHelper {
  DateFormatHelper._();

  static bool _localeInitialized = false;

  /// Inicializa os dados de localização para pt_BR.
  /// Deve ser chamado no início do app (main.dart).
  static Future<void> initialize() async {
    if (!_localeInitialized) {
      await initializeDateFormatting('pt_BR', null);
      _localeInitialized = true;
    }
  }

  /// Formata uma data de forma humanizada em português.
  ///
  /// Exemplos:
  /// - Se for hoje: "Hoje"
  /// - Se for amanhã: "Amanhã"
  /// - Se for ontem: "Ontem"
  /// - Se for esta semana: "Qui, 23 Jan"
  /// - Se for este ano: "23 de Janeiro"
  /// - Caso contrário: "23/01/2026"
  static String formatHumanized(DateTime date) {
    // Inicialização lazy na primeira chamada
    if (!_localeInitialized) {
      initializeDateFormatting('pt_BR', null);
      _localeInitialized = true;
    }

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dateOnly = DateTime(date.year, date.month, date.day);
    final difference = dateOnly.difference(today).inDays;

    if (difference == 0) {
      return 'Hoje';
    } else if (difference == 1) {
      return 'Amanhã';
    } else if (difference == -1) {
      return 'Ontem';
    } else if (difference > 1 && difference <= 6) {
      // Próximos 6 dias: exibe dia da semana abreviado + dia + mês abreviado
      return DateFormat('EEE, d MMM', 'pt_BR').format(date);
    } else if (difference >= -6 && difference < -1) {
      // Últimos 6 dias: exibe dia da semana abreviado + dia + mês abreviado
      return DateFormat('EEE, d MMM', 'pt_BR').format(date);
    } else if (date.year == now.year) {
      // Mesmo ano: dia + mês por extenso
      return DateFormat('d \'de\' MMMM', 'pt_BR').format(date);
    } else {
      // Outro ano: formato numérico
      return DateFormat('dd/MM/yyyy', 'pt_BR').format(date);
    }
  }

  /// Formata data e hora de forma compacta.
  ///
  /// Exemplos:
  /// - "Hoje, 14:30"
  /// - "Amanhã, 09:00"
  /// - "Qui, 23 Jan, 14:30"
  static String formatWithTime(DateTime dateTime) {
    if (!_localeInitialized) {
      initializeDateFormatting('pt_BR', null);
      _localeInitialized = true;
    }

    final dateStr = formatHumanized(dateTime);
    final timeStr = DateFormat('HH:mm', 'pt_BR').format(dateTime);
    return '$dateStr, $timeStr';
  }

  /// Formata apenas o horário.
  ///
  /// Exemplo: "14:30"
  static String formatTime(DateTime dateTime) {
    if (!_localeInitialized) {
      initializeDateFormatting('pt_BR', null);
      _localeInitialized = true;
    }

    return DateFormat('HH:mm', 'pt_BR').format(dateTime);
  }

  /// Formata data no formato curto.
  ///
  /// Exemplo: "23/01/2026"
  static String formatShort(DateTime date) {
    if (!_localeInitialized) {
      initializeDateFormatting('pt_BR', null);
      _localeInitialized = true;
    }

    return DateFormat('dd/MM/yyyy', 'pt_BR').format(date);
  }

  /// Formata data no formato longo.
  ///
  /// Exemplo: "23 de janeiro de 2026"
  static String formatLong(DateTime date) {
    if (!_localeInitialized) {
      initializeDateFormatting('pt_BR', null);
      _localeInitialized = true;
    }

    return DateFormat('d \'de\' MMMM \'de\' yyyy', 'pt_BR').format(date);
  }

  /// Verifica se duas datas são do mesmo dia.
  static bool isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  /// Retorna a data sem horário (meia-noite).
  static DateTime dateOnly(DateTime dateTime) {
    return DateTime(dateTime.year, dateTime.month, dateTime.day);
  }
}
