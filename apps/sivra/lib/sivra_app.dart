import 'package:flutter/material.dart';

import 'design/sivra_theme.dart';
import 'screens/onboarding_screen.dart';
import 'screens/today_screen.dart';

class SivraApp extends StatelessWidget {
  const SivraApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sivra',
      theme: SivraTheme.light(),
      darkTheme: SivraTheme.dark(),
      themeMode: ThemeMode.dark,
      home: const OnboardingScreen(),
      routes: {
        TodayScreen.routeName: (context) => const TodayScreen(),
      },
    );
  }
}

