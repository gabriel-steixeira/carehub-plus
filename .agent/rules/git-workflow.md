# Git Workflow — CareHub Plus

## Branch Strategy
```
main          ← production-ready only
└── develop   ← integration branch
    ├── feat/[feature-name]      ← new features
    ├── fix/[bug-description]    ← bug fixes
    ├── refactor/[description]   ← refactors
    └── docs/[description]       ← documentation only
```

## Commit Convention (Conventional Commits)
```
feat: add appointment booking screen
fix: resolve auth token refresh on cold start
refactor: extract shared AppButton from feature widgets
docs: update architecture rules with routing section
test: add bloc tests for profile feature
chore: update flutter_bloc to 8.1.6
```

## PR Rules
- Title follows commit convention
- Must pass `flutter analyze` with zero issues
- Must pass `flutter test` with zero failures
- Link to Figma frame if PR contains UI changes
- At least one reviewer required before merge to develop

## Do Not Commit
- `.env` files or any Firebase config with real credentials
- `*.g.dart` generated files if they are in .gitignore
- `pubspec.lock` changes from accidental version bumps
