import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:carehub_plus/features/home/data/models/caregiver_model.dart';
import 'package:carehub_plus/features/home/data/models/care_recipient_model.dart';
import 'package:carehub_plus/features/home/data/repositories/home_repository.dart';
import 'package:carehub_plus/features/home/presentation/bloc/home_bloc.dart';

class MockHomeRepository extends Mock implements HomeRepository {}

void main() {
  late HomeRepository homeRepository;
  late HomeBloc homeBloc;

  setUp(() {
    homeRepository = MockHomeRepository();
    homeBloc = HomeBloc(repository: homeRepository);
  });

  tearDown(() {
    homeBloc.close();
  });

  const caregiver = CaregiverModel(
    id: 'caregiver_123',
    name: 'Maria Oliveira',
    email: 'maria@carehub.com',
  );

  const profiles = [
    CareRecipientModel(
      id: 'recipient_yuna',
      name: 'Yuna',
      type: 'pet',
      unreadNotificationsCount: 0,
    ),
  ];

  group('HomeBloc', () {
    test('initial state is correct', () {
      expect(homeBloc.state, const HomeState());
    });

    group('HomeLoadEvent', () {
      blocTest<HomeBloc, HomeState>(
        'emits [loading, success] when fetching data succeeds',
        build: () {
          when(() => homeRepository.fetchCaregiver())
              .thenAnswer((_) async => caregiver);
          when(() => homeRepository.fetchCareRecipients())
              .thenAnswer((_) async => profiles);
          return homeBloc;
        },
        act: (bloc) => bloc.add(const HomeLoadEvent()),
        expect: () => const [
          HomeState(status: HomeStatus.loading),
          HomeState(
            status: HomeStatus.success,
            caregiver: caregiver,
            profiles: profiles,
          ),
        ],
        verify: (_) {
          verify(() => homeRepository.fetchCaregiver()).called(1);
          verify(() => homeRepository.fetchCareRecipients()).called(1);
        },
      );

      blocTest<HomeBloc, HomeState>(
        'emits [loading, failure] when fetching data fails',
        build: () {
          when(() => homeRepository.fetchCaregiver())
              .thenThrow(Exception('Erro no servidor'));
          return homeBloc;
        },
        act: (bloc) => bloc.add(const HomeLoadEvent()),
        expect: () => const [
          HomeState(status: HomeStatus.loading),
          HomeState(
            status: HomeStatus.failure,
            errorMessage: 'Exception: Erro no servidor',
          ),
        ],
      );
    });

    group('HomeSelectProfileEvent', () {
      blocTest<HomeBloc, HomeState>(
        'emits selectedProfileId state',
        build: () => homeBloc,
        act: (bloc) =>
            bloc.add(const HomeSelectProfileEvent(profileId: 'recipient_yuna')),
        expect: () => const [
          HomeState(selectedProfileId: 'recipient_yuna'),
        ],
      );
    });
  });
}
