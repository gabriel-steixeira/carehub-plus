import '../../../home/data/models/caregiver_model.dart';

/// Settings and preferences repository.
class SettingsRepository {
  Future<CaregiverModel> fetchCaregiver() async {
    await Future.delayed(const Duration(milliseconds: 300));
    return const CaregiverModel(
      id: 'caregiver_123',
      name: 'Maria Oliveira',
      email: 'maria@carehub.com',
      photoUrl:
          'https://images.unsplash.com/photo-1494790108377-be9c29b29330?auto=format&fit=crop&q=80&w=150',
    );
  }

  Future<Map<String, bool>> fetchNotificationSettings() async {
    await Future.delayed(const Duration(milliseconds: 300));
    return {
      'pushEnabled': true,
      'medicationReminders': true,
      'coraProactiveAlerts': true,
      'networkChatNotifications': true,
    };
  }

  Future<void> updateNotificationSetting(String key, bool value) async {
    await Future.delayed(const Duration(milliseconds: 200));
  }
}
