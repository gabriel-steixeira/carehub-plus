import '../models/network_member_model.dart';

/// Repository for managing the Support Network.
class NetworkRepository {
  final List<NetworkMemberModel> _mockMembers = [
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
    await Future.delayed(const Duration(milliseconds: 400));
    return List.unmodifiable(_mockMembers);
  }

  Future<NetworkMemberModel> addMember(NetworkMemberModel member) async {
    await Future.delayed(const Duration(milliseconds: 300));
    _mockMembers.add(member);
    return member;
  }

  Future<void> removeMember(String memberId) async {
    await Future.delayed(const Duration(milliseconds: 300));
    _mockMembers.removeWhere((m) => m.id == memberId);
  }
}
