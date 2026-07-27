import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../home/data/models/caregiver_model.dart';

/// Settings and preferences repository with real Firebase integration.
class SettingsRepository {
  SettingsRepository({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  Future<CaregiverModel> fetchCaregiver() async {
    final user = _auth.currentUser;
    if (user != null) {
      final doc = await _firestore.collection('caregivers').doc(user.uid).get();
      if (doc.exists && doc.data() != null) {
        return CaregiverModel.fromJson(doc.data()!);
      }
      return CaregiverModel(
        id: user.uid,
        name: user.displayName ?? 'Cuidador',
        email: user.email ?? 'cuidador@carehub.com',
        photoUrl: user.photoURL ??
            'https://images.unsplash.com/photo-1494790108377-be9c29b29330?auto=format&fit=crop&q=80&w=150',
      );
    }

    return const CaregiverModel(
      id: 'caregiver_123',
      name: 'Maria Oliveira',
      email: 'maria@carehub.com',
      photoUrl:
          'https://images.unsplash.com/photo-1494790108377-be9c29b29330?auto=format&fit=crop&q=80&w=150',
    );
  }

  Future<Map<String, bool>> fetchNotificationSettings() async {
    final uid = _auth.currentUser?.uid;
    if (uid != null) {
      try {
        final doc = await _firestore.collection('caregivers').doc(uid).get();
        if (doc.exists && doc.data()?['settings'] != null) {
          final map = Map<String, dynamic>.from(doc.data()!['settings']);
          return map.map((k, v) => MapEntry(k, v as bool));
        }
      } catch (_) {}
    }

    return {
      'pushEnabled': true,
      'medicationReminders': true,
      'coraProactiveAlerts': true,
      'networkChatNotifications': true,
    };
  }

  Future<void> updateNotificationSetting(String key, bool value) async {
    final uid = _auth.currentUser?.uid;
    if (uid != null) {
      try {
        await _firestore.collection('caregivers').doc(uid).set({
          'settings': {key: value}
        }, SetOptions(merge: true));
      } catch (_) {}
    }
  }
}
