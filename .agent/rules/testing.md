# Testing Rules — CareHub Plus

## Test Structure (mirrors lib/)
```
test/
├── core/
│   └── theme/
│       └── app_theme_test.dart
├── shared/
│   └── widgets/
│       └── app_button_test.dart
└── features/
    └── [feature_name]/
        ├── bloc/
        │   └── [feature]_bloc_test.dart
        └── data/
            └── repositories/
                └── [feature]_repository_test.dart
```

## BLoC Test Template
```dart
void main() {
  late FeatureBloc bloc;
  late MockFeatureRepository repository;

  setUp(() {
    repository = MockFeatureRepository();
    bloc = FeatureBloc(repository: repository);
  });

  tearDown(() => bloc.close());

  blocTest<FeatureBloc, FeatureState>(
    'emits [loading, success] when load succeeds',
    build: () {
      when(() => repository.fetchData()).thenAnswer((_) async => fakeEntity);
      return bloc;
    },
    act: (bloc) => bloc.add(const FeatureLoadEvent()),
    expect: () => [
      const FeatureState(status: FeatureStatus.loading),
      FeatureState(status: FeatureStatus.success, data: fakeEntity),
    ],
  );
}
```

## Coverage Targets
- BLoC: 100% — every event/state transition must be tested
- Repository: 90% — all paths including error cases
- Widgets: test interaction, not rendering details
- No test should make real Firebase calls — always mock

## Mocking
- Use `mocktail` (not mockito)
- Create `MockXxxRepository` extending `Mock` implements `XxxRepository`
- Fake entities in `test/helpers/fake_entities.dart`
