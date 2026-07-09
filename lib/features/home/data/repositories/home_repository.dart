import '../models/caregiver_model.dart';
import '../models/care_recipient_model.dart';

/// Repository for Home / Profile Selection feature.
class HomeRepository {
  /// Fetches the currently authenticated Caregiver.
  Future<CaregiverModel> fetchCaregiver() async {
    // Simulating network delay
    await Future.delayed(const Duration(milliseconds: 800));

    return const CaregiverModel(
      id: 'caregiver_123',
      name: 'Maria Oliveira',
      email: 'maria@carehub.com',
      // High-quality unsplash photo for caregiver profile
      photoUrl:
          'https://images.unsplash.com/photo-1494790108377-be9c29b29330?auto=format&fit=crop&q=80&w=150',
    );
  }

  /// Fetches all Care Recipients managed by this Caregiver.
  Future<List<CareRecipientModel>> fetchCareRecipients() async {
    // Simulating network delay
    await Future.delayed(const Duration(milliseconds: 1000));

    return const [
      CareRecipientModel(
        id: 'recipient_yuna',
        name: 'Yuna',
        type: 'pet',
        unreadNotificationsCount: 0,
        // High-quality shiba inu image
        photoUrl:
            'https://images.unsplash.com/photo-1583511655857-d19b40a7a54e?auto=format&fit=crop&q=80&w=200',
      ),
      CareRecipientModel(
        id: 'recipient_lucia',
        name: 'Vovó Lúcia',
        type: 'person',
        unreadNotificationsCount: 1,
        // High-quality elderly person image
        photoUrl:
            'https://images.unsplash.com/photo-1502086223501-7ea6ecd79368?auto=format&fit=crop&q=80&w=200',
      ),
    ];
  }
}
