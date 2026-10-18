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
| Startup | Animated splash that opens the database, onboarding, guest entry | Persist guest choice; redesigned onboarding and welcome |
| Customers | Redesigned list, add/edit, customer page and delete; search, photos, notes, measurement profiles, order history | Filter on the order history |
| Measurements | Grouped fields for seven garments, Formal/Casual profiles, in/cm, stitching note, editor with keypad and previous value | Editing garment field sets in Settings |
| Orders | Redesigned list with All/Today/Upcoming/Overdue filters; new and edit form with pieces, fabric, cutter note and a linked measurement profile; order page with production timeline and payments; separate stage, payment and delivery steps; payment undo and removal; delete | Receipts; filters on the customer's order history |
| Dashboard/revenue | Home with the month's billed, collected and outstanding money, work in progress, today's deliveries with Deliver/Update, overdue link; Revenue by this month, last month, year or custom dates with a six-month chart and the payments received, copied as CSV | Exporting to a file |
| Design foundation | Tokens, Material theme, offline fonts, component library, glass navigation, debug preview | Full feature-screen layouts |
| Login/settings | Placeholder screens; stored shop settings | Authentication, settings screen, language/unit preferences |
| WhatsApp | Reminder sheet that opens WhatsApp with an editable message for the order's stage and balance; nothing is sent by the app | Confirmation message on new orders; Urdu text |
| Invoices/backup/cloud | Planned | Export, restore, accounts, synchronization |

The interface is English-only. Previously stored optional Urdu customer names
remain in storage and are preserved when editing a customer.

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

Customers, measurements, orders, and settings have `domain`, `data`, and
`presentation` directories. The Clean Architecture responsibilities are:

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
during feature work. Auth has presentation placeholders; settings has storage
and providers behind a placeholder screen.

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

Redesigned screens draw their own headers instead of an app bar. Status-bar
icons are dark by default (set in `main.dart`); the splash and carbon headers
switch them to light.

The splash plays once: the button mark is sewn on over 1.2 seconds and the
screen fades to onboarding or the welcome screen. It opens the database
meanwhile, shows a progress sweep only if that takes longer than 400ms, and
with reduced motion shows the finished mark immediately.

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

`DatabaseHelper` opens `tailor_khata.db` at schema version **5**, with foreign keys
enabled. Existing databases are upgraded in place by
`core/database/database_migrations.dart`.

| Table | Contents |
| --- | --- |
| `customers` | Name, phone, address, photo path, optional note |
| `measurements` | One profile per customer, garment and fit (Formal/Casual): a JSON map of field to inches, the unit it is shown in, a stitching note, last update, and for each changed field the value it held before |
| `orders` | Order number, garment, pieces, fabric, cutter note, due date, total, optional measurement reference; current status and paid total |
| `payments` | One row per payment: amount, method (cash, bank, Easypaisa), date, whether it was the advance |
| `order_status_events` | One row each time an order enters a stage, with the time |
| `shop_settings` | A single row: shop name, owner, phone, address, hours, order prefix, next order number, default unit |

Measurement values are stored in inches whichever unit a profile is shown in.
An order's `status` and paid total (the `advancePaid` column) repeat the latest
status event and the sum of its payments. They change only through the
operations that also write those rows: change status, deliver, record payment
and delete payment. Editing an order's details does not touch them. Order
numbers come from a counter in `shop_settings` and are not reused after a
deletion; `ShopSettings.orderLabel` formats them as `TK-0042`.

Customer deletion cascades to measurements/orders; order deletion cascades to
payments and status events; measurement deletion clears an order's measurement
reference.

When version 3 data is upgraded, measurement text such as `40.5"` becomes
numbers in a Formal Fit profile, the old order notes become the fabric, orders
are numbered by creation date, and each order's paid amount becomes one cash
payment dated at order creation. Only creation and delivery times were
recorded before, so earlier stages in the history carry the creation time.
Version 5 adds the previous values (empty for existing profiles) and renames
the garment "Pant-Coat" to "Suit" in measurements and orders.

