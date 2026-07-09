# CareHub Plus — AI Agent Rules

## Project Overview
CareHub Plus is a **mobile health/care app** built with Flutter + Firebase.
- **Platform:** Flutter (Dart) — Mobile only (iOS & Android)
- **State Management:** BLoC (flutter_bloc)
- **Backend:** Firebase (Firestore, Auth, Storage, Cloud Functions)
- **Target device:** iPhone 13 Pro (390×844) and equivalent Android
- **Design System:** Figma — purple/lilac palette (#7B61C8 primary, gradient purple→white→pink)
- **Typography:** Inter (all weights)
- **Language:** UI text in Portuguese (BR); code, comments, variables in English

## Core Philosophy
> **One codebase, one style, forever.** The app must look and feel architecturally identical on day 1 and day 300. Every new feature must be indistinguishable from existing code in structure, naming, and style.

## Domain Concepts (Caregiver vs. Care Recipient)
- **Caregiver (Cuidador):** The authenticated user (account owner). Has login credentials (email/password), settings, and manages one or more profiles.
- **Care Recipient (Cuidado/Paciente):** The person or pet being cared for (e.g., Vovó Lúcia, Yuna). App features like tasks, medical logs, chat, and SOS are always scoped and associated with the selected Care Recipient, not the Caregiver.

## Absolute Rules (never break these)
1. **Never** write business logic inside a Widget. Widgets are dumb — they render state.
2. **Never** hardcode colors, font sizes, or spacing. Always reference `AppTheme`, `AppTypography`, or `AppSpacing`.
3. **Never** create a new component without checking `lib/shared/widgets/` first.
4. **Never** access Firebase directly from a Widget or BLoC. Always go through a Repository.
5. **Never** skip error, loading, and empty states. Every screen must handle all three.
6. **Always** follow the Feature-first folder structure (see architecture.md rule file).
7. **Always** write tests for BLoC events/states and Repository methods.
8. **Always** use `const` constructors wherever possible.
9. **Always** use named routes via `AppRouter`.
10. **Commits** must follow Conventional Commits: `feat:`, `fix:`, `refactor:`, `docs:`, `test:`, `chore:`.

## Figma Reference
- File: https://www.figma.com/file/HWnS5C49Kc86lRwuMbzEjx/CareHub-Plus
- Pages: Cover · Identidade Visual · Wireframes · Others
- Always check Figma before implementing any UI. Pixel-perfect adherence required.

## Stack Versions (always use these — do not upgrade without explicit instruction)
- Flutter: stable channel
- flutter_bloc: ^8.x
- firebase_core, firebase_auth, cloud_firestore, firebase_storage: latest stable
- go_router: ^14.x (routing)
- freezed + json_serializable: code generation for models
- mocktail: testing mocks
