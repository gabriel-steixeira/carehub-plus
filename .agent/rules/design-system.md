# Design System Rules — CareHub Plus

## Source of Truth
Figma: https://www.figma.com/file/HWnS5C49Kc86lRwuMbzEjx/CareHub-Plus
Always verify against Figma before implementing any UI change.

## Color Palette (lib/core/theme/app_theme.dart)
```dart
// PRIMARY
static const Color primary = Color(0xFF7B61C8);       // Purple — main accent
static const Color primaryLight = Color(0xFFAF9EE0);  // Hover/disabled states
static const Color primaryDark = Color(0xFF5A44A8);   // Pressed state

// BACKGROUND & SURFACES
static const Color background = Color(0xFFFFFFFF);
static const Color surface = Color(0xFFF8F6FF);       // Subtle purple-tinted card bg
static const Color surfaceVariant = Color(0xFFF0ECFD);

// GRADIENT (Figma: purple → white → pink)
static const LinearGradient primaryGradient = LinearGradient(
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
  colors: [Color(0xFFA78BDB), Color(0xFFFFFFFF), Color(0xFFFACFE8)],
  stops: [0.09, 0.57, 1.0],
);

// TEXT
static const Color textPrimary = Color(0xFF1A1A2E);
static const Color textSecondary = Color(0xFF6B6B8A);
static const Color textHint = Color(0xFFB0B0C8);
static const Color textInverse = Color(0xFFFFFFFF);

// FEEDBACK
static const Color success = Color(0xFF437A22);
static const Color error = Color(0xFFD32F2F);
static const Color warning = Color(0xFFF59E0B);
static const Color info = Color(0xFF006494);

// DIVIDER / BORDER
static const Color divider = Color(0xFFE8E4F7);
static const Color border = Color(0xFFD4CEEF);
```

## Typography (lib/core/theme/app_typography.dart)
- **Font family:** Inter (load via google_fonts or local asset)
- All text styles defined as static `TextStyle` constants
- Never use a raw `TextStyle(...)` inline in a widget

```
AppTypography.displayLarge   // 32px, w700 — screen titles
AppTypography.headlineMedium // 24px, w600 — section headers
AppTypography.titleLarge     // 18px, w600 — card titles
AppTypography.titleMedium    // 16px, w500 — subtitles
AppTypography.bodyLarge      // 16px, w400 — body text
AppTypography.bodyMedium     // 14px, w400 — secondary body
AppTypography.labelLarge     // 14px, w600 — buttons
AppTypography.labelSmall     // 11px, w500 — badges, chips
```

## Spacing (lib/core/theme/app_spacing.dart)
```dart
// 4px grid — ALWAYS use these, never hardcode pixels
static const double xs  = 4.0;
static const double sm  = 8.0;
static const double md  = 16.0;
static const double lg  = 24.0;
static const double xl  = 32.0;
static const double xxl = 48.0;
static const double xxxl = 64.0;

// Radius
static const double radiusXs  = 4.0;
static const double radiusSm  = 8.0;
static const double radiusMd  = 12.0;
static const double radiusLg  = 16.0;
static const double radiusXl  = 24.0;
static const double radiusFull = 999.0;
```

## Component Rules
- **AppButton:** primary (filled purple), secondary (outlined), ghost (text only), destructive (red)
- **AppTextField:** always use `AppTextField`, never raw `TextField` or `TextFormField` directly
- **AppCard:** white background, `radiusMd`, `shadow-sm` (2px blur, 8% opacity)
- **Loading state:** always `AppLoading()` centered widget — never `CircularProgressIndicator` raw
- **Error state:** always `AppErrorView(message: ..., onRetry: ...)` — never raw `Text('Error')`
- **Empty state:** always `AppEmptyView(message: ..., icon: ...)` — never raw `Text('Vazio')`

## Design Anti-Patterns (never do)
- Hardcoded `Color(0xFF...)` anywhere except `app_theme.dart`
- Raw `TextStyle(fontSize: 14)` inline in widgets
- `SizedBox(height: 20)` — use `SizedBox(height: AppSpacing.md)` instead
- `BorderRadius.circular(8)` inline — use `BorderRadius.circular(AppSpacing.radiusSm)`
- Different loading indicators in different screens
