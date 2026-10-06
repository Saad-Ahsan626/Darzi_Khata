import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:tailor_khata/core/theme/design_tokens.dart';
import 'package:tailor_khata/core/dev/design_system_preview.dart';
import 'package:tailor_khata/core/shell/app_shell.dart';
import 'package:tailor_khata/features/auth/presentation/screens/splash_screen.dart';
import 'package:tailor_khata/features/auth/presentation/screens/onboarding_screen.dart';
import 'package:tailor_khata/features/auth/presentation/screens/welcome_screen.dart';
import 'package:tailor_khata/features/auth/presentation/screens/login_screen.dart';
import 'package:tailor_khata/features/dashboard/presentation/screens/dashboard_screen.dart';
import 'package:tailor_khata/features/customers/presentation/screens/customer_list_screen.dart';
import 'package:tailor_khata/features/customers/presentation/screens/customer_detail_screen.dart';
import 'package:tailor_khata/features/customers/presentation/screens/add_edit_customer_screen.dart';
import 'package:tailor_khata/features/measurements/presentation/screens/measurement_screen.dart';
import 'package:tailor_khata/features/orders/presentation/screens/order_list_screen.dart';
import 'package:tailor_khata/features/orders/presentation/screens/order_detail_screen.dart';
import 'package:tailor_khata/features/orders/presentation/screens/new_edit_order_screen.dart';
import 'package:tailor_khata/features/settings/presentation/screens/settings_screen.dart';
import 'package:tailor_khata/features/dashboard/presentation/screens/revenue_screen.dart';

final goRouter = createAppRouter();

GoRouter createAppRouter({String? initialLocation}) => GoRouter(
  initialLocation:
      initialLocation ??
      (kDebugMode && const bool.fromEnvironment('SHOW_DESIGN_PREVIEW')
          ? '/design-preview'
          : '/splash'),
  restorationScopeId: 'app_router',
  routes: [
    if (kDebugMode)
      GoRoute(
        path: '/design-preview',
        builder: (context, state) => const DesignSystemPreview(),
      ),
    // Auth Routes
    GoRoute(path: '/splash', builder: (context, state) => const SplashScreen()),
    // The splash fades itself out, so the screens it hands off to fade in.
    GoRoute(
      path: '/onboarding',
      pageBuilder: (context, state) =>
          _fadePage(context, state, const OnboardingScreen()),
    ),
    GoRoute(
      path: '/welcome',
      pageBuilder: (context, state) =>
          _fadePage(context, state, const WelcomeScreen()),
    ),
    GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),

    // Bottom Nav Shell
    ShellRoute(
      builder: (context, state, child) {
        return AppShell(child: child);
      },
      routes: [
        GoRoute(
          path: '/home',
          builder: (context, state) => const DashboardScreen(),
          routes: [
            GoRoute(
              path: 'revenue',
              builder: (context, state) => const RevenueScreen(),
            ),
          ],
        ),
        GoRoute(
          path: '/customers',
          builder: (context, state) => const CustomerListScreen(),
          routes: [
            GoRoute(
              path: 'new',
              builder: (context, state) => AddEditCustomerScreen(
                initialName: state.uri.queryParameters['name'],
                initialPhone: state.uri.queryParameters['phone'],
              ),
            ),
            GoRoute(
              path: ':id',
              builder: (context, state) =>
                  CustomerDetailScreen(customerId: state.pathParameters['id']!),
              routes: [
                GoRoute(
                  path: 'edit',
                  builder: (context, state) {
                    return AddEditCustomerScreen(
                      existingCustomer: state.extra as dynamic,
                    );
                  },
                ),
                GoRoute(
                  path: 'measurements',
                  builder: (context, state) => MeasurementScreen(
                    customerId: state.pathParameters['id']!,
                  ),
                ),
              ],
            ),
          ],
        ),
        GoRoute(
          path: '/orders',
          builder: (context, state) => const OrderListScreen(),
          routes: [
            GoRoute(
              path: 'new',
              builder: (context, state) => NewEditOrderScreen(
                initialCustomerId: state.uri.queryParameters['customerId'],
              ),
            ),
            GoRoute(
              path: ':id',
              builder: (context, state) => const OrderDetailScreen(),
            ),
          ],
        ),
        GoRoute(
          path: '/settings',
          builder: (context, state) => const SettingsScreen(),
        ),
      ],
    ),
  ],
);

Page<void> _fadePage(BuildContext context, GoRouterState state, Widget child) {
  return CustomTransitionPage<void>(
    key: state.pageKey,
    child: child,
    transitionDuration: MediaQuery.disableAnimationsOf(context)
        ? Duration.zero
        : AppMotion.page,
    transitionsBuilder: (context, animation, secondaryAnimation, child) =>
        FadeTransition(
          opacity: CurvedAnimation(parent: animation, curve: AppMotion.curve),
          child: child,
        ),
  );
}
