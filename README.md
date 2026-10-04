# Tailor Khata

An offline Flutter application for tailor shops to manage customers, reuse
garment measurements, track production and deliveries, and view outstanding
balances in Pakistani rupees.

The app is under active development. Customer and order workflows use local
SQLite storage. The redesign uses carbon black, white, grey olive, and bundled
Inter typography. Phase 1 includes shared tokens, the Material theme, reusable
components, floating glass navigation, and an English-only interface. Individual
screens are being redesigned incrementally in the following phases.

## Current functionality

| Area | Implemented | Remaining work |
| --- | --- | --- |
| Startup | Splash, onboarding, guest entry | Persist guest choice; redesigned screens |
| Customers | Add/edit, search, optional photos, details, order history | Redesigned screens and deletion UI |
| Measurements | Save values per customer and garment | Replace 3D viewer with grouped fields; separate fit profiles and convert units |
| Orders | Create, due-date filters, status changes, delivery/payment confirmation | General editing, measurement linking, payment correctness |
| Dashboard/revenue | Delivery list, balances, period summaries | New layouts and payment-date-based reporting |
| Design foundation | Tokens, Material theme, offline fonts, component library, glass navigation, debug preview | Full feature-screen layouts |
| Login/settings | Placeholder screens | Authentication, shop settings, language/unit preferences |
| WhatsApp | Buttons with placeholder feedback | Actual prepared-conversation integration |
| Invoices/backup/cloud | Planned | Export, restore, accounts, synchronization |

The interface is English-only. Previously stored optional Urdu customer names
remain in storage and are preserved when editing a customer. The existing 3D
measurement viewer remains until its form-based replacement in Phase 4.

## Run locally

The development SDK used for this project is Flutter **3.41.9**, with Dart
**3.11.5**. `pubspec.yaml` requires Dart `^3.11.5`.

Install a compatible Flutter SDK, Android SDK/toolchain, and an emulator or attach
an Android device with USB debugging enabled. Then run:

```sh
flutter doctor
flutter pub get
flutter devices
flutter run -d <device-id>
```

No backend configuration, API keys, or Firebase project are required for current
guest workflows. Package installation needs internet access or a populated Pub
cache; the installed app stores records locally and uses bundled fonts.

```sh
flutter build apk --debug
```

Android minimum SDK is 24. The application ID is `com.example.tailor_khata` and
release builds currently use debug signing. Configure production identity and
signing before distribution.

An iOS runner is checked in; iOS build/device verification requires macOS and
Xcode. Check photo-access configuration before shipping. Desktop/web scaffold
directories may exist locally but are ignored by Git. Windows/Linux database
initialization and web-compatible storage/photos are not configured in the app.

## Architecture

```text
lib/
  main.dart
  core/
    database/       SQLite initialization, schema and migrations
    error/          Shared failures and exceptions
    providers/      Database dependency injection
    routing/        go_router routes
    shell/          Navigation shell
    theme/          Shared presentation theme and tokens
    widgets/        Reusable presentation components; values and callbacks only
    dev/            Debug-only component preview
    usecase/        UseCase contract
  features/
    auth/
    customers/
    dashboard/
    measurements/
    orders/
    settings/
```

Customers, measurements, and orders have `domain`, `data`, and `presentation`
directories. The Clean Architecture responsibilities are:

- **Domain:** entities, repository contracts, use cases, and business rules.
  This layer must not depend on Flutter widgets or SQLite APIs.
- **Data:** serialization, local data sources, and repository implementations.
  Database exceptions become typed failures.
- **Presentation:** screens, widgets, Riverpod state, and loading/error feedback.
  Screens consume domain operations rather than query the database.
- **Composition:** Riverpod providers construct the dependency chain.

Customer and order operations follow:

```text
Screen -> Notifier -> Use case -> Repository contract
                                |
                     Repository implementation -> Local data source -> SQLite
```

Existing gaps: the active measurement notifier directly uses its data source;
dashboard calculations live in widgets. These should move behind domain operations
during feature work. Auth/settings have presentation placeholders.

Theme/token files under `core` are shared **presentation** dependencies. Domain
and data code must not import the theme or Flutter-specific design values.

## Design system

| Base color | Hex | Role |
| --- | --- | --- |
| Carbon black | `#171918` | Primary text and strong surfaces |
| White | `#FFFFFF` | Main backgrounds and text on carbon |
| Grey olive | `#7C8070` | Accents, fills, and selection details |

