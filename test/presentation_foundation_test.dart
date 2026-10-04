import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tailor_khata/core/dev/design_system_preview.dart';
import 'package:tailor_khata/core/routing/app_router.dart';
import 'package:tailor_khata/core/theme/app_theme.dart';
import 'package:tailor_khata/core/theme/design_tokens.dart';
import 'package:tailor_khata/core/widgets/app_widgets.dart';
import 'package:tailor_khata/features/customers/domain/entities/customer.dart';
import 'package:tailor_khata/features/customers/presentation/providers/customers_notifier.dart';
import 'package:tailor_khata/features/customers/presentation/screens/add_edit_customer_screen.dart';
import 'package:tailor_khata/features/orders/domain/entities/order.dart';
import 'package:tailor_khata/features/orders/presentation/providers/orders_notifier.dart';
import 'package:tailor_khata/features/orders/presentation/screens/new_edit_order_screen.dart';

final _customer = Customer(
  id: 'customer-1',
  name: 'Faisal Shah',
  urduName: 'فیصل شاہ',
  phone: '03004128876',
  createdAt: DateTime(2026, 10, 4),
);

class _Customers extends CustomersNotifier {
  Customer? saved;
  @override
  Future<List<Customer>> build() async => [_customer];
  @override
  Future<void> updateCustomer(Customer customer) async {
    saved = customer;
  }
}

class _Orders extends OrdersNotifier {
  @override
  Future<List<Order>> build() async => [];
}

Widget _app(Widget child, {MediaQueryData? media}) => MaterialApp(
  theme: AppTheme.lightTheme,
  locale: const Locale('en'),
  builder: media == null
      ? null
      : (_, child) => MediaQuery(data: media, child: child!),
  home: Scaffold(body: child),
);

