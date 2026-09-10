# Theme and Design System Reference

This document codifies the design tokens, 8pt spacing system, compact mobile typography, and iconography rules.

---

## 1. Strict 8pt Spacing Tokens

Never use arbitrary padding or margins (e.g. 10, 14, 18). Always use multiples of 4 or 8:

```dart
class AppSpacing {
  AppSpacing._();

  static const double xxs = 2.0;
  static const double xs  = 4.0;
  static const double sm  = 8.0;
  static const double md  = 12.0;
  static const double lg  = 16.0;  // Standard screen padding
  static const double xl  = 20.0;  // Large screen padding
  static const double xxl = 24.0;
  static const double xxxl = 32.0;
  static const double huge = 48.0;

  // Insets helpers — use literal doubles because static const references
  // are NOT compile-time constants when referenced cross-field in Dart.
  static const screenPadding  = EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0);
  static const cardPadding    = EdgeInsets.all(16.0);
  static const compactPadding = EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0);
}
```

---

## 2. Compact Mobile Typography Scale

AI-generated UI often makes headers > 24px, cramping 360–390dp mobile screens. Enforce this compact scale:

```dart
class AppTypography {
  AppTypography._();

  // Hero title / Big numbers (e.g., wallet balance, summary total)
  static const TextStyle heroTitle = TextStyle(
    fontSize: 20.0,
    fontWeight: FontWeight.w700,
    height: 1.2,
  );

  // Section Heading / Card Title
  static const TextStyle sectionHeading = TextStyle(
    fontSize: 15.0,
    fontWeight: FontWeight.w600,
    height: 1.3,
  );

  // List Tile Title / Subheading
  static const TextStyle listTitle = TextStyle(
    fontSize: 14.0,
    fontWeight: FontWeight.w500,
    height: 1.35,
  );

  // Body Text (Default Mobile)
  static const TextStyle body = TextStyle(
    fontSize: 13.0,
    fontWeight: FontWeight.w400,
    height: 1.45,
  );

  // Secondary Metadata / Subtitle (60% opacity)
  static TextStyle secondary(BuildContext context) => TextStyle(
    fontSize: 12.0,
    fontWeight: FontWeight.w400,
    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
    height: 1.4,
  );

  // Micro Labels / Tags / Timestamps
  static const TextStyle micro = TextStyle(
    fontSize: 10.5,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.2,
  );
}
```

---

## 3. Surface Contrast & Radii Rules

```dart
class AppRadii {
  AppRadii._();

  // Micro components: badges, tags, chips
  static const double micro = 6.0;
  static const Radius microRadius = Radius.circular(micro);
  // BorderRadius.circular is NOT a const constructor — use static final (correct).
  static final BorderRadius microBorder = BorderRadius.circular(micro);

  // Interactive controls: buttons, text inputs, dropdowns
  static const double control = 10.0;
  static const Radius controlRadius = Radius.circular(control);
  // BorderRadius.circular is NOT a const constructor — use static final (correct).
  static final BorderRadius controlBorder = BorderRadius.circular(control);

  // Containers: cards, modal sheets, dialogs
  static const double surface = 16.0;
  static const Radius surfaceRadius = Radius.circular(surface);
  // BorderRadius.circular is NOT a const constructor — use static final (correct).
  static final BorderRadius surfaceBorder = BorderRadius.circular(surface);
}
```

### Clean Surface Border
```dart
BoxDecoration cleanSurface(BuildContext context) {
  final theme = Theme.of(context);
  return BoxDecoration(
    color: theme.colorScheme.surface,
    borderRadius: AppRadii.surfaceBorder,
    border: Border.all(
      color: theme.dividerColor.withOpacity(0.08),
      width: 1.0,
    ),
  );
}
```

---

## 4. Iconography Constraints

1. **Avoid Generic Material 2 Filled Icons**:
   - Strictly prefer `_outlined` or `_rounded` variants (e.g. `Icons.notifications_outlined`, `Icons.settings_outlined`).
   - If using `lucide_icons` or `phosphor_flutter`, maintain consistent line weight (1.5px or 2.0px).
2. **Icon Sizing**:
   - Micro inline icon: `16px`
   - List tile / button icon: `20px`
   - Primary action icon: `24px`
   - Tap Target: Wrap in `IconButton` or `Padding` ensuring at least `48x48px` accessible touch target.
3. **States**:
   - Inactive: Secondary neutral color (`colorScheme.onSurface.withOpacity(0.6)`).
   - Active: Primary accent color or filled variant.
