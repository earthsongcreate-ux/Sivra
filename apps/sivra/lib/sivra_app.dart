import 'package:flutter/material.dart';

import 'design/sivra_theme.dart';
import 'screens/bootstrap_screen.dart';
import 'screens/screenshot_preview_screen.dart';
import 'screens/today_screen.dart';

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
      home: screenshotScreen.isEmpty
          ? const BootstrapScreen()
          : const ScreenshotPreviewScreen(screen: screenshotScreen),
      routes: {TodayScreen.routeName: (context) => const TodayScreen()},
    );
  }
}
