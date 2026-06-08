# Workflow: Code Review

## Trigger
User says: "revisa o PR", "code review", "analisa esse código"

## Checklist (go through every item)

### Architecture
- [ ] Business logic is NOT in widgets
- [ ] Firebase is NOT called outside repositories
- [ ] Feature folder structure matches architecture.md
- [ ] New components added to `shared/widgets/` if reusable

### Design System
- [ ] No hardcoded colors — all from AppTheme
- [ ] No hardcoded font sizes — all from AppTypography
- [ ] No hardcoded spacing — all from AppSpacing
- [ ] Loading/error/empty states handled

### BLoC
- [ ] Events extend Equatable with `props`
- [ ] States use `copyWith` pattern
- [ ] Status enum used (not boolean flags)
- [ ] No Firebase calls inside BLoC

### Flutter Best Practices
- [ ] `const` constructors used where possible
- [ ] No `setState` in screens that use BLoC
- [ ] No magic numbers
- [ ] Widget tree is not deeply nested (max ~5 levels — extract if deeper)

### Testing
- [ ] New BLoC events have tests
- [ ] New repository methods have tests
- [ ] No real Firebase calls in tests

### Git
- [ ] Commit messages follow Conventional Commits
- [ ] No debug prints (`print()`) left in code

## Output Format
Report: ✅ passed items, ⚠️ warnings, ❌ blockers.
Suggest fixes for all ⚠️ and ❌ items.
