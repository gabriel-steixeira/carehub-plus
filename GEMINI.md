# CareHub Plus — Antigravity Agent Configuration

## Agent Behavior
- **Plan before acting.** For any task touching more than 1 file, output `implementation_plan.md` first and wait for approval unless the task is trivially small.
- **Turbo mode allowed** for: running `flutter analyze`, `dart format .`, `flutter test`, adding `const`, renaming variables within a single file.
- **Always verify** after implementing: run `flutter analyze` and confirm zero errors before finishing.
- **Prefer surgical edits** — change only what is necessary. Do not reformat unrelated code.
- **Figma access:** When referencing Figma for UI tasks, always use the **browser subagent** to open Figma URLs and capture screenshots. The `read_url_content` tool cannot access Figma (returns 403). Use `docs/Figma.md` for the list of Figma page URLs. Always visually inspect the Figma frame before implementing any screen.

## Context Loading Priority
When starting any task, load context in this order:
1. `AGENTS.md` (always)
2. `.agent/rules/architecture.md` (always)
3. `.agent/rules/design-system.md` (for any UI task)
4. `.agent/rules/flutter-bloc.md` (for any feature/state task)
5. `.agent/rules/firebase.md` (for any data/auth task)
6. `.agent/rules/testing.md` (for test tasks)

## Workflow Triggers
Use the appropriate workflow file when the user says:
- "cria uma nova tela" / "new screen" → `.agent/workflows/new-screen.md`
- "revisa o PR" / "code review" → `.agent/workflows/code-review.md`
- "gera testes" / "generate tests" → `.agent/workflows/generate-tests.md`
- "sincroniza o design" / "sync figma" → `.agent/workflows/sync-design.md`
- "roda o app" / "iniciar emulador" / "testar app" → `.agent/workflows/run-app.md`

## Flutter Emulator & Testing Commands
- List available emulators: `flutter emulators`
- Launch CareHub emulator: `flutter emulators --launch carehub_emulator`
- Run application code: `flutter run`

## Implementation Artifacts
For complex features, generate these files in the project root (delete after task):
- `task.md` — what needs to be done
- `implementation_plan.md` — step-by-step plan with file paths
- `walkthrough.md` — what was changed and why

## Response Style
- Be concise. No filler text.
- When showing code, show the **complete file** (not snippets) unless the file is >300 lines.
- When creating a widget, always show usage example in the same response.
- Ask clarifying questions ONLY if ambiguity would cause the wrong file to be edited.
