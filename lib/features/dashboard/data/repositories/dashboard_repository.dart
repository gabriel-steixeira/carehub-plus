import '../../../home/data/models/care_recipient_model.dart';
import '../../../home/data/models/caregiver_model.dart';
import '../../../home/data/repositories/home_repository.dart';
import '../models/dashboard_summary_model.dart';
import '../models/suggestion_model.dart';

/// Repository for Dashboard feature.
class DashboardRepository {
  DashboardRepository({HomeRepository? homeRepository})
      : _homeRepository = homeRepository ?? HomeRepository();

  final HomeRepository _homeRepository;

  /// Fetches the currently authenticated Caregiver.
  Future<CaregiverModel> fetchCaregiver() {
    return _homeRepository.fetchCaregiver();
  }

  /// Fetches all Care Recipients managed by this Caregiver.
  Future<List<CareRecipientModel>> fetchCareRecipients() {
    return _homeRepository.fetchCareRecipients();
  }

  /// Fetches summary stats and pro-active AI suggestions for the active care recipient profile.
  Future<DashboardSummaryModel> fetchDashboardSummary(String profileId) async {
    await Future.delayed(const Duration(milliseconds: 600));

    // Simulated data according to profileId
    final isPet = profileId.contains('yuna');

    return DashboardSummaryModel(
      monitoredProfilesCount: 2,
      pendingTasksCount: isPet ? 2 : 4,
      supportNetworkCount: isPet ? 2 : 3,
      unreadChatsCount: isPet ? 0 : 2,
      suggestions: isPet
          ? const [
              SuggestionModel(
                id: 'sug_1',
                title: 'Vacinação Anual',
                description:
                    'A vacina V10 da Yuna vence em 15 dias. Deseja agendar um lembrete?',
                actionLabel: 'Criar Tarefa',
                category: 'Saúde',
              ),
              SuggestionModel(
                id: 'sug_2',
                title: 'Ração de Reforço',
                description:
                    'Cora detectou estoque baixo da ração Sênior. Adicionar à lista de compras?',
                actionLabel: 'Ver Estoque',
                category: 'Alimentação',
              ),
            ]
          : const [
              SuggestionModel(
                id: 'sug_3',
                title: 'Medicação Noturna',
                description:
                    'Vovó Lúcia precisa tomar a medicação de pressão às 20h. Confirmar com a cuidadora Patrícia.',
                actionLabel: 'Ver no Chat',
                category: 'Saúde',
              ),
              SuggestionModel(
                id: 'sug_4',
                title: 'Consulta Cardiológica',
                description:
                    'Retorno agendado para a próxima quinta-feira às 14h30.',
                actionLabel: 'Ver Agendamento',
                category: 'Consulta',
              ),
            ],
    );
  }
}
