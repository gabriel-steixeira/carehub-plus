# Workflow: Generate Tests

## Trigger
User says: "gera testes para [feature/arquivo]" or "generate tests for [x]"

## Steps

### Step 1 — Identify target
- [ ] Load the target file
- [ ] Determine type: BLoC, Repository, or Widget

### Step 2 — For BLoC tests
- [ ] Load `.agent/rules/testing.md`
- [ ] Map every `on<Event>` handler → test case
- [ ] Cover: happy path, error path, empty/edge cases
- [ ] Mock repository with mocktail
- [ ] Use `blocTest` from `bloc_test` package

### Step 3 — For Repository tests
- [ ] Mock `FirebaseFirestore` with `fake_cloud_firestore`
- [ ] Test: successful fetch, document not found, FirebaseException
- [ ] Test stream emissions for `watch*` methods

### Step 4 — Place file
- [ ] Create at `test/features/[feature]/bloc/[feature]_bloc_test.dart`
- [ ] Or `test/features/[feature]/data/repositories/[feature]_repository_test.dart`

### Step 5 — Verify
- [ ] Run `flutter test [file_path]`
- [ ] All tests must pass
