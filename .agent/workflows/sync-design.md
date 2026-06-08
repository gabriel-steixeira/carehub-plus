# Workflow: Sync Design System from Figma

## Trigger
User says: "sincroniza o design", "sync figma", "atualiza as cores"

## Steps

### Step 1 — Open Figma
- Figma file: https://www.figma.com/file/HWnS5C49Kc86lRwuMbzEjx/CareHub-Plus
- Navigate to: Identidade Visual page

### Step 2 — Extract tokens
- [ ] Colors: document all fills from color swatches
- [ ] Typography: document all text styles (family, size, weight, line height)
- [ ] Spacing: document padding/margin values from component specs
- [ ] Border radius: document from card/button components

### Step 3 — Compare with current code
- [ ] Open `lib/core/theme/app_theme.dart`
- [ ] Open `lib/core/theme/app_typography.dart`
- [ ] Open `lib/core/theme/app_spacing.dart`
- [ ] List differences: added, removed, changed tokens

### Step 4 — Update files
- [ ] Update only the values that changed
- [ ] Never remove a token without checking all usages first (`grep` the codebase)
- [ ] If a token is removed from Figma, mark as `@deprecated` for one cycle before deleting

### Step 5 — Verify
- [ ] Run `flutter analyze`
- [ ] Run `flutter test`
- [ ] Build the app and visually verify affected screens
