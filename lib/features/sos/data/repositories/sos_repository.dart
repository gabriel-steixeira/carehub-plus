/*
 * CareHub Plus — Dados SOS / Repositório de pedidos de ajuda
 *
 * Porta de entrada única de dados da tela de SOS. A tela precisa juntar coisas
 * que vivem em três features diferentes (perfis cuidados, tarefas e rede de
 * apoio) e ainda disparar o alerta. Em vez de injetar quatro dependências no
 * BLoC, este repositório funciona como uma fachada (padrão Facade): o BLoC
 * conhece só ele, e os testes precisam simular só ele.
 *
 * Author: Vitoria Lana
 * Created on: 23/08/2026
 * Version: 1.0.0
 * Squad: CareHub Plus
 */

import 'dart:math';

import '../../../../core/errors/app_exception.dart';
import '../../../assistants/data/repositories/caregiver_avatar_repository.dart';
import '../../../home/data/models/care_recipient_model.dart';
import '../../../home/data/repositories/home_repository.dart';
import '../../../network/data/models/network_member_model.dart';
import '../../../network/data/repositories/network_repository.dart';
import '../../../tasks/data/models/task_model.dart';
import '../../../tasks/data/repositories/tasks_repository.dart';
import '../../domain/entities/sos_acceptance_entity.dart';
import '../../domain/entities/sos_help_request_entity.dart';

/// Fachada de dados do SOS: leitura da tela e ciclo de vida do alerta.
class SosRepository {
  SosRepository({
    HomeRepository? homeRepository,
    TasksRepository? tasksRepository,
    NetworkRepository? networkRepository,
    CaregiverAvatarRepository? caregiverAvatarRepository,
    Random? random,
  }) : _homeRepository = homeRepository ?? HomeRepository(),
       _tasksRepository = tasksRepository ?? TasksRepository(),
       _networkRepository = networkRepository ?? NetworkRepository(),
       _caregiverAvatarRepository =
           caregiverAvatarRepository ?? CaregiverAvatarRepository(),
       _random = random ?? Random();

  final HomeRepository _homeRepository;
  final TasksRepository _tasksRepository;
  final NetworkRepository _networkRepository;
  final CaregiverAvatarRepository _caregiverAvatarRepository;
  final Random _random;

  /// Tempo que a cuidadora tem para cancelar o alerta antes de a rede
  /// responder. Vive aqui, e não na interface, porque é regra do fluxo.
  static const Duration cancellationWindow = Duration(seconds: 10);

  /// Faixa de tempo estimado de chegada sorteada no MVP (em minutos).
  static const int _minEtaMinutes = 3;
  static const int _maxEtaMinutes = 9;

  /// Foto do cuidador autenticado para o cabeçalho. `null` quando a conta não
  /// tem foto — nesse caso o `AppHeader` mostra o avatar genérico.
  Future<String?> fetchCaregiverPhotoUrl() =>
      _caregiverAvatarRepository.fetchPhotoUrl();

  /// Perfis cuidados disponíveis para o filtro do topo da tela.
  Future<List<CareRecipientModel>> fetchProfiles() =>
      _homeRepository.fetchCareRecipients();

  /// Membros da rede de apoio que podem ser acionados.
  Future<List<NetworkMemberModel>> fetchSupportNetwork({
    String? careRecipientId,
  }) => _networkRepository.fetchMembers(careRecipientId: careRecipientId);

  /// Tarefas ainda em aberto do perfil selecionado — só elas fazem sentido
  /// como motivo de um pedido de ajuda.
  Future<List<TaskModel>> fetchOpenTasks({
    required String careRecipientId,
  }) async {
    final tasks = await _tasksRepository.fetchTasks(
      careRecipientId: careRecipientId,
    );
    return tasks.where((task) => !task.isCompleted).toList();
  }

  /// Registra o pedido de ajuda e devolve o id do alerta criado.
  ///
  /// **MVP:** o envio é simulado. Notificação real (push/SMS) depende de
  /// Firebase Cloud Messaging, que ainda não está no projeto; quando entrar,
  /// só este método muda — BLoC e telas continuam iguais.
  Future<String> notifySupportNetwork(SosHelpRequestEntity request) async {
    if (!request.isValid) {
      throw const AppException(
        'Escolha uma tarefa e pelo menos uma pessoa da rede de apoio.',
      );
    }

    return 'sos_${DateTime.now().millisecondsSinceEpoch}';
  }

  /// Sorteia quem da rede de apoio aceitou o chamado.
  ///
  /// **MVP:** sem backend para receber o aceite de verdade, um dos avisados é
  /// escolhido aleatoriamente quando a janela de cancelamento termina.
  Future<SosAcceptanceEntity> drawAcceptance(
    SosHelpRequestEntity request,
  ) async {
    if (request.notifiedMemberIds.isEmpty) {
      throw const AppException(
        'Nenhuma pessoa da rede de apoio foi avisada neste alerta.',
      );
    }

    final memberId = request
        .notifiedMemberIds[_random.nextInt(request.notifiedMemberIds.length)];
    final etaMinutes =
        _minEtaMinutes + _random.nextInt(_maxEtaMinutes - _minEtaMinutes);

    return SosAcceptanceEntity(memberId: memberId, etaMinutes: etaMinutes);
  }

  /// Cancela um alerta em andamento.
  ///
  /// **MVP:** nada é persistido ainda, então o cancelamento só encerra o
  /// pedido em memória. Mantido como método para o cancelamento ter um único
  /// lugar quando o backend existir.
  Future<void> cancelAlert(String alertId) async {
    if (alertId.isEmpty) {
      throw const AppException('Não há alerta em andamento para cancelar.');
    }
  }
}