void _viewport(WidgetTester tester, double width) {
  tester.view.physicalSize = Size(width, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
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

  testWidgets('fields validate, focus and retain labels after typing', (
    tester,
  ) async {
    final form = GlobalKey<FormState>();
    await tester.pumpWidget(
      _app(
        Form(
          key: form,
          child: ListView(
            children: [
              AppTextField(
                label: 'Full name',
                helper: 'Enter a name',
                validator: (value) =>
                    value == null || value.isEmpty ? 'Name is required' : null,
              ),
              AppButton(
                label: 'Save',
                onPressed: () => form.currentState!.validate(),
              ),
            ],
          ),
        ),
      ),
    );
    await tester.tap(find.text('Save'));
    await tester.pump();
    expect(find.text('Name is required'), findsOneWidget);
    await tester.enterText(find.byType(TextFormField), 'Faisal');
    expect(
      tester.widget<EditableText>(find.byType(EditableText)).focusNode.hasFocus,
      isTrue,
    );
    expect(find.text('Full name'), findsOneWidget);
    await tester.tap(find.text('Save'));
    await tester.pump();
    expect(find.text('Name is required'), findsNothing);
  });

  testWidgets('loading and disabled actions do not trigger callbacks', (
    tester,
  ) async {
    int calls = 0;
    await tester.pumpWidget(
      _app(
        Column(
          children: [
            AppButton(label: 'Save', isLoading: true, onPressed: () => calls++),
            const AppButton(label: 'Disabled', onPressed: null),
            AppButton(label: 'Ready', onPressed: () => calls++),
          ],
        ),
      ),
    );
    await tester.tap(find.text('Save…'));
    await tester.tap(find.text('Disabled'));
    expect(calls, 0);
    await tester.tap(find.text('Ready'));
    expect(calls, 1);
  });

  testWidgets('high contrast replaces glass with opaque surfaces', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(
        const GlassSurface(child: Text('Glass')),
        media: const MediaQueryData(highContrast: true),
      ),
    );
    expect(find.byType(BackdropFilter), findsNothing);
    await tester.pumpWidget(_app(const GlassSurface(child: Text('Glass'))));
    expect(find.byType(BackdropFilter), findsOneWidget);
    await tester.pumpWidget(
      _app(const GlassSurface(blurEnabled: false, child: Text('Glass'))),
    );
    expect(find.byType(BackdropFilter), findsNothing);
  });

  testWidgets('navigation supports keyboard activation', (tester) async {
    int selected = 1;
    await tester.pumpWidget(
      _app(
        StatefulBuilder(
          builder: (_, setState) => AppBottomNavigation(
            items: const [
              AppNavigationItem(label: 'Home', icon: Icons.home_outlined),
              AppNavigationItem(
                label: 'Orders',
                icon: Icons.receipt_long_outlined,
              ),
            ],
            selectedIndex: selected,
            onSelected: (index) => setState(() => selected = index),
          ),
        ),
      ),
    );
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(selected, 0);
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(selected, 1);
  });

  for (final width in [360.0, 390.0]) {
    testWidgets('gallery renders all variants at $width with large text', (
      tester,
    ) async {
      _viewport(tester, width);
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          builder: (_, child) => MediaQuery(
            data: MediaQueryData(
              size: Size(width, 844),
              textScaler: TextScaler.linear(1.4),
              disableAnimations: true,
              padding: const EdgeInsets.only(bottom: 34),
            ),
            child: child!,
          ),
          home: const DesignSystemPreview(),
        ),
      );
      await tester.pump();
      for (final label in [
        'Buttons',
        'Fields',
        'Surfaces',
        'Selection',
        'Feedback',
        'Navigation',
      ]) {
        final tab = find.text(label).first;
        await tester.ensureVisible(tab);
        await tester.tap(tab);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 500));
        expect(tester.takeException(), isNull, reason: label);
      }
      await tester.tap(find.text('Orders'));
      await tester.pump();
      final semantics = tester.getSemantics(find.byType(AppBottomNavigation));
      expect(semantics.toStringDeep(), contains('Orders'));
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets(
    'real routes retain add/back actions and hide navigation during entry',
    (tester) async {
      _viewport(tester, 360);
      final router = createAppRouter(initialLocation: '/customers');
      addTearDown(router.dispose);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            customersNotifierProvider.overrideWith(_Customers.new),
            ordersNotifierProvider.overrideWith(_Orders.new),
          ],
          child: MaterialApp.router(
            theme: AppTheme.lightTheme,
            routerConfig: router,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(AppBottomNavigation), findsOneWidget);
      await tester.tap(find.byTooltip('Add customer'));
      await tester.pumpAndSettle();
      expect(find.byType(AddEditCustomerScreen), findsOneWidget);
      expect(find.byType(AppBottomNavigation), findsNothing);
      router.pop();
      await tester.pumpAndSettle();
      expect(find.byType(AppBottomNavigation), findsOneWidget);
      await tester.tap(find.text('Orders'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('New order'));
      await tester.pumpAndSettle();
      expect(find.byType(NewEditOrderScreen), findsOneWidget);
      expect(find.byType(AppBottomNavigation), findsNothing);
      router.pop();
      await tester.pumpAndSettle();
      await tester.tap(find.text('Customers'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Faisal Shah'));
      await tester.pumpAndSettle();
      expect(find.byType(AppBottomNavigation), findsNothing);
      expect(find.text(_customer.urduName!), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('English edit preserves the hidden stored customer name', (
    tester,
  ) async {
    final fixture = _Customers();
    final router = createAppRouter(initialLocation: '/customers');
    addTearDown(router.dispose);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          customersNotifierProvider.overrideWith(() => fixture),
          ordersNotifierProvider.overrideWith(_Orders.new),
        ],
        child: MaterialApp.router(
          theme: AppTheme.lightTheme,
          routerConfig: router,
        ),
      ),
    );
    await tester.pumpAndSettle();
    router.push('/customers/customer-1/edit', extra: _customer);
    await tester.pumpAndSettle();
    expect(find.byType(TextFormField), findsNWidgets(3));
    await tester.enterText(find.byType(TextFormField).first, 'Faisal Ahmed');
    await tester.ensureVisible(find.text('Save changes'));
    await tester.tap(find.text('Save changes'));
    await tester.pumpAndSettle();
    expect(fixture.saved?.name, 'Faisal Ahmed');
    expect(fixture.saved?.urduName, _customer.urduName);
  });

  testWidgets(
    'keyboard hides global navigation and safe-area space is reserved',
    (tester) async {
      _viewport(tester, 360);
      final router = createAppRouter(initialLocation: '/customers');
      addTearDown(router.dispose);
      final keyboard = ValueNotifier<double>(0);
      addTearDown(keyboard.dispose);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            customersNotifierProvider.overrideWith(_Customers.new),
            ordersNotifierProvider.overrideWith(_Orders.new),
          ],
          child: MaterialApp.router(
            theme: AppTheme.lightTheme,
            routerConfig: router,
            builder: (_, child) => ValueListenableBuilder<double>(
              valueListenable: keyboard,
              builder: (_, inset, _) => MediaQuery(
                data: MediaQueryData(
                  size: const Size(360, 844),
                  padding: const EdgeInsets.only(bottom: 34),
                  viewInsets: EdgeInsets.only(bottom: inset),
                ),
                child: child!,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final nav = tester.getRect(find.byType(AppBottomNavigation));
      expect(nav.bottom, lessThanOrEqualTo(844 - 34));
      expect(
        tester.getRect(find.text('Faisal Shah')).bottom,
        lessThan(nav.top),
      );
      keyboard.value = 300;
      await tester.pumpAndSettle();
      expect(find.byType(AppBottomNavigation), findsNothing);
      keyboard.value = 0;
      await tester.pumpAndSettle();
      expect(find.byType(AppBottomNavigation), findsOneWidget);
    },
  );
}
