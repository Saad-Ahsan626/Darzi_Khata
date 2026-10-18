import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tailor_khata/core/theme/design_tokens.dart';
import 'package:tailor_khata/core/widgets/app_widgets.dart';
import 'package:tailor_khata/features/auth/presentation/providers/startup_provider.dart';
import 'package:tailor_khata/features/dashboard/presentation/widgets/money_card.dart';
import 'package:tailor_khata/features/orders/presentation/widgets/production_stepper.dart';

class _Page {
  const _Page({
    required this.kicker,
    required this.title,
    required this.body,
    required this.example,
    required this.art,
  });

  final String kicker;
  final String title;
  final String body;

  /// What the picture shows, for screen readers.
  final String example;
  final Widget art;
}

const _pages = [
  _Page(
    kicker: '01 — Measurements',
    title: 'Take a measurement\nonce, use it forever',
    body:
        'Formal and casual profiles per garment, in inches or centimetres. '
        'No body diagrams to interpret — just the numbers you already call '
        'out.',
    example: "Example: a customer's saved measurements",
    art: _MeasurementsArt(),
  ),
  _Page(
    kicker: '02 — Production',
    title: "Know what's cut,\nstitched and ready",
    body:
        "Move an order through five stages. Today's and overdue work sit at "
        'the top of the list, called out by label, not by colour alone.',
    example: 'Example: an order in stitching, with deliveries due',
    art: _ProductionArt(),
  ),
  _Page(
    kicker: '03 — Money',
    title: 'Advances, balances,\nnothing forgotten',
    body:
        'Record an advance at intake and the balance is worked out for you. '
        "Deliver with money still owed — the app keeps the amount on the "
        "customer's account.",
    example: 'Example: money outstanding and collected',
    art: _MoneyArt(),
  ),
];

