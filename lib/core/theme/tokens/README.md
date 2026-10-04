# Tailor Khata design tokens

The runtime source of truth for the new design is this directory. Presentation
code imports `package:tailor_khata/core/theme/design_tokens.dart`.

| Namespace | Responsibility |
| --- | --- |
| `AppPalette` | Three base colors, derived tones, translucent surfaces |
| `AppTypography` | Inter text styles, weights, tracking, tabular figures |
| `AppSpacing` | Spacing scale, screen padding, gutters |
| `AppRadii` | Control, card, sheet, pill, icon radii |
| `AppSizing` | Minimum hit target and reference viewport |
| `AppMotion` | Durations and easing |
| `AppGlass` | Blur, saturation reference, opaque fallback colors |
| `AppShadows` | Selection, navigation, sheet, modal shadows |

## Architecture boundary

These are shared presentation values, placed beside the existing application
theme. They depend only on Flutter painting and animation primitives. They do not
depend on repositories, use cases, entities, state providers, or database code.
Feature domain and data code must not import them. Tokens contain no widgets,
business rules, asset loading, or runtime design-file parsing.

## Reference and translation decisions

- Values follow `idea/UI/tokens/tailor-khata-tokens.json`; this is more complete
  than the handoff's Dart export. Shadows follow the HTML's actual UI surfaces.
- Flutter letter spacing is in logical pixels, so JSON em tracking is multiplied
  by font size. Numeric styles follow the JSON, which specifies no tracking for
  `numberLg`; the Dart export adds tracking that is not in that specification.
- Section-label capitalization belongs to the consuming widget.
- Grey olive is for accents and fills; use carbon or appropriate darker ink for
  readable small text. Text and status labels must communicate meaning as well
  as their visual styling.
- Inter weights 400, 500, 600, and 700 are bundled under `assets/fonts/inter/`
  and registered in `pubspec.yaml`. Typography does not fetch fonts at runtime.
- Reference viewport dimensions are for design comparison. Do not force screen
  sizes or block smaller devices. Respect text scaling and safe areas.
- Glass saturation is a design reference; a Flutter blur filter does not perform
  CSS saturation automatically. Apply effects in widgets and use the opaque
  fallbacks when glass is disabled. Match shadow rendering during that work.
- Widgets must respect the platform's reduced-motion preference.

## Incremental adoption

`AppTheme.lightTheme` maps these values to Material controls, and feature
presentation code uses `AppPalette` and `AppTypography`. `AppColors` is a
deprecated compatibility facade with aliases only; it defines no separate
palette. Existing layouts remain in place while their full redesign proceeds.
New presentation work should use the token barrel rather than copy values from
`idea/`, which is ignored by Git. No runtime dependency on that directory is
required. Supporting text on light surfaces uses `ink70`; carbon surfaces use
`onCarbonMuted` instead.
