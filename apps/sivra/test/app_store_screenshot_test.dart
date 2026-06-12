import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sivra/design/sivra_theme.dart';
import 'package:sivra/screens/screenshot_preview_screen.dart';

void main() {
  const shouldGenerate = bool.fromEnvironment('GENERATE_APP_STORE_SCREENSHOTS');

  if (!shouldGenerate) {
    return;
  }

  setUpAll(() async {
    await _loadFont(family: 'Roboto', path: '/System/Library/Fonts/SFNS.ttf');
    await _loadFont(family: 'Inter', path: 'assets/fonts/Inter-Regular.ttf');
    await _loadFont(family: 'Inter', path: 'assets/fonts/Inter-SemiBold.ttf');
    await _loadFont(
      family: 'Playfair Display',
      path: 'assets/fonts/PlayfairDisplay-SemiBold.ttf',
    );
    await _loadFont(
      family: 'MaterialIcons',
      path:
          '/usr/local/share/flutter/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf',
    );
  });

  Future<void> pumpScreenshot(
    WidgetTester tester, {
    required String screen,
    required String fileName,
  }) async {
    tester.view.physicalSize = const Size(1320, 2868);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        title: 'Sivra',
        debugShowCheckedModeBanner: false,
        theme: SivraTheme.light(),
        darkTheme: SivraTheme.dark(),
        themeMode: ThemeMode.dark,
        home: ScreenshotPreviewScreen(screen: screen),
      ),
    );
    await tester.pumpAndSettle();

    await expectLater(
      find.byType(ScreenshotPreviewScreen),
      matchesGoldenFile('../../../screenshots/app-store/raw/$fileName'),
    );
  }

  testWidgets('captures Today ready screenshot', (tester) async {
    await pumpScreenshot(
      tester,
      screen: 'today-ready',
      fileName: '01-today-ready.png',
    );
  });

  testWidgets('captures onboarding focus screenshot', (tester) async {
    await pumpScreenshot(
      tester,
      screen: 'onboarding-focus',
      fileName: '02-onboarding-focus.png',
    );
  });

  testWidgets('captures trusted briefing screenshot', (tester) async {
    await pumpScreenshot(
      tester,
      screen: 'source-context',
      fileName: '03-daily-briefing.png',
    );
  });

  testWidgets('captures articulation answer screenshot', (tester) async {
    await pumpScreenshot(
      tester,
      screen: 'articulation-answer',
      fileName: '04-articulation-answer.png',
    );
  });

  testWidgets('captures learning memory screenshot', (tester) async {
    await pumpScreenshot(
      tester,
      screen: 'learning-memory',
      fileName: '05-learning-memory.png',
    );
  });

  testWidgets('captures weekly recap screenshot', (tester) async {
    await pumpScreenshot(
      tester,
      screen: 'weekly-recap',
      fileName: '06-weekly-recap.png',
    );
  });
}

Future<void> _loadFont({required String family, required String path}) async {
  final bytes = await File(path).readAsBytes();
  final loader = FontLoader(family)
    ..addFont(Future<ByteData>.value(ByteData.sublistView(bytes)));
  await loader.load();
}
