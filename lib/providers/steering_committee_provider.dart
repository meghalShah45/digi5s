import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/steering_committee.dart';

class SteeringCommitteeNotifier extends StateNotifier<List<SteeringCommitteeMember>> {
  SteeringCommitteeNotifier() : super([]);

  void addMember(SteeringCommitteeMember member) {
    state = [...state, member];
  }

  void updateMember(SteeringCommitteeMember updatedMember) {
    state = state.map((member) {
      return member.id == updatedMember.id ? updatedMember : member;
    }).toList();
  }

  void deleteMember(String id) {
    state = state.where((member) => member.id != id).toList();
  }

  Future<String> uploadPhoto(String filePath) async {
    // TODO: Implement photo upload to storage service
    // For now, return a placeholder URL
    return 'https://picsum.photos/${DateTime.now().millisecondsSinceEpoch % 1000}';
  }

  // Load members from storage or API
  Future<void> loadMembers() async {
    // TODO: Implement loading from storage or API
    state = [
      SteeringCommitteeMember(
        id: '1',
        name: 'User Name 1',
        role: 'Chairman',
        joinedDate: DateTime(2023, 1, 1),
      ),
      SteeringCommitteeMember(
        id: '2',
        name: 'User Name 2',
        role: 'Secretary',
        joinedDate: DateTime(2023, 2, 15),
      ),
    ];
  }

  // Save members to storage or API
  Future<void> saveMembers() async {
    // TODO: Implement saving to storage or API
  }
}

final steeringCommitteeProvider =
    StateNotifierProvider<SteeringCommitteeNotifier, List<SteeringCommitteeMember>>(
  (ref) => SteeringCommitteeNotifier(),
);
