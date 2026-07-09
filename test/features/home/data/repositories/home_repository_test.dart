import 'package:flutter_test/flutter_test.dart';
import 'package:carehub_plus/features/home/data/repositories/home_repository.dart';

void main() {
  late HomeRepository repository;

  setUp(() {
    repository = HomeRepository();
  });

  group('HomeRepository', () {
    test('fetchCaregiver returns caregiver profile successfully', () async {
      final caregiver = await repository.fetchCaregiver();

      expect(caregiver.id, equals('caregiver_123'));
      expect(caregiver.name, equals('Maria Oliveira'));
      expect(caregiver.email, equals('maria@carehub.com'));
      expect(caregiver.photoUrl, isNotNull);
    });

    test('fetchCareRecipients returns all care recipients successfully',
        () async {
      final recipients = await repository.fetchCareRecipients();

      expect(recipients, hasLength(2));
      expect(recipients[0].id, equals('recipient_yuna'));
      expect(recipients[0].name, equals('Yuna'));
      expect(recipients[0].type, equals('pet'));
      expect(recipients[0].unreadNotificationsCount, equals(0));

      expect(recipients[1].id, equals('recipient_lucia'));
      expect(recipients[1].name, equals('Vovó Lúcia'));
      expect(recipients[1].type, equals('person'));
      expect(recipients[1].unreadNotificationsCount, equals(1));
    });
  });
}
