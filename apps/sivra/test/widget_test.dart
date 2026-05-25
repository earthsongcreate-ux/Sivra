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
        home: OnboardingScreen(uid: 'test', onCompleted: () {}),
      ),
    );

    expect(find.text('Sivra'), findsOneWidget);
    expect(find.text('Choose your focus'), findsOneWidget);
    expect(
      find.text('Pick up to 3. This shapes your daily pack.'),
      findsOneWidget,
    );
    expect(find.text('Product strategy'), findsOneWidget);
    expect(find.text('GTM & sales'), findsOneWidget);
    expect(find.text('Hiring & team'), findsOneWidget);
    expect(find.text('Infra & costs'), findsOneWidget);
  });
}
