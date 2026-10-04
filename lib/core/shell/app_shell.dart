import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../theme/design_tokens.dart';
import '../widgets/app_widgets.dart';

class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.child});
  final Widget child;

  static const _destinations = ['/home', '/customers', '/orders', '/settings'];
  static const _items = [
    AppNavigationItem(label: 'Home', icon: Icons.home_outlined),
    AppNavigationItem(label: 'Customers', icon: Icons.person_outline),
    AppNavigationItem(label: 'Orders', icon: Icons.receipt_long_outlined),
    AppNavigationItem(label: 'Settings', icon: Icons.settings_outlined),
  ];

  @override
  Widget build(BuildContext context) {
    final path = GoRouterState.of(context).uri.path;
    // Root tabs own global navigation. Detail, form and measurement routes
    // retain their back stack and receive the full viewport for focused work.
    final showNavigation =
        _destinations.contains(path) &&
        MediaQuery.viewInsetsOf(context).bottom == 0;
    final index = _destinations.indexOf(path);
    return Scaffold(
      body: child,
      bottomNavigationBar: showNavigation
          ? SafeArea(
              top: false,
              minimum: const EdgeInsets.fromLTRB(
                AppSpacing.screenPadding,
                AppSpacing.sm,
                AppSpacing.screenPadding,
                AppSpacing.md,
              ),
              child: Center(
                heightFactor: 1,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 560),
                  child: AppBottomNavigation(
                    items: _items,
                    selectedIndex: index,
                    onSelected: (selected) =>
                        context.go(_destinations[selected]),
                  ),
                ),
              ),
            )
          : null,
    );
  }
}
