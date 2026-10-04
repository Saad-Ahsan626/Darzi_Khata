import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          const ListTile(
            title: Text('Shop settings'),
            subtitle: Text(
              'Shop preferences will be available in a later update.',
            ),
          ),
          if (kDebugMode)
            ListTile(
              leading: const Icon(Icons.palette_outlined),
              title: const Text('Design system preview'),
              onTap: () => context.push('/design-preview'),
            ),
        ],
      ),
    );
  }
}
