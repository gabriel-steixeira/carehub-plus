# Architecture Rules — CareHub Plus

## Folder Structure (feature-first, mandatory)

```
lib/
├── main.dart
├── app/
│   ├── app.dart                    # MaterialApp root
│   └── router/
│       └── app_router.dart         # GoRouter — all routes defined here
├── core/
│   ├── theme/
│   │   ├── app_theme.dart          # ThemeData, ColorScheme — SINGLE SOURCE OF TRUTH for colors
│   │   ├── app_typography.dart     # TextTheme, all text styles
│   │   └── app_spacing.dart        # Spacing constants (4px grid)
│   ├── constants/
│   │   └── app_constants.dart      # Non-UI constants (timeouts, limits)
│   ├── errors/
│   │   ├── app_exception.dart      # Base exception class
│   │   └── failures.dart           # Typed failures (NetworkFailure, AuthFailure, etc.)
│   └── utils/
│       └── validators.dart         # Form validators
├── shared/
│   └── widgets/                    # Reusable components — check here FIRST
│       ├── app_button.dart
│       ├── app_text_field.dart
│       ├── app_card.dart
│       ├── app_loading.dart
│       ├── app_error_view.dart
│       └── app_empty_view.dart
├── services/
│   ├── auth_service.dart           # Firebase Auth abstraction
│   └── storage_service.dart        # Firebase Storage abstraction
└── features/
    └── [feature_name]/             # e.g., home, profile, appointments
        ├── data/
        │   ├── models/
        │   │   └── [model]_model.dart         # Freezed model + fromJson/toJson
        │   └── repositories/
        │       └── [feature]_repository.dart  # Firebase calls ONLY here
        ├── domain/
        │   └── entities/
        │       └── [feature]_entity.dart      # Pure Dart entity (no Firebase deps)
        └── presentation/
            ├── bloc/
            │   ├── [feature]_bloc.dart
            │   ├── [feature]_event.dart
            │   └── [feature]_state.dart
            ├── pages/
            │   └── [feature]_page.dart        # Scaffold + BlocProvider
            └── widgets/
                └── [feature specific widgets]
```

## Naming Conventions
- Files: `snake_case.dart`
- Classes: `PascalCase`
- Variables/methods: `camelCase`
- BLoC events: `[Feature][Action]Event` (e.g., `ProfileLoadEvent`)
- BLoC states: `[Feature]State` with `status` enum (initial, loading, success, failure)
- Routes: `AppRoutes.featureName` as static `String` constants

## Layer Rules
| Layer | Can access | Cannot access |
|---|---|---|
| Widget (presentation) | BLoC state, shared/widgets, core/theme | Repository, Firebase, services |
| BLoC | Repository, domain entities | Firebase directly, Widgets |
| Repository | Firebase services, models | BLoC, Widgets |
| Model | Nothing external | — |

## One BLoC per feature
Never share a BLoC between unrelated features. If data is needed across features, use a Repository or a shared service layer.

## Domain Scoping & Data Modeling
1. **Caregiver (Cuidador):** Scoped globally to the app session. Represents the logged-in user.
2. **Care Recipient (Cuidado/Paciente):** Most features (such as tasks, chat, clinical record) MUST be scoped to the *currently active/selected Care Recipient* (i.e. using a `careRecipientId`). Ensure repositories filter queries based on the active care recipient profile.
