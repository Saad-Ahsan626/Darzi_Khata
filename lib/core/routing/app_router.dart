import 'package:go_router/go_router.dart';
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

final goRouter = GoRouter(
  initialLocation: '/splash',
  routes: [
    // Auth Routes
    GoRoute(path: '/splash', builder: (context, state) => const SplashScreen()),
    GoRoute(
      path: '/onboarding',
      builder: (context, state) => const OnboardingScreen(),
    ),
    GoRoute(
      path: '/welcome',
      builder: (context, state) => const WelcomeScreen(),
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
        ),
        GoRoute(
          path: '/customers',
          builder: (context, state) => const CustomerListScreen(),
          routes: [
            GoRoute(
              path: 'new',
              builder: (context, state) => const AddEditCustomerScreen(),
            ),
            GoRoute(
              path: ':id',
              builder: (context, state) => CustomerDetailScreen(customerId: state.pathParameters['id']!),
              routes: [
                GoRoute(
                  path: 'measurements',
                  builder: (context, state) => MeasurementScreen(customerId: state.pathParameters['id']!),
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
              builder: (context, state) => const NewEditOrderScreen(),
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
