import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tailor_khata/core/routing/app_router.dart';
import 'package:tailor_khata/core/theme/app_theme.dart';
import 'package:tailor_khata/core/theme/design_tokens.dart';
import 'package:tailor_khata/features/auth/presentation/providers/startup_provider.dart';
import 'package:tailor_khata/features/auth/presentation/screens/splash_screen.dart';
import 'package:tailor_khata/features/auth/presentation/screens/welcome_screen.dart';
import 'package:tailor_khata/features/auth/presentation/widgets/sewn_button_mark.dart';

Future<void> _pumpSplash(
  WidgetTester tester, {
  required FutureOr<String> Function() openRecords,
  bool reduceMotion = false,
}) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final router = createAppRouter(initialLocation: '/splash');
  addTearDown(router.dispose);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        startupRouteProvider.overrideWith((ref) => openRecords()),
      ],
      child: MaterialApp.router(
        theme: AppTheme.lightTheme,
        routerConfig: router,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(disableAnimations: reduceMotion),
          child: child!,
        ),
      ),
    ),
  );
}

SewnButtonMark _mark(WidgetTester tester) =>
    tester.widget(find.byType(SewnButtonMark));

void _expectFinishedMark(WidgetTester tester) {
  final mark = _mark(tester);
  expect(mark.rim, 1);
  expect(mark.holes, 1);
  expect(mark.firstStitch, 1);
  expect(mark.secondStitch, 1);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    final font = FontLoader(AppTypography.fontFamily);
    for (final weight in ['Regular', 'Medium', 'SemiBold', 'Bold']) {
      font.addFont(rootBundle.load('assets/fonts/inter/Inter-$weight.ttf'));
    }
    await font.load();
    final icons = FontLoader('MaterialIcons');
    icons.addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
    await icons.load();
  });

  testWidgets('sews the mark on, then opens the next screen', (tester) async {
    await _pumpSplash(tester, openRecords: () => '/welcome');

    // First frame: a quarter of the rim, nothing else yet.
    expect(_mark(tester).rim, closeTo(0.246, 0.001));
    expect(_mark(tester).holes, 0);
    expect(_mark(tester).secondStitch, 0);

    // The rim is drawn before the holes and stitches are finished.
    await tester.pump(const Duration(milliseconds: 800));
    expect(_mark(tester).rim, 1);
    expect(_mark(tester).holes, inExclusiveRange(0, 1));
    expect(_mark(tester).firstStitch, 0);

    await tester.pump(const Duration(milliseconds: 400));
    _expectFinishedMark(tester);
    expect(find.text('Tailor Khata'), findsOneWidget);
    expect(find.text('OFFLINE LEDGER'), findsOneWidget);

    // Records opened long ago, so no progress sweep was ever shown.
    expect(find.bySemanticsLabel('Opening your records'), findsNothing);

    await tester.pumpAndSettle();
    expect(find.byType(WelcomeScreen), findsOneWidget);
    expect(find.byType(SplashScreen), findsNothing);
  });

  testWidgets('holds the finished mark while records open slowly', (
    tester,
  ) async {
    final records = Completer<String>();
    await _pumpSplash(tester, openRecords: () => records.future);

    await tester.pump(const Duration(milliseconds: 300));
    expect(find.bySemanticsLabel('Opening your records'), findsNothing);
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.bySemanticsLabel('Opening your records'), findsOneWidget);

    await tester.pump(const Duration(seconds: 3));
    expect(find.byType(SplashScreen), findsOneWidget);
    _expectFinishedMark(tester);

    records.complete('/welcome');
    await tester.pumpAndSettle();
    expect(find.byType(WelcomeScreen), findsOneWidget);
  });

  testWidgets('reduced motion shows the finished mark at once', (tester) async {
    final records = Completer<String>();
    await _pumpSplash(
      tester,
      openRecords: () => records.future,
      reduceMotion: true,
    );
    _expectFinishedMark(tester);

    records.complete('/welcome');
    await tester.pump();
    await tester.pump();
    expect(find.byType(WelcomeScreen), findsOneWidget);
  });

  testWidgets('offers a retry when the records cannot open', (tester) async {
    var attempts = 0;
    await _pumpSplash(
      tester,
      openRecords: () => attempts++ == 0
          ? Future<String>.error(StateError('disk'))
          : '/welcome',
    );
    await tester.pump(const Duration(milliseconds: 1300));
    expect(find.text('Try again'), findsOneWidget);
    expect(find.byType(SplashScreen), findsOneWidget);

    await tester.tap(find.text('Try again'));
    await tester.pumpAndSettle();
    expect(find.byType(WelcomeScreen), findsOneWidget);
  });
}
