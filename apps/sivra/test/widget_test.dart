import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:sivra/design/sivra_theme.dart';
import 'package:sivra/data/mock_daily_pack.dart';
import 'package:sivra/models/daily_pack.dart';
import 'package:sivra/models/drill_item.dart';
import 'package:sivra/models/learning_profile.dart';
import 'package:sivra/models/source_audit.dart';
import 'package:sivra/models/weekly_recap.dart';
import 'package:sivra/screens/onboarding_screen.dart';
import 'package:sivra/screens/paywall_screen.dart';
import 'package:sivra/screens/today_screen.dart';
import 'package:sivra/services/daily_pack_validator.dart';
import 'package:sivra/services/personalization_engine.dart';

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

  testWidgets('onboarding advances through personalization questions', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: SivraTheme.light(),
        darkTheme: SivraTheme.dark(),
        themeMode: ThemeMode.dark,
        home: OnboardingScreen(uid: 'test', onCompleted: () {}),
      ),
    );

    expect(find.text('1/5'), findsOneWidget);
    await tester.tap(find.text('Product strategy'));
    await tester.pump();
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    expect(find.text('How fluent are you with AI today?'), findsOneWidget);
    expect(find.text('2/5'), findsOneWidget);
    await tester.tap(find.text('Experimenting'));
    await tester.pump();
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    expect(find.text('What usually gets in the way?'), findsOneWidget);
    expect(find.text('3/5'), findsOneWidget);
  });

  testWidgets('daily pack advances, goes back by item, and finishes', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: SivraTheme.light(),
        darkTheme: SivraTheme.dark(),
        themeMode: ThemeMode.dark,
        home: const TodayScreen.preview(),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Start pack'));
    await tester.pumpAndSettle();

    for (var i = 0; i < 6; i += 1) {
      expect(find.text('${i + 1}/8'), findsOneWidget);
      await tester.tap(find.text('Reveal'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();
    }

    expect(find.text('7/8'), findsOneWidget);
    expect(find.text('Next'), findsOneWidget);

    await tester.enterText(
      find.byType(TextField),
      'It reduces avoidable work.',
    );
    await tester.pump();
    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();

    expect(find.text('8/8'), findsOneWidget);
    expect(find.text('Answer'), findsOneWidget);
    expect(find.text('Finish'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.chevron_left));
    await tester.pumpAndSettle();
    expect(find.text('7/8'), findsOneWidget);
    final answerField = tester.widget<TextField>(find.byType(TextField));
    expect(answerField.controller?.text, 'It reduces avoidable work.');

    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Finish'));
    await tester.pumpAndSettle();

    expect(find.text('Today’s Pack'), findsOneWidget);
    expect(find.text('Done'), findsOneWidget);
    expect(find.text('Answers'), findsOneWidget);
    expect(find.text('1'), findsOneWidget);
  });

  testWidgets('paywall falls back gracefully without RevenueCat config', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: SivraTheme.light(),
        darkTheme: SivraTheme.dark(),
        themeMode: ThemeMode.dark,
        home: const PaywallScreen(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Sivra Pro'), findsOneWidget);
    expect(find.text('Unlock AI Pack Generation'), findsOneWidget);
    expect(
      find.text(
        'RevenueCat offerings are not available in this build. Free curated packs remain available.',
      ),
      findsOneWidget,
    );
    expect(find.text('Continue free'), findsOneWidget);
  });

  test('daily pack validator accepts the generated pack shape', () {
    final pack = DailyPack(
      dayId: '2026-05-26',
      focusAreas: const <String>['Product strategy'],
      items: MockDailyPack.forFocus(const <String>['Product strategy']),
    );

    final result = const DailyPackValidator().validate(pack);

    expect(result.errors, isEmpty);
  });

  test('daily pack validator rejects vague placeholder sources', () {
    final items = MockDailyPack.forFocus(const <String>['Product strategy']);
    final badSourceItem = DrillItem(
      id: items.first.id,
      type: items.first.type,
      prompt: items.first.prompt,
      answer: items.first.answer,
      explanation: items.first.explanation,
      source: const DrillItemSource(
        title: 'Source title',
        publisher: 'Trusted publication',
        dateLabel: 'Today',
        url: 'https://example.com',
        snippet: 'Placeholder source.',
      ),
    );
    final pack = DailyPack(
      dayId: '2026-05-26',
      focusAreas: const <String>['Product strategy'],
      items: <DrillItem>[badSourceItem, ...items.skip(1)],
    );

    final result = const DailyPackValidator().validate(pack);

    expect(result.errors, isNotEmpty);
  });

  test('weekly recap summarizes recent packs', () {
    final items = MockDailyPack.forFocus(const <String>['Product strategy']);
    final pack = DailyPack(
      dayId: '2026-05-26',
      focusAreas: const <String>['Product strategy'],
      items: items,
      completedItemIds: items.take(3).map((item) => item.id).toList(),
      answersByItemId: <String, String>{items[6].id: 'A clear CFO answer.'},
      completedAt: DateTime(2026, 5, 26),
    );

    final recap = WeeklyRecap.fromPacks(<DailyPack>[pack]);

    expect(recap.packCount, 1);
    expect(recap.completedPackCount, 1);
    expect(recap.completedScreenCount, 3);
    expect(recap.writtenAnswerCount, 1);
    expect(recap.focusAreas, contains('Product strategy'));
  });

  test('personalization engine identifies weak drill types', () {
    final items = MockDailyPack.forFocus(const <String>['Product strategy']);
    final pack = DailyPack(
      dayId: '2026-05-26',
      focusAreas: const <String>['Product strategy'],
      items: items,
      completedItemIds: items
          .where((item) => item.type != DrillItemType.articulation)
          .map((item) => item.id)
          .toList(),
    );

    final profile = const PersonalizationEngine().buildProfile(
      recentPacks: <DailyPack>[pack],
      focusAreas: const <String>['Product strategy'],
    );

    expect(profile.weakDrillTypes, contains(DrillItemType.articulation));
    expect(profile.guidance, contains('articulation'));
  });

  test('learning profile round trips to map', () {
    const profile = LearningProfile(
      focusPriority: <String>['Product strategy'],
      weakDrillTypes: <DrillItemType>[DrillItemType.decision],
      recentPackCount: 2,
      completedPackCount: 1,
      writtenAnswerCount: 3,
      guidance: 'Emphasize decision practice.',
    );

    final restored = LearningProfile.fromMap(profile.toMap());

    expect(restored.focusPriority, contains('Product strategy'));
    expect(restored.weakDrillTypes, contains(DrillItemType.decision));
    expect(restored.guidance, 'Emphasize decision practice.');
  });

  test('source audit summarizes trust and fallback counts', () {
    final items = MockDailyPack.forFocus(const <String>['Product strategy']);
    final pack = DailyPack(
      dayId: '2026-05-26',
      focusAreas: const <String>['Product strategy'],
      items: items,
      generator: 'curated_fallback_v1',
    );

    final audit = SourceAudit.fromPacks(<DailyPack>[pack]);

    expect(audit.packCount, 1);
    expect(audit.sourceCount, 2);
    expect(audit.fallbackPackCount, 1);
    expect(audit.hostCounts.keys, contains('openai.com'));
  });
}
