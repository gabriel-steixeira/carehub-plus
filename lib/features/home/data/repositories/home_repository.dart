import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/care_recipient_type.dart';
import '../models/caregiver_model.dart';
import '../models/care_recipient_model.dart';

/// Repository for Home / Profile Selection feature with real Firebase Firestore integration.
class HomeRepository {
  HomeRepository({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  /// Fetches the currently authenticated Caregiver.
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

  /// Fetches all Care Recipients managed by this Caregiver from Firestore.
  Future<List<CareRecipientModel>> fetchCareRecipients() async {
    final user = _auth.currentUser;
    final userId = user?.uid ?? 'caregiver_123';

    try {
      final snapshot = await _firestore
          .collection('care_recipients')
          .where('caregiverId', isEqualTo: userId)
          .get();

      if (snapshot.docs.isNotEmpty) {
        return snapshot.docs
            .map((doc) => CareRecipientModel.fromJson(doc.data()))
            .toList();
      }

      return [];
    } catch (_) {
      return [];
    }
  }

  /// Adds a new Care Recipient to the Caregiver's profile list in Firestore.
  Future<CareRecipientModel> addCareRecipient({
    required String name,
    required CareRecipientType recipientType,
    DateTime? dateOfBirth,
    String? photoUrl,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('Usuário não autenticado. Faça login novamente.');
    }
    final userId = user.uid;
    final id = 'recipient_${DateTime.now().millisecondsSinceEpoch}';

    final profile = CareRecipientModel(
      id: id,
      name: name,
      type: recipientType == CareRecipientType.pet ? 'pet' : 'person',
      recipientType: recipientType,
      dateOfBirth: dateOfBirth,
      photoUrl: photoUrl,
      unreadNotificationsCount: 0,
    );

    final data = profile.toJson();
    data['caregiverId'] = userId;

    await _firestore.collection('care_recipients').doc(id).set(data);

    return profile;
  }
}
