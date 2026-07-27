import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/network_member_model.dart';

/// Repository for managing the Support Network with real Firebase Firestore integration.
class NetworkRepository {
  NetworkRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  final List<NetworkMemberModel> _seedMembers = [
    const NetworkMemberModel(
      id: 'mem_1',
      name: 'Patrícia Cuidadora',
      phone: '(11) 98765-4321',
      role: NetworkRole.caregiver,
      email: 'patricia.cuidadora@email.com',
      photoUrl: 'https://i.pravatar.cc/150?img=47',
      isOnline: true,
    ),
    const NetworkMemberModel(
      id: 'mem_2',
      name: 'Dr. Roberto Santos',
      phone: '(11) 91234-5678',
      role: NetworkRole.doctor,
      email: 'dr.roberto@cardio.med.br',
      photoUrl: 'https://i.pravatar.cc/150?img=11',
      isOnline: false,
    ),
    const NetworkMemberModel(
      id: 'mem_3',
      name: 'Carlos Teixeira',
      phone: '(11) 99887-6655',
      role: NetworkRole.family,
      email: 'carlos.t@email.com',
      photoUrl: 'https://i.pravatar.cc/150?img=12',
      isOnline: true,
    ),
  ];

  Future<List<NetworkMemberModel>> fetchMembers() async {
    try {
      final snapshot = await _firestore.collection('network_members').get();
      if (snapshot.docs.isNotEmpty) {
        return snapshot.docs
            .map((doc) => NetworkMemberModel.fromJson(doc.data()))
            .toList();
      }

      // Seed default members
      for (final m in _seedMembers) {
        await _firestore.collection('network_members').doc(m.id).set(m.toJson());
      }
      return _seedMembers;
    } catch (_) {
      return _seedMembers;
    }
  }

  Future<NetworkMemberModel> addMember(NetworkMemberModel member) async {
    final docId = member.id.isEmpty
        ? 'mem_${DateTime.now().millisecondsSinceEpoch}'
        : member.id;
    final data = member.toJson();
    data['id'] = docId;

    await _firestore.collection('network_members').doc(docId).set(data);
    return NetworkMemberModel.fromJson(data);
  }

  Future<void> removeMember(String memberId) async {
    await _firestore.collection('network_members').doc(memberId).delete();
  }
}
