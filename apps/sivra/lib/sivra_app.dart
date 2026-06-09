import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'design/sivra_theme.dart';
import 'screens/bootstrap_screen.dart';
import 'screens/screenshot_preview_screen.dart';
import 'screens/app_shell.dart';

class SivraApp extends StatelessWidget {
  const SivraApp({super.key});

  @override
  Widget build(BuildContext context) {
    const screenshotScreen = String.fromEnvironment('SIVRA_SCREENSHOT_SCREEN');

    return MaterialApp(
      title: 'Sivra',
      debugShowCheckedModeBanner: false,
      theme: SivraTheme.light(),
      darkTheme: SivraTheme.dark(),
      themeMode: ThemeMode.dark,
      home: kIsWeb
          ? (screenshotScreen.isEmpty
                ? const AppShell.preview()
                : ScreenshotPreviewScreen(screen: screenshotScreen))
          : screenshotScreen.isEmpty
          ? const BootstrapScreen()
          : const ScreenshotPreviewScreen(screen: screenshotScreen),
      restorationScopeId: 'sivra',
      routes: {AppShell.routeName: (context) => const AppShell()},
    );
  }
}
