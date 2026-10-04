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
- Inter is declared as a font-family token. Bundling and registering its font
  assets is part of the later theme integration, not this token-only change.
- Reference viewport dimensions are for design comparison. Do not force screen
  sizes or block smaller devices. Respect text scaling and safe areas.
- Glass saturation is a design reference; a Flutter blur filter does not perform
  CSS saturation automatically. Apply effects in widgets and use the opaque
  fallbacks when glass is disabled. Match shadow rendering during that work.
- Widgets must respect the platform's reduced-motion preference.

## Incremental adoption

The existing `AppColors` and `AppTheme` remain the legacy presentation API until
theme integration. This change only centralizes the new design values; it does
not recolor existing screens or change their behavior. New presentation work
should use the token barrel rather than copy values from `idea/`, which is ignored
by Git. No runtime dependency on that directory is required.
