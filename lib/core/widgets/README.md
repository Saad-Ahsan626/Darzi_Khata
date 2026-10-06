# Shared presentation components

Import `package:tailor_khata/core/widgets/app_widgets.dart` from presentation code.
These components accept values and callbacks. They never read Riverpod providers,
feature entities, repositories, use cases, database APIs, or navigation routes.
Feature widgets translate their business state into labels and visual variants.

| Component | Use |
| --- | --- |
| `AppButton` / `AppIconButton` | Primary, outlined, olive, destructive, text, loading, disabled and named icon actions |
| `AppBoxedIconButton` | Bordered header actions (back, edit, more) on light or carbon backgrounds |
| `AppTextField` | Persistent label, text/phone/amount/search inputs, helper text and caller validation |
| `AppDateField` | A labeled date picker; caller owns the value |
| `AppCard` | White, carbon and selected surfaces; optional tap callback |
| `GlassSurface` | Clipped light/dark blur and opaque fallbacks |
| `AppSelectionChip` / `AppSegmentedControl` | Keyboard-accessible selection with semantic selected states |
| `AppStatusBadge` | Status/payment label, optional icon and visual tone |
| `AppSectionLabel` / `AppMoneyText` / `AppSeparator` | Section hierarchy, tabular Rs amounts and separation |
| `AppFeedback` / `AppLoading` | Empty, error, retry and loading states |
| `AppDashedLine` / `AppDashedBox` / `AppTickPattern` / `AppIconTile` | Dashed rules and outlines, tape-tick texture for carbon surfaces, and the icon tile that heads empty states, sheets and dialogs |
| `AppBottomNavigation` | Destinations and selection supplied by the shell |

```dart
AppTextField(
  label: 'Full name',
  controller: nameController,
  validator: validateName,
);
AppButton(label: 'Save customer', isLoading: isSaving, onPressed: saveCustomer);
AppStatusBadge(label: statusLabel, icon: statusIcon, tone: badgeTone);
```

Use `expand: false` for inline buttons. Labels wrap rather than shrink accessible
text. Buttons and selection controls have at least 48px hit targets. Segments
stack when text is large or the available width is small. Motion respects
`MediaQuery.disableAnimations`; navigation announces selected destinations.

Carbon cards inherit white text/icons. Explicit text styles should choose the
appropriate color; `AppTypography.support` contains ink intended for light
surfaces. Use `onCarbonMuted` for supporting text on carbon.

Place dark glass over carbon backgrounds. Prefer opaque cards for forms and
financial detail. High contrast disables blur automatically; `blurEnabled: false`
lets a caller select the opaque fallback. Blur is clipped to the surface bounds,
and shadows sit outside the clip. CSS saturation from the handoff is a reference,
not a Flutter blur operation.

Review variants in Settings → Design system preview during debug development,
or run with `--dart-define=SHOW_DESIGN_PREVIEW=true`. The preview uses sample values
and callbacks only. Shared components and the preview use tokens rather than
depending on the ignored `idea/` folder.
