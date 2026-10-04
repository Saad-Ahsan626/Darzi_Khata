# Tailor Khata

An offline Flutter application for tailor shops to manage customers, reuse
garment measurements, track production and deliveries, and view outstanding
balances in Pakistani rupees.

The app is under active development. Customer and order workflows use local
SQLite storage. The redesign uses carbon black, white, grey olive, and bundled
Inter typography. Shared tokens and the Material theme are implemented;
individual screens are being redesigned incrementally.

## Current functionality

| Area | Implemented | Remaining work |
| --- | --- | --- |
| Startup | Splash, onboarding, guest entry | Persist guest choice; redesigned screens |
| Customers | Add/edit, search, optional photos, details, order history | Redesigned screens and deletion UI |
| Measurements | Save values per customer and garment | Replace 3D viewer with grouped fields; separate fit profiles and convert units |
| Orders | Create, due-date filters, status changes, delivery/payment confirmation | General editing, measurement linking, payment correctness |
| Dashboard/revenue | Delivery list, balances, period summaries | New layouts and payment-date-based reporting |
| Design foundation | Tokens, Material theme, offline fonts, migrated colors/fonts | Component library, floating glass navigation, full layouts |
| Login/settings | Placeholder screens | Authentication, shop settings, language/unit preferences |
| WhatsApp | Buttons with placeholder feedback | Actual prepared-conversation integration |
| Invoices/backup/cloud | Planned | Export, restore, accounts, synchronization |

The redesign references are English-only and use form-based measurements. Some
existing screens still contain Urdu labels and the 3D model while their dedicated
redesign stages are pending. Theme integration does not replace those workflows.

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
snackbars, progress, text selection, and existing navigation controls. Custom glass
navigation and complete screen layouts belong to later stages.

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
```

Two database tests exist in local workspaces under `test/`. That directory is
ignored by Git, so fresh clones do not receive them. Where present, run
`flutter test --no-pub`. They use a persistent database and a fixed customer ID;
the insertion test can fail on repeated runs. Isolated databases and broader
feature tests are needed.

Important existing issues for subsequent feature work:

- Production-status updates can overwrite the paid amount with the order total.
- Revenue is attributed to order creation dates rather than payment dates.
- Some saves show success before persistence completes.
- Formal/Casual selection shares one measurement record; values are formatted
  strings rather than canonical numbers.
- New-order customer preselection and measurement linking are incomplete.
- WhatsApp feedback does not send a message.

These are feature/data-flow tasks; theme integration does not change their logic.
Next stages are reusable components, floating navigation, dashboard/customer
layouts, form-based measurements, order workflow, and settings.