Derived neutral/olive tones provide surfaces, borders, and secondary text. Status
and validation messages use explicit labels/icons rather than additional red/green
accents. Use `ink70` on light surfaces and `onCarbonMuted` on carbon surfaces;
grey olive is not appropriate for small text on white.

```dart
import 'package:tailor_khata/core/theme/design_tokens.dart';
```

The barrel exports `AppPalette`, `AppTypography`, `AppSpacing`, `AppRadii`,
`AppSizing`, `AppMotion`, `AppGlass`, and `AppShadows`. `AppTheme.lightTheme` maps
tokens to Material controls. `AppColors` contains deprecated aliases only.

The theme covers text, button states, inputs, cards, tabs, dialogs, bottom sheets,
snackbars, progress, text selection, and navigation controls. Shared widgets are
exported by `core/widgets/app_widgets.dart`; their usage is documented in
`core/widgets/README.md`. They import no feature entities, providers, or storage.

Floating navigation appears on Home, Customers, Orders, and Settings. Detail,
entry, and measurement routes use the full viewport. Keyboard visibility hides
the navigation. Its layout reserves space for lists and bottom safe areas; add
actions are in the Customers and Orders headers and empty states.

Glass has a bounded blur, fine borders, and solid light/dark fallbacks. High
contrast uses opaque surfaces automatically; callers can disable blur explicitly.
Custom selection/navigation transitions respect reduced motion.

### Review the foundation

In a debug build, open **Settings → Design system preview**, or start there:

```sh
flutter run -d <device-id> --dart-define=SHOW_DESIGN_PREVIEW=true
```

The `/design-preview` route and Settings entry are available only in debug mode.
The gallery shows button states, persistent-label fields, validation, date picking,
cards, light/dark glass and solid fallbacks, badges, selection controls, loading,
empty/error feedback, a sheet, a confirmation dialog, and navigation. Sample
interactions do not access the database.

Inter weights 400/500/600/700 are bundled in `assets/fonts/inter/`, registered in
`pubspec.yaml`, and load without runtime network requests. The SIL Open Font
License is included and registered with Flutter. Font provenance is documented
alongside the assets.

Local references under `idea/UI/` include HTML, screenshots, boards, logos, and
source tokens. This folder is ignored by Git and is not required at runtime.
Tracked Dart tokens are the implementation source of truth.

## Persistence and dependencies

`DatabaseHelper` opens `tailor_khata.db` at schema version **3**, with foreign keys
enabled. Its tables are `customers`, `measurements`, and `orders`. Measurements
contain a JSON value map; orders contain status, amounts, due dates, and an optional
measurement reference. Customer deletion cascades to measurements/orders;
measurement deletion clears an order's measurement reference.

Photos are files in the app's documents directory. `shared_preferences` stores
onboarding completion. `ownerId`/`syncStatus` reserve fields for future cloud work;
they do not implement synchronization or account isolation. Backup/restore is
not yet available.

| Purpose | Packages |
| --- | --- |
| State/composition and routing | `flutter_riverpod`, `go_router` |
| Storage | `sqflite`, `path`, `shared_preferences` |
| Results/equality | `fpdart`, `equatable` |
| IDs/formatting | `uuid`, `intl` |
| Photos/files | `image_picker`, `path_provider` |
| Existing measurement viewer | `flutter_cube`, pending replacement |
| Development checks | `flutter_test`, `flutter_lints`, `sqflite_common_ffi` |

## Validation and known gaps

```sh
flutter analyze --no-pub
flutter test --no-pub test/presentation_foundation_test.dart
```

The tracked foundation tests use in-memory provider fixtures, bundled fonts, and
the real app routes. They verify navigation/add/back behavior, keyboard and safe
areas, fields, disabled/loading buttons, glass fallbacks, 360/390px widths with
larger text, and preservation of stored customer names during English edits.

Two older database tests may exist locally under `test/`; they remain ignored by
Git. They use a persistent database and a fixed customer ID, so the insertion
test can fail on repeated runs. Use the explicit test command above for repeatable
foundation checks. Isolated database and broader feature tests are still needed.

Important existing issues for subsequent feature work:

- Production-status updates can overwrite the paid amount with the order total.
- Revenue is attributed to order creation dates rather than payment dates.
- Some saves show success before persistence completes.
- Formal/Casual selection shares one measurement record; values are formatted
  strings rather than canonical numbers.
- New-order customer preselection and measurement linking are incomplete.
- WhatsApp feedback does not send a message.

These are feature/data-flow tasks; theme integration does not change their logic.
Phase 1's visual foundation is implemented. The remaining phases are dashboard,
customer workflow, form-based measurements, orders/payments, remaining screens,
and complete end-to-end verification.
