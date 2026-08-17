import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:tailor_khata/core/routing/app_router.dart';
import 'package:tailor_khata/core/theme/app_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(const ProviderScope(child: TailorKhataApp()));
}

class TailorKhataApp extends StatelessWidget {
  const TailorKhataApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      restorationScopeId: 'tailor_khata_app',
      title: 'Tailor Khata',
      theme: AppTheme.lightTheme,
      debugShowCheckedModeBanner: false,

      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('en', ''), Locale('ur', '')],

      routerConfig: goRouter,
    );
  }
}
