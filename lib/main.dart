import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:tailor_khata/core/routing/app_router.dart';
import 'package:tailor_khata/core/theme/app_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  LicenseRegistry.addLicense(() async* {
    final license = await rootBundle.loadString('assets/fonts/inter/OFL.txt');
    yield LicenseEntryWithLineBreaks(['Inter'], license);
  });

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
      locale: const Locale('en'),
      supportedLocales: const [Locale('en')],

      routerConfig: goRouter,
      // Screens are white unless they say otherwise, so status-bar icons are
      // dark by default; carbon headers and the splash switch them to light.
      builder: (context, child) => AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.dark,
        child: child!,
      ),
    );
  }
}
