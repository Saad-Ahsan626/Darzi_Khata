import 'package:flutter/material.dart';
import 'package:tailor_khata/core/theme/design_tokens.dart';
import 'package:go_router/go_router.dart';

class AppShell extends StatelessWidget {
  final Widget child;
  const AppShell({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: child,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _calculateSelectedIndex(context),
        onTap: (int idx) => _onItemTapped(idx, context),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.people), label: 'Customers'),
          BottomNavigationBarItem(icon: Icon(Icons.receipt), label: 'Orders'),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
      floatingActionButton:
          _calculateSelectedIndex(context) == 1 ||
              _calculateSelectedIndex(context) == 2
          ? FloatingActionButton(
              backgroundColor: AppPalette.carbon, // Primary action
              onPressed: () {
                final idx = _calculateSelectedIndex(context);
                if (idx == 1) {
                  context.push('/customers/new');
                } else {
                  context.push('/orders/new');
                }
              },
              child: const Icon(Icons.add, size: 34, color: AppPalette.white),
            )
          : null,
    );
  }

  static int _calculateSelectedIndex(BuildContext context) {
    final String location = GoRouterState.of(context).uri.path;
    if (location.startsWith('/home')) return 0;
    if (location.startsWith('/customers')) return 1;
    if (location.startsWith('/orders')) return 2;
    if (location.startsWith('/settings')) return 3;
    return 0;
  }

  void _onItemTapped(int index, BuildContext context) {
    switch (index) {
      case 0:
        context.go('/home');
        break;
      case 1:
        context.go('/customers');
        break;
      case 2:
        context.go('/orders');
        break;
      case 3:
        context.go('/settings');
        break;
    }
  }
}
