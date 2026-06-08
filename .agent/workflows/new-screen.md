# Workflow: Create New Screen

## Trigger
User says: "cria uma nova tela de [nome]" or "new screen for [feature]"

## Steps (execute in order)

### Step 1 — Identify
- [ ] Ask: "Qual é o nome da feature? (ex: appointments, profile, home)"
- [ ] Ask: "Tem link do frame no Figma?"
- [ ] Load: `.agent/rules/architecture.md`, `.agent/rules/design-system.md`, `.agent/rules/flutter-bloc.md`

### Step 2 — Create folder structure
```
lib/features/[feature]/
├── data/
│   ├── models/[feature]_model.dart
│   └── repositories/[feature]_repository.dart
├── domain/
│   └── entities/[feature]_entity.dart
└── presentation/
    ├── bloc/
    │   ├── [feature]_bloc.dart
    │   ├── [feature]_event.dart
    │   └── [feature]_state.dart
    ├── pages/
    │   └── [feature]_page.dart
    └── widgets/
        └── (empty — add as needed)
```

### Step 3 — Generate files
- [ ] `[feature]_entity.dart` — pure Dart, Equatable, final fields
- [ ] `[feature]_model.dart` — extends entity, add fromJson/toJson with freezed
- [ ] `[feature]_repository.dart` — stub with TODO comments for each method
- [ ] `[feature]_event.dart` — Load event + any other obvious events
- [ ] `[feature]_state.dart` — status enum + copyWith
- [ ] `[feature]_bloc.dart` — handler for each event
- [ ] `[feature]_page.dart` — BlocProvider + BlocBuilder with loading/error/success

### Step 4 — Register route
- [ ] Add `GoRoute` to `lib/app/router/app_router.dart`
- [ ] Add route constant to `AppRoutes`

### Step 5 — Verify
- [ ] Run `flutter analyze` — zero errors
- [ ] Run `dart format .`
- [ ] Show usage: how to navigate to the new screen

## Output
Show all created files. Show the route addition. Confirm analyze passes.
