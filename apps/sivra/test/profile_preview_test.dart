import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sivra/design/sivra_theme.dart';
import 'package:sivra/screens/screenshot_preview_screen.dart';

void main() {
  setUpAll(() async {
    await _loadFont(family: 'Roboto', path: '/System/Library/Fonts/SFNS.ttf');
    await _loadFont(family: 'Inter', path: 'assets/fonts/Inter-Regular.ttf');
    await _loadFont(family: 'Inter', path: 'assets/fonts/Inter-SemiBold.ttf');
    await _loadFont(
      family: 'MaterialIcons',
      path:
          '/usr/local/share/flutter/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf',
    );
  });

  testWidgets('renders Thinking Profile', (tester) async {
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
        home: const ScreenshotPreviewScreen(screen: 'profile'),
      ),
    );
    await tester.pumpAndSettle();

    await expectLater(
      find.byType(ScreenshotPreviewScreen),
      matchesGoldenFile('../../../screenshots/profile-thinking-profile.png'),
    );
  });
}

Future<void> _loadFont({required String family, required String path}) async {
  final bytes = await File(path).readAsBytes();
  final loader = FontLoader(family)
    ..addFont(Future<ByteData>.value(ByteData.sublistView(bytes)));
  await loader.load();
}
