import '../models/cora_message_model.dart';

/// Repository for Cora AI Assistant interaction.
class CoraRepository {
  final List<CoraMessageModel> _initialMessages = [
    CoraMessageModel(
      id: 'cora_welcome',
      text:
          'Olá! Eu sou a Cora, sua assistente proativa de cuidados no CareHub+. Como posso te ajudar hoje?',
      isUser: false,
      timestamp: DateTime.now().subtract(const Duration(minutes: 5)),
      quickReplies: const [
        'Resumo da Vovó Lúcia',
        'Lembretes da Yuna (Pet)',
        'Dicas de Saúde',
        'Próximas Mediações',
      ],
    ),
  ];

  Future<List<CoraMessageModel>> fetchInitialMessages() async {
    await Future.delayed(const Duration(milliseconds: 300));
    return List.of(_initialMessages);
  }

  Future<CoraMessageModel> sendMessage(
      String userText, List<CoraMessageModel> history) async {
    await Future.delayed(const Duration(milliseconds: 800));

    final textLower = userText.toLowerCase();
    String responseText;
    List<String> replies = [];

    if (textLower.contains('vovó') || textLower.contains('lúcia')) {
      responseText =
          'Vovó Lúcia está com todas as medicações em dia hoje! A pressão foi aferida às 08h (12/8). A próxima medicação de pressão será às 20h.';
      replies = ['Ver Tarefas da Vovó', 'Abrir Chat da Rede'];
    } else if (textLower.contains('yuna') || textLower.contains('pet')) {
      responseText =
          'A Yuna (Pet) tomou a ração matinal! Lembrete: a vacina V10 precisa de reforço em 15 dias. Deseja agendar o lembrete?';
      replies = ['Criar Lembrete de Vacina', 'Ver Alimentação'];
    } else if (textLower.contains('medicação') || textLower.contains('remédio')) {
      responseText =
          'Temos 1 medicação agendada para hoje às 20h: Anti-hipertensivo (Losartana 50mg) para a Vovó Lúcia.';
      replies = ['Marcar como Concluída', 'Ver Lista de Tarefas'];
    } else if (textLower.contains('dica') || textLower.contains('saúde')) {
      responseText =
          'Dica Cora: Manter uma rotina de hidratação regular e caminhadas curtas pela manhã melhora a circulação e o humor de idosos em até 35%!';
      replies = ['Agendar Caminhada', 'Falar com Médico'];
    } else {
      responseText =
          'Entendi! Estou monitorando a rotina de cuidados do CareHub+. Posso te ajudar a criar uma tarefa, consultar a rede de apoio ou dar orientações de saúde.';
      replies = [
        'Resumo da Vovó Lúcia',
        'Lembretes da Yuna',
        'Próximas Mediações',
      ];
    }

    return CoraMessageModel(
      id: 'cora_${DateTime.now().millisecondsSinceEpoch}',
      text: responseText,
      isUser: false,
      timestamp: DateTime.now(),
      quickReplies: replies,
    );
  }
}