/// Three pages on what the app does, shown once. The last one, or Skip,
/// opens the shop.
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _controller = PageController();
  int _page = 0;

  bool get _last => _page == _pages.length - 1;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _openShop() async {
    await ref.read(launchPreferencesProvider).markShopOpened();
    if (mounted) context.go('/home');
  }

  void _turn(int page) {
    if (MediaQuery.disableAnimationsOf(context)) {
      _controller.jumpToPage(page);
    } else {
      _controller.animateToPage(
        page,
        duration: AppMotion.page,
        curve: AppMotion.curve,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppPalette.white,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(0, AppSpacing.xs, 6, 0),
                // Retired on the last page, where the main button does the
                // same thing.
                child: TextButton(
                  onPressed: _last ? null : _openShop,
                  style: TextButton.styleFrom(
                    foregroundColor: AppPalette.ink55,
                    disabledForegroundColor: const Color.fromRGBO(
                      23,
                      25,
                      24,
                      0.3,
                    ),
                    textStyle: AppTypography.body.copyWith(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  child: const Text('Skip'),
                ),
              ),
            ),
            Expanded(
              child: PageView(
                controller: _controller,
                onPageChanged: (page) => setState(() => _page = page),
                children: [for (final page in _pages) _PageView(page)],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.screenPadding,
                AppSpacing.md,
                AppSpacing.screenPadding,
                AppSpacing.md,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      for (var index = 0; index < _pages.length; index++) ...[
                        if (index > 0) const SizedBox(width: 7),
                        AnimatedContainer(
                          duration: MediaQuery.disableAnimationsOf(context)
                              ? Duration.zero
                              : AppMotion.selection,
                          curve: AppMotion.curve,
                          width: index == _page ? 22 : 5,
                          height: 5,
                          decoration: BoxDecoration(
                            color: index == _page
                                ? AppPalette.carbon
                                : const Color.fromRGBO(23, 25, 24, 0.2),
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                      ],
                      const Spacer(),
                      Semantics(
                        liveRegion: true,
                        child: Text(
                          '${_page + 1} of ${_pages.length}',
                          style: AppTypography.micro.copyWith(
                            fontSize: 11.5,
                            fontFeatures: AppTypography.tabularFigures,
                            color: AppPalette.ink45,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Row(
                    children: [
                      if (_page > 0) ...[
                        IconButton(
                          tooltip: 'Back',
                          onPressed: () => _turn(_page - 1),
                          icon: const Icon(Icons.arrow_back, size: 20),
                          style: IconButton.styleFrom(
                            foregroundColor: AppPalette.carbon,
                            fixedSize: const Size.square(54),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                              side: const BorderSide(
                                color: AppPalette.lineStrong,
                                width: 1.5,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                      ],
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _last ? _openShop : () => _turn(_page + 1),
                          style: ElevatedButton.styleFrom(
                            minimumSize: const Size.fromHeight(54),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Flexible(
                                child: Text(
                                  _last ? 'Continue to My Shop' : 'Next',
                                ),
                              ),
                              const SizedBox(width: 9),
                              const Icon(Icons.arrow_forward, size: 19),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PageView extends StatelessWidget {
  const _PageView(this.page);
  final _Page page;

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    padding: const EdgeInsets.fromLTRB(
      AppSpacing.screenPadding,
      AppSpacing.sm,
      AppSpacing.screenPadding,
      AppSpacing.lg,
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          label: page.example,
          image: true,
          child: ExcludeSemantics(child: page.art),
        ),
        const SizedBox(height: 28),
        Text(
          page.kicker.toUpperCase(),
          style: AppTypography.sectionLabel.copyWith(
            fontSize: 10.5,
            letterSpacing: 10.5 * 0.11,
            color: AppPalette.ink45,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Semantics(
          header: true,
          child: Text(
            page.title,
            style: AppTypography.title.copyWith(
              fontSize: 27,
              height: 1.18,
              letterSpacing: 27 * -0.03,
              color: AppPalette.carbon,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 320),
          child: Text(
            page.body,
            style: AppTypography.body.copyWith(
              height: 1.6,
              fontWeight: FontWeight.w400,
              color: const Color.fromRGBO(23, 25, 24, 0.65),
            ),
          ),
        ),
      ],
    ),
  );
}

/// The light panel the first two pictures sit on.
class _ArtPanel extends StatelessWidget {
  const _ArtPanel({required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Container(
    clipBehavior: Clip.antiAlias,
    decoration: BoxDecoration(
      color: AppPalette.surfaceSunken,
      borderRadius: BorderRadius.circular(22),
      border: Border.all(color: AppPalette.line),
    ),
    child: Stack(
      children: [
        const Positioned(
          left: 0,
          right: 0,
          top: 0,
          height: 10,
          child: AppTickPattern(
            color: Color.fromRGBO(23, 25, 24, 0.18),
            spacing: 9,
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 30, 18, 22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: children,
          ),
        ),
      ],
    ),
  );
}

BoxDecoration _whiteCard([double radius = 13]) => BoxDecoration(
  color: AppPalette.white,
  borderRadius: BorderRadius.circular(radius),
  border: Border.all(color: AppPalette.line),
);

final _tileLabel = AppTypography.micro.copyWith(
  fontSize: 9.5,
  letterSpacing: 9.5 * 0.06,
  color: AppPalette.ink55,
);

final _tileValue = AppTypography.numberMd.copyWith(
  fontSize: 19,
  letterSpacing: 19 * -0.02,
  color: AppPalette.carbon,
);

class _MeasurementsArt extends StatelessWidget {
  const _MeasurementsArt();

  @override
  Widget build(BuildContext context) => _ArtPanel(
    children: [
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
        decoration: _whiteCard(14),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color.fromRGBO(124, 128, 112, 0.18),
              ),
              alignment: Alignment.center,
              child: Text(
                'FS',
                style: AppTypography.body.copyWith(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppPalette.oliveInk,
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Faisal Shah',
                  style: AppTypography.body.copyWith(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w600,
                    color: AppPalette.carbon,
                  ),
                ),
                Text(
                  '2 profiles saved',
                  style: AppTypography.support.copyWith(fontSize: 11.5),
                ),
              ],
            ),
          ],
        ),
      ),
      const SizedBox(height: 10),
      Row(
        children: [
          for (final (label, value, picked) in const [
            ('CHEST', '40.5', false),
            ('SLEEVE', '24.5', true),
            ('LENGTH', '42.0', false),
          ]) ...[
            if (label != 'CHEST') const SizedBox(width: 9),
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: 11,
                ),
                decoration: picked
                    ? BoxDecoration(
                        color: AppPalette.white,
                        borderRadius: BorderRadius.circular(13),
                        border: Border.all(
                          color: AppPalette.carbon,
                          width: 1.5,
                        ),
                      )
                    : _whiteCard(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: picked
                          ? _tileLabel.copyWith(color: AppPalette.oliveInk)
                          : _tileLabel,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(value, style: _tileValue),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
      const SizedBox(height: AppSpacing.md),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: AppPalette.oliveFill14,
          borderRadius: BorderRadius.circular(AppRadii.control),
          border: Border.all(color: AppPalette.oliveBorder),
        ),
        child: Row(
          children: [
            const Icon(Icons.check, size: 15, color: AppPalette.oliveInk),
            const SizedBox(width: AppSpacing.sm),
            Text(
              'Saved · reused on every order',
              style: AppTypography.support.copyWith(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppPalette.oliveInk,
              ),
            ),
          ],
        ),
      ),
    ],
  );
}

class _ProductionArt extends StatelessWidget {
  const _ProductionArt();

  @override
  Widget build(BuildContext context) => _ArtPanel(
    children: [
      Container(
        padding: const EdgeInsets.all(13),
        decoration: _whiteCard(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Sadia Rehman',
                        style: AppTypography.body.copyWith(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w600,
                          color: AppPalette.carbon,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Kameez · 3 pcs · DK-1040',
                        style: AppTypography.support.copyWith(fontSize: 12),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Rs 4,200',
                      style: AppTypography.numberMd.copyWith(
                        fontSize: 14.5,
                        color: AppPalette.carbon,
                      ),
                    ),
                    Text(
                      'balance',
                      style: AppTypography.support.copyWith(
                        fontSize: 10,
                        color: AppPalette.ink55,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 11),
              child: AppDashedLine(),
            ),
            const ProductionStepper(status: 'Stitching'),
          ],
        ),
      ),
      const SizedBox(height: 10),
      Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: 11,
              ),
              decoration: _whiteCard(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('DUE TODAY', style: _tileLabel),
                  const SizedBox(height: AppSpacing.xs),
                  Text('5', style: _tileValue),
                ],
              ),
            ),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: 11,
              ),
              decoration: BoxDecoration(
                color: AppPalette.carbon,
                borderRadius: BorderRadius.circular(13),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'OVERDUE',
                    style: _tileLabel.copyWith(
                      color: const Color.fromRGBO(255, 255, 255, 0.6),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    '3',
                    style: _tileValue.copyWith(color: AppPalette.white),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    ],
  );
}

class _MoneyArt extends StatelessWidget {
  const _MoneyArt();

  @override
  Widget build(BuildContext context) => const MoneyCard(
    label: 'Outstanding across 9 orders',
    amount: 46200,
    tiles: [
      MoneyTile(label: 'Collected', amount: 138300),
      MoneyTile(label: 'This month', amount: 184500),
    ],
  );
}
