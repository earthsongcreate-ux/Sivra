import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:sivra/design/sivra_theme.dart';
import 'package:sivra/screens/onboarding_screen.dart';

void main() {
  testWidgets('onboarding loads', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: SivraTheme.light(),
        darkTheme: SivraTheme.dark(),
        themeMode: ThemeMode.dark,
        home: const OnboardingScreen(),
      ),
    );

    expect(find.text('Sivra'), findsOneWidget);
    expect(find.text('Choose your focus'), findsOneWidget);
  });
}