The garments and the fields each is measured by are listed in
`measurements/domain/entities/garment_template.dart`. A saved value outside a
garment's field set is shown under "Other" rather than hidden.

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
| Links | `url_launcher` (opens WhatsApp) |
| Development checks | `flutter_test`, `flutter_lints`, `sqflite_common_ffi` |

## Validation and known gaps

```sh
flutter analyze --no-pub
flutter test --no-pub \
  test/presentation_foundation_test.dart test/splash_screen_test.dart \
  test/customer_screens_test.dart test/customer_activity_test.dart \
  test/customer_repository_test.dart test/order_flow_test.dart \
  test/order_reminder_test.dart test/order_repository_test.dart \
  test/dashboard_test.dart \
  test/measurement_screen_test.dart \
  test/measurement_repository_test.dart test/measurement_profile_test.dart \
  test/shop_settings_repository_test.dart \
  test/database_migration_test.dart
```

The tracked foundation tests use in-memory provider fixtures, bundled fonts, and
the real app routes. They verify navigation/add/back behavior, keyboard and safe
areas, fields, disabled/loading buttons, glass fallbacks, 360/390px widths with
larger text, and preservation of stored customer names during English edits.

The order flow tests use the same fixtures. They cover the order page (money,
stage and due date), changing the stage without touching payments, delivering
with a balance or recording the payment first, a plain confirmation when
nothing is owed, payments by method with undo, refusing more than the balance,
the WhatsApp link and message, deleting, the list's counts, overdue filter and
empty filters, and the order form: the customer it was started from, the linked
measurement profile, the balance kept in view, required details, the advance
limit, picking a customer, the prompt before leaving, and editing an order
without changing its payments or number. The reminder test covers due-date
sorting, each reminder message, the wa.me link and rupee input grouping.

The dashboard test covers how money is counted (orders are billed on the day
they are taken, payments collected on the day they are received), periods,
the six-month totals and labels; Home's figures, an earlier month, delivering
and moving a stage from Home, and opening today's orders; and Revenue's
periods, payments, opening an order from a payment and the CSV copy.

The measurement tests cover the grouped fields, the draft kept until "Save
Profile", discarding, the editor's steps, fractions, keypad and previous value,
centimeter profiles stored in inches, a new profile, the prompt before
switching fit or leaving with unsaved changes, and a narrow phone with larger
text. The profile test covers which previous value each field keeps, the
garment field sets, and how values are formatted.

The customer tests cover the list (A–Z order, status lines, search, empty and
no-match states), the form (required name and 11-digit phone, a save that
waits for storage, the failure sheet and retry), the customer page (summary,
measurement profiles, order history) and deletion. They also run the screens
at 360px with larger text. The activity test covers the rules behind each
customer's status line. The splash test covers the drawing sequence, the wait
for slow storage, reduced motion and the retry after a failure.

The database tests run against SQLite through `sqflite_common_ffi`, each on its
own temporary file opened with `DatabaseHelper.atPath`. The migration test
builds a version 3 database, upgrades it, and checks the converted data and
that the structure matches a newly created database. The repository tests cover
order numbering, status history, payments, delivery, editing, measurement
profiles, shop settings, the customer note, and that deleting a customer also
clears their orders and measurements from the lists the screens hold.

Two older database tests may exist locally under `test/`; they remain ignored by
Git. They use a persistent database and a fixed customer ID, so the insertion
test can fail on repeated runs. Use the explicit test command above for repeatable
checks. Screen tests for settings are still needed.

Important existing issues for subsequent feature work:

- Shop settings are stored but have no screen yet, so reminders leave out the
  shop name and hours until it exists.

These are feature/data-flow tasks; theme integration does not change their logic.
Phase 1's visual foundation, the data model, the customer workflow, the
measurement screens, the order and payment screens, Home and Revenue, and the
animated splash are implemented. The remaining phases are onboarding, welcome,
settings and the app icon, then complete end-to-end verification.
