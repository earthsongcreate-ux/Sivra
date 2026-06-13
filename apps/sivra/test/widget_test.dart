import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:sivra/design/sivra_theme.dart';
import 'package:sivra/data/mock_daily_pack.dart';
import 'package:sivra/models/archive_entry.dart';
import 'package:sivra/models/daily_pack.dart';
import 'package:sivra/models/drill_item.dart';
import 'package:sivra/models/entitlement_state.dart';
import 'package:sivra/models/learning_profile.dart';
import 'package:sivra/models/source_audit.dart';
import 'package:sivra/models/thought.dart';
import 'package:sivra/models/weekly_recap.dart';
import 'package:sivra/screens/app_shell.dart';
import 'package:sivra/screens/learning_memory_screen.dart';
import 'package:sivra/screens/onboarding_screen.dart';
import 'package:sivra/screens/paywall_screen.dart';
import 'package:sivra/screens/profile_screen.dart';
import 'package:sivra/screens/today_screen.dart';
import 'package:sivra/screens/weekly_recap_screen.dart';
import 'package:sivra/services/daily_pack_validator.dart';
import 'package:sivra/services/daily_thought_engine.dart';
import 'package:sivra/services/debug_onboarding_override.dart';
import 'package:sivra/services/personalization_engine.dart';
import 'package:sivra/services/thought_repository.dart';

void main() {
  test(
    'debug onboarding override persists locally and can be cleared',
    () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});

      expect(await DebugOnboardingOverride.isEnabledFor('test-user'), isFalse);

      await DebugOnboardingOverride.enableFor('test-user');
      expect(await DebugOnboardingOverride.isEnabledFor('test-user'), isTrue);

      await DebugOnboardingOverride.clearFor('test-user');
      expect(await DebugOnboardingOverride.isEnabledFor('test-user'), isFalse);
    },
  );

  testWidgets('app shell fits the target iPhone viewports', (
    WidgetTester tester,
  ) async {
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    tester.view.devicePixelRatio = 1;

    for (final size in const <Size>[
      Size(320, 568),
      Size(375, 812),
      Size(393, 852),
    ]) {
      tester.view.physicalSize = size;
      await tester.pumpWidget(
        MaterialApp(
          theme: SivraTheme.light(),
          darkTheme: SivraTheme.dark(),
          themeMode: ThemeMode.dark,
          home: const AppShell.preview(),
        ),
      );
      await tester.pumpAndSettle();

      final navRect = tester.getRect(find.byKey(const ValueKey('nav-today')));
      expect(navRect.bottom, lessThanOrEqualTo(size.height));
      expect(navRect.top, greaterThan(0));
      expect(tester.takeException(), isNull);

      await tester.pumpWidget(const SizedBox.shrink());
    }
  });

  testWidgets('app shell keeps permanent destinations one tap away', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        restorationScopeId: 'test',
        theme: SivraTheme.light(),
        darkTheme: SivraTheme.dark(),
        themeMode: ThemeMode.dark,
        home: const AppShell.preview(
          initialFocusAreas: <String>['Product strategy', 'Infra & costs'],
        ),
      ),
    );
    await tester.pumpAndSettle();

    for (final destination in <String>[
      'today',
      'archive',
      'recap',
      'profile',
    ]) {
      expect(find.byKey(ValueKey('nav-$destination')), findsOneWidget);
    }

    await tester.tap(find.byKey(const ValueKey('nav-archive')));
    await tester.pumpAndSettle();
    expect(find.text('Thinking Archive'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('nav-recap')));
    await tester.pumpAndSettle();
    expect(find.text('Weekly Recap'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('nav-profile')));
    await tester.pumpAndSettle();
    expect(find.text('Subscription'), findsOneWidget);
    expect(find.text('Focus Areas'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Support'),
      260,
      scrollable: find.byType(Scrollable).last,
    );
    expect(find.text('Settings'), findsOneWidget);
    expect(find.text('Support'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('nav-today')));
    await tester.pumpAndSettle();
    expect(find.text('TODAY’S RITUAL'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('ritual route hides the app shell navigation', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        theme: SivraTheme.light(),
        darkTheme: SivraTheme.dark(),
        themeMode: ThemeMode.dark,
        home: const AppShell.preview(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('nav-today')), findsOneWidget);
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('begin-ritual')),
      280,
      scrollable: find.byType(Scrollable).last,
    );
    final beginRitual = tester.widget<FilledButton>(
      find.byKey(const ValueKey('begin-ritual')),
    );
    beginRitual.onPressed!();
    await tester.pumpAndSettle();

    expect(find.text('Question 1 of 8'), findsOneWidget);
    expect(find.byKey(const ValueKey('nav-today')), findsNothing);
    expect(find.text('Previous'), findsOneWidget);
    expect(find.text('Next'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('onboarding loads', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: SivraTheme.light(),
        darkTheme: SivraTheme.dark(),
        themeMode: ThemeMode.dark,
        home: OnboardingScreen(uid: 'test', onCompleted: () {}),
      ),
    );

    expect(find.bySemanticsLabel('Sivra'), findsOneWidget);
    expect(find.text('WALK INTO ANY ROOM PREPARED'), findsOneWidget);
    expect(
      find.text(
        'Sharpen judgment, decision-making, and communication\n'
        'in 7 minutes a day.',
      ),
      findsOneWidget,
    );
    expect(find.text('2'), findsOneWidget);
    expect(find.text('3'), findsOneWidget);
    expect(find.text('7'), findsOneWidget);
    expect(find.text('Decisions'), findsOneWidget);
    expect(find.text('Begin'), findsOneWidget);
  });

  testWidgets('onboarding advances through five-screen ritual flow', (
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

    await tester.tap(find.text('Begin'));
    await tester.pumpAndSettle();

    expect(find.text('GREAT THINKING IS A DAILY PRACTICE'), findsOneWidget);
    expect(find.text('2'), findsOneWidget);
    expect(find.text('Briefings'), findsOneWidget);
    expect(find.text('Read.\nDecide.\nExplain.\nRepeat.'), findsOneWidget);
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    expect(find.text('WHERE DO YOU WANT TO BECOME SHARPER?'), findsOneWidget);
    expect(
      find.text(
        'Choose up to three areas.\n'
        'Sivra will tailor your daily thinking ritual around them.',
      ),
      findsOneWidget,
    );
    expect(
      tester.getTopLeft(find.byKey(const ValueKey('onboarding-progress'))).dy,
      lessThan(
        tester.getTopLeft(find.text('WHERE DO YOU WANT TO BECOME SHARPER?')).dy,
      ),
    );
    expect(find.text('Founder'), findsOneWidget);
    expect(find.text('Product Strategy'), findsOneWidget);
    await tester.tap(find.text('Founder'));
    await tester.pump();
    for (final label in <String>[
      'Operator',
      'Investor',
      'Builder',
      'Marketing',
      'Other',
    ]) {
      await tester.scrollUntilVisible(
        find.text(label),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text(label), findsOneWidget);
    }
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    expect(find.text('YOUR THINKING COMPOUNDS'), findsOneWidget);
    expect(find.text('LEARNING MEMORY'), findsOneWidget);
    expect(
      find.text(
        'Every briefing, decision, and answer becomes part of your learning memory.',
      ),
      findsOneWidget,
    );
    expect(find.text('Weekly recap'), findsOneWidget);

    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    expect(find.text('YOUR RITUAL IS READY'), findsOneWidget);
    expect(find.text('Founder'), findsOneWidget);
    expect(find.text('Your edge is prepared.'), findsOneWidget);
    expect(find.text('Begin Today’s Ritual'), findsOneWidget);

    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();
    expect(find.text('YOUR THINKING COMPOUNDS'), findsOneWidget);
    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();
    expect(find.text('WHERE DO YOU WANT TO BECOME SHARPER?'), findsOneWidget);
  });

  testWidgets('onboarding fits the target iPhone viewports', (
    WidgetTester tester,
  ) async {
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    tester.view.devicePixelRatio = 1;

    for (final size in const <Size>[
      Size(320, 568),
      Size(375, 812),
      Size(393, 852),
      Size(430, 932),
    ]) {
      tester.view.physicalSize = size;

      for (var step = 0; step < 5; step++) {
        await tester.pumpWidget(
          MaterialApp(
            theme: SivraTheme.light(),
            darkTheme: SivraTheme.dark(),
            themeMode: ThemeMode.dark,
            home: OnboardingScreen(
              uid: 'test',
              initialStepIndex: step,
              initialSelectedFocus: step >= 2
                  ? const <String>['Founder']
                  : const <String>[],
              onCompleted: _noop,
            ),
          ),
        );
        await tester.pumpAndSettle();

        final cta = tester.getRect(
          find.text(switch (step) {
            0 => 'Begin',
            4 => 'Begin Today’s Ritual',
            _ => 'Continue',
          }),
        );
        expect(cta.bottom, lessThanOrEqualTo(size.height));
        expect(
          tester.takeException(),
          isNull,
          reason:
              'Step $step initially overflowed at ${size.width}x${size.height}.',
        );
        if (step == 2) {
          await tester.drag(
            find.byType(CustomScrollView),
            const Offset(0, -360),
          );
          await tester.pumpAndSettle();
          final selectedCard = tester.getRect(
            find.byKey(const ValueKey('role-chip-selected-Founder')),
          );
          expect(selectedCard.left, greaterThanOrEqualTo(0));
          expect(selectedCard.right, lessThanOrEqualTo(size.width));
          final scrollException = tester.takeException();
          expect(
            scrollException,
            isNull,
            reason:
                'Step $step overflowed after scrolling at '
                '${size.width}x${size.height}.',
          );
        }
        await tester.pumpWidget(const SizedBox.shrink());
      }
    }
  });

  testWidgets('onboarding supports larger dynamic type', (
    WidgetTester tester,
  ) async {
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(320, 568);

    for (var step = 0; step < 5; step++) {
      await tester.pumpWidget(
        MaterialApp(
          theme: SivraTheme.light(),
          darkTheme: SivraTheme.dark(),
          themeMode: ThemeMode.dark,
          builder: (context, child) {
            final mediaQuery = MediaQuery.of(context);
            return MediaQuery(
              data: mediaQuery.copyWith(
                textScaler: const TextScaler.linear(1.3),
              ),
              child: child!,
            );
          },
          home: OnboardingScreen(
            uid: 'test',
            initialStepIndex: step,
            initialSelectedFocus: step >= 2
                ? const <String>['Founder']
                : const <String>[],
            onCompleted: _noop,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        tester.takeException(),
        isNull,
        reason: 'Step $step overflowed with larger dynamic type.',
      );
      await tester.pumpWidget(const SizedBox.shrink());
    }
  });

  testWidgets('onboarding limits personalization to three roles', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: SivraTheme.light(),
        darkTheme: SivraTheme.dark(),
        themeMode: ThemeMode.dark,
        home: const OnboardingScreen(
          uid: 'test',
          initialStepIndex: 2,
          onCompleted: _noop,
        ),
      ),
    );

    for (final label in <String>[
      'Founder',
      'Product Strategy',
      'Operator',
      'Investor',
    ]) {
      final card = find.byKey(ValueKey('role-chip-$label'));
      await tester.ensureVisible(card);
      await tester.tap(card);
      await tester.pump();
    }
    await tester.pump();

    expect(find.byKey(const ValueKey('role-chip-Investor')), findsOneWidget);
    expect(
      find.byKey(const ValueKey('role-chip-selected-Investor')),
      findsNothing,
    );

    final founderCard = find.byKey(
      const ValueKey('role-chip-selected-Founder'),
    );
    await tester.drag(find.byType(CustomScrollView), const Offset(0, 600));
    await tester.pumpAndSettle();
    expect(founderCard, findsOneWidget);
  });

  testWidgets(
    'onboarding completion presents paywall before continuing free into the app',
    (WidgetTester tester) async {
      var completed = false;

      await tester.pumpWidget(
        MaterialApp(
          theme: SivraTheme.light(),
          darkTheme: SivraTheme.dark(),
          themeMode: ThemeMode.dark,
          routes: <String, WidgetBuilder>{
            AppShell.routeName: (_) => const Scaffold(body: Text('App Shell')),
          },
          home: OnboardingScreen(
            uid: 'test',
            initialStepIndex: 2,
            allowLocalCompletion: true,
            analyticsEnabled: false,
            onCompleted: () {
              completed = true;
            },
            paywallBuilder: (_) => const PaywallScreen(
              previewPlans: <PaywallPlan>[
                PaywallPlan(
                  id: 'annual',
                  price: r'$99.99/year',
                  recommended: true,
                  hasTrial: true,
                ),
                PaywallPlan(
                  id: 'monthly',
                  price: r'$12.99/month',
                  recommended: false,
                  hasTrial: false,
                ),
              ],
            ),
          ),
        ),
      );

      await tester.tap(find.text('Founder'));
      await tester.pump();
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Begin Today’s Ritual'));
      await tester.pumpAndSettle();

      expect(find.textContaining('Continue Building Your'), findsOneWidget);
      expect(completed, isFalse);

      await tester.tap(find.text('Continue Free'));
      await tester.pumpAndSettle();

      expect(completed, isTrue);
      expect(find.text('App Shell'), findsOneWidget);
    },
  );

  testWidgets(
    'onboarding continues after a successful subscription from the paywall',
    (WidgetTester tester) async {
      var completed = false;

      await tester.pumpWidget(
        MaterialApp(
          theme: SivraTheme.light(),
          darkTheme: SivraTheme.dark(),
          themeMode: ThemeMode.dark,
          routes: <String, WidgetBuilder>{
            AppShell.routeName: (_) => const Scaffold(body: Text('App Shell')),
          },
          home: OnboardingScreen(
            uid: 'test',
            initialStepIndex: 2,
            allowLocalCompletion: true,
            analyticsEnabled: false,
            onCompleted: () {
              completed = true;
            },
            paywallBuilder: (_) => PaywallScreen(
              previewPlans: const <PaywallPlan>[
                PaywallPlan(
                  id: 'annual',
                  price: r'$99.99/year',
                  recommended: true,
                  hasTrial: true,
                ),
                PaywallPlan(
                  id: 'monthly',
                  price: r'$12.99/month',
                  recommended: false,
                  hasTrial: false,
                ),
              ],
              previewPurchase: (planId) async {
                return const EntitlementState(
                  isConfigured: true,
                  isPro: true,
                  entitlementId: 'sivra_pro',
                  activeProductId: 'sivra_annual_9999',
                );
              },
            ),
          ),
        ),
      );

      await tester.tap(find.text('Founder'));
      await tester.pump();
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Begin Today’s Ritual'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('purchase-annual')));
      await tester.pumpAndSettle();

      expect(completed, isTrue);
      expect(find.text('App Shell'), findsOneWidget);
    },
  );

  testWidgets(
    'onboarding can complete locally when startup sync is unavailable',
    (WidgetTester tester) async {
      var completed = false;
      var completedFocus = <String>[];

      await tester.pumpWidget(
        MaterialApp(
          theme: SivraTheme.light(),
          darkTheme: SivraTheme.dark(),
          themeMode: ThemeMode.dark,
          home: OnboardingScreen(
            uid: 'local-startup',
            initialStepIndex: 2,
            allowLocalCompletion: true,
            onCompleted: () {
              completed = true;
            },
            onCompletedWithFocus: (focusAreas) {
              completedFocus = focusAreas;
            },
            paywallBuilder: (_) => const PaywallScreen(
              previewPlans: <PaywallPlan>[
                PaywallPlan(
                  id: 'annual',
                  price: r'$99.99/year',
                  recommended: true,
                  hasTrial: true,
                ),
                PaywallPlan(
                  id: 'monthly',
                  price: r'$12.99/month',
                  recommended: false,
                  hasTrial: false,
                ),
              ],
            ),
          ),
        ),
      );

      await tester.tap(find.text('Founder'));
      await tester.pump();
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Begin Today’s Ritual'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Continue Free'));
      await tester.pumpAndSettle();

      expect(completed, isTrue);
      expect(completedFocus, contains('Product strategy'));
    },
  );

  testWidgets('Today greeting follows the local daypart and profile name', (
    WidgetTester tester,
  ) async {
    for (final (hour, expected) in <(int, String)>[
      (9, 'Good Morning, Alex'),
      (13, 'Good Afternoon, Alex'),
      (18, 'Good Evening, Alex'),
      (23, 'Welcome Back, Alex'),
    ]) {
      await tester.pumpWidget(
        MaterialApp(
          theme: SivraTheme.light(),
          darkTheme: SivraTheme.dark(),
          themeMode: ThemeMode.dark,
          home: TodayScreen.preview(greetingTime: DateTime(2026, 6, 13, hour)),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text(expected), findsOneWidget);
      await tester.pumpWidget(const SizedBox.shrink());
    }

    await tester.pumpWidget(
      MaterialApp(
        theme: SivraTheme.light(),
        darkTheme: SivraTheme.dark(),
        themeMode: ThemeMode.dark,
        home: TodayScreen.preview(
          initialFirstName: '',
          greetingTime: DateTime(2026, 6, 13, 9),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Welcome Back'), findsOneWidget);
    expect(find.textContaining(','), findsNothing);
    expect(find.text('Welcome'), findsNothing);
  });

  testWidgets('home header routes all secondary features through Profile', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: SivraTheme.light(),
        darkTheme: SivraTheme.dark(),
        themeMode: ThemeMode.dark,
        home: TodayScreen.preview(
          initialFocusAreas: <String>['Product strategy', 'Infra & costs'],
          greetingTime: DateTime(2026, 6, 13, 9),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Good Morning, Alex'), findsOneWidget);
    expect(find.text('Welcome'), findsNothing);
    expect(find.text('Today’s Thought'), findsOneWidget);
    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is Text &&
            widget.data != null &&
            widget.data!.startsWith('“') &&
            widget.data!.endsWith('”'),
      ),
      findsOneWidget,
    );
    final thoughtText = tester.widget<Text>(
      find.byWidgetPredicate(
        (widget) =>
            widget is Text &&
            widget.data != null &&
            widget.data!.startsWith('“') &&
            widget.data!.endsWith('”'),
      ),
    );
    expect(thoughtText.maxLines, 2);
    expect(thoughtText.overflow, TextOverflow.ellipsis);
    expect(thoughtText.softWrap, isTrue);
    expect(find.byTooltip('Profile'), findsOneWidget);
    expect(find.text('TODAY’S RITUAL'), findsOneWidget);
    expect(find.text('Your thinking session is ready.'), findsOneWidget);
    expect(find.text('Product Strategy'), findsWidgets);
    expect(find.text('Infrastructure & Costs'), findsWidgets);
    expect(find.text('Today’s Investment'), findsOneWidget);
    expect(find.text('7 Minutes'), findsOneWidget);
    expect(find.text('2 Briefings  •  6 Drills'), findsOneWidget);
    expect(find.text('Begin Ritual'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Ritual Streak  •  Day 1'),
      240,
      scrollable: find.byType(Scrollable).last,
    );
    expect(find.text('Ritual Streak  •  Day 1'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Today’s Themes'),
      200,
      scrollable: find.byType(Scrollable).last,
    );
    expect(find.text('Today’s Themes'), findsOneWidget);
    expect(find.text('Open'), findsNothing);
    expect(find.text('Progress'), findsNothing);
    expect(find.text('Answers'), findsNothing);
    expect(find.byTooltip('Content QA'), findsNothing);
    expect(find.byTooltip('Thinking Archive'), findsNothing);
    expect(find.byTooltip('History'), findsNothing);
    expect(find.byTooltip('Weekly Recap'), findsNothing);
    expect(find.byTooltip('Source Admin'), findsNothing);
    expect(find.byTooltip('Diagnostics'), findsNothing);

    await tester.tap(find.byTooltip('Profile'));
    await tester.pumpAndSettle();

    expect(find.text('Profile'), findsOneWidget);
    expect(find.text('Thinking Archive'), findsOneWidget);
    expect(find.text('History'), findsOneWidget);
    expect(find.text('Weekly Recap'), findsOneWidget);

    await tester.tap(find.text('Thinking Archive'));
    await tester.pumpAndSettle();
    expect(find.text('Your archive is empty.'), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();

    await tester.tap(find.text('History'));
    await tester.pumpAndSettle();
    expect(find.text('History'), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();

    await tester.tap(find.text('Weekly Recap'));
    await tester.pumpAndSettle();
    expect(find.text('Weekly Recap'), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text('Content QA'),
      300,
      scrollable: find.byType(Scrollable).last,
    );
    expect(find.text('Developer tools'), findsOneWidget);
    expect(find.text('Content QA'), findsOneWidget);
    expect(find.text('Source Admin'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Diagnostics'),
      300,
      scrollable: find.byType(Scrollable).last,
    );
    expect(find.text('Diagnostics'), findsOneWidget);
    expect(find.text('Reset Onboarding'), findsOneWidget);
  });

  testWidgets('production Profile hides developer tools', (
    WidgetTester tester,
  ) async {
    final pack = DailyPack(
      dayId: '2026-06-08',
      focusAreas: const <String>['Product strategy'],
      items: MockDailyPack.forFocus(const <String>['Product strategy']),
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: SivraTheme.light(),
        darkTheme: SivraTheme.dark(),
        themeMode: ThemeMode.dark,
        home: ProfileScreen(
          uid: null,
          firstName: 'Alex',
          pack: pack,
          showDeveloperTools: false,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Thinking Archive'), findsOneWidget);
    expect(find.text('History'), findsOneWidget);
    expect(find.text('Weekly Recap'), findsOneWidget);
    expect(find.text('Developer tools'), findsNothing);
    expect(find.text('Content QA'), findsNothing);
    expect(find.text('Source Admin'), findsNothing);
    expect(find.text('Diagnostics'), findsNothing);
    expect(find.text('Reset Onboarding'), findsNothing);
  });

  testWidgets('developer Profile can reset onboarding for the current user', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final pack = DailyPack(
      dayId: '2026-06-08',
      focusAreas: const <String>['Product strategy'],
      items: MockDailyPack.forFocus(const <String>['Product strategy']),
    );
    var resetCalled = false;
    var completionCalled = false;

    await tester.pumpWidget(
      MaterialApp(
        theme: SivraTheme.light(),
        darkTheme: SivraTheme.dark(),
        themeMode: ThemeMode.dark,
        home: ProfileScreen(
          uid: 'test-user',
          firstName: 'Alex',
          pack: pack,
          showDeveloperTools: true,
          onResetOnboarding: () async {
            resetCalled = true;
          },
          onResetOnboardingComplete: (context) async {
            completionCalled = true;
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text('Reset Onboarding'),
      300,
      scrollable: find.byType(Scrollable).last,
    );
    final resetAction = find.byKey(
      const ValueKey('profile-action-Reset Onboarding'),
    );
    await tester.ensureVisible(resetAction);
    await tester.tap(resetAction);
    await tester.pumpAndSettle();

    expect(find.text('Reset onboarding?'), findsOneWidget);
    expect(
      find.textContaining('RevenueCat entitlements are not changed.'),
      findsOneWidget,
    );

    await tester.tap(find.text('Reset'));
    await tester.pumpAndSettle();

    expect(resetCalled, isTrue);
    expect(completionCalled, isTrue);
  });

  testWidgets('daily pack uses separate question and exit navigation', (
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

    await tester.tap(find.text('Begin Ritual'));
    await tester.pumpAndSettle();

    for (var i = 0; i < 6; i += 1) {
      expect(find.text('Question ${i + 1} of 8'), findsOneWidget);
      expect(
        tester
            .widget<TextButton>(find.byKey(const ValueKey('previous-question')))
            .onPressed,
        i == 0 ? isNull : isNotNull,
      );
      await tester.tap(find.text('Reveal'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();
    }

    expect(find.text('Question 7 of 8'), findsOneWidget);
    expect(find.text('Next'), findsOneWidget);

    await tester.enterText(
      find.byType(TextField),
      'It reduces avoidable work.',
    );
    await tester.pump();
    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();

    expect(find.text('Question 8 of 8'), findsOneWidget);
    expect(find.text('ANSWER'), findsOneWidget);
    expect(find.text('Finish'), findsOneWidget);

    await tester.tap(find.text('Previous'));
    await tester.pumpAndSettle();
    expect(find.text('Question 7 of 8'), findsOneWidget);
    final answerField = tester.widget<TextField>(find.byType(TextField));
    expect(answerField.controller?.text, 'It reduces avoidable work.');

    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Finish'));
    await tester.pumpAndSettle();

    expect(find.text('TODAY’S RITUAL'), findsOneWidget);
    expect(find.text('Review Ritual'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Ritual Streak  •  Day 1'),
      240,
      scrollable: find.byType(Scrollable).last,
    );
    expect(find.text('Ritual Streak  •  Day 1'), findsOneWidget);
  });

  testWidgets('top Back exits the drill after confirmation', (
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

    await tester.tap(find.text('Begin Ritual'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Reveal'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();

    expect(find.text('Question 2 of 8'), findsOneWidget);
    await tester.tap(find.text('Back'));
    await tester.pumpAndSettle();

    expect(find.text('Leave this drill?'), findsOneWidget);
    expect(find.text('Your progress will be saved.'), findsOneWidget);

    await tester.tap(find.text('Continue Drill'));
    await tester.pumpAndSettle();
    expect(find.text('Question 2 of 8'), findsOneWidget);

    await tester.tap(find.text('Back'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Leave'));
    await tester.pumpAndSettle();

    expect(find.text('TODAY’S RITUAL'), findsOneWidget);
    expect(find.text('Question 2 of 8'), findsNothing);
  });

  testWidgets('Sivra Pro prompt opens the custom paywall', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(800, 1800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        theme: SivraTheme.light(),
        darkTheme: SivraTheme.dark(),
        themeMode: ThemeMode.dark,
        home: const TodayScreen.preview(),
      ),
    );
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text('Sivra Pro'),
      300,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.tap(find.text('Sivra Pro'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Continue Building Your'), findsOneWidget);
    expect(find.text('Personalized Daily Rituals'), findsOneWidget);
    expect(find.text('Thinking Archive'), findsOneWidget);
    expect(find.text('Weekly Recaps'), findsOneWidget);
    expect(find.text('Fresh Source Context'), findsOneWidget);
    expect(find.text('RevenueCat hosted paywall'), findsNothing);

    await tester.tap(find.text('Continue Free'));
    await tester.pumpAndSettle();
    expect(find.text('TODAY’S RITUAL'), findsOneWidget);
  });

  testWidgets('custom paywall emphasizes annual without a monthly trial', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(800, 1800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final purchasedPlans = <String>[];

    await tester.pumpWidget(
      MaterialApp(
        theme: SivraTheme.light(),
        darkTheme: SivraTheme.dark(),
        themeMode: ThemeMode.dark,
        home: PaywallScreen(
          previewPlans: const <PaywallPlan>[
            PaywallPlan(
              id: 'annual',
              price: r'$99.99/year',
              recommended: true,
              hasTrial: true,
            ),
            PaywallPlan(
              id: 'monthly',
              price: r'$12.99/month',
              recommended: false,
              hasTrial: false,
            ),
          ],
          previewPurchase: (planId) async {
            purchasedPlans.add(planId);
            return const EntitlementState.free(
              entitlementId: 'sivra_pro',
              message: 'Preview purchase',
            );
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Recommended'), findsOneWidget);
    expect(find.text('7-Day Free Trial'), findsOneWidget);
    expect(find.text(r'$99.99/year'), findsOneWidget);
    expect(find.text(r'Equivalent to $8.33/month'), findsNothing);
    expect(find.text('Save 36%'), findsOneWidget);
    expect(find.textContaining(r'$55.89'), findsNothing);
    expect(find.text(r'$12.99/month'), findsOneWidget);
    expect(find.textContaining('Start 7-Day'), findsOneWidget);
    expect(find.text('Cancel anytime'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('purchase-monthly')),
      350,
      scrollable: find.byType(Scrollable).last,
    );
    final monthlyCard = find.byKey(const ValueKey('plan-monthly'));
    expect(
      find.descendant(of: monthlyCard, matching: find.text('7-Day Free Trial')),
      findsNothing,
    );

    await tester.tap(find.byKey(const ValueKey('purchase-annual')));
    await tester.pumpAndSettle();
    expect(purchasedPlans, <String>['annual']);

    await tester.tap(find.byKey(const ValueKey('purchase-monthly')));
    await tester.pumpAndSettle();
    expect(purchasedPlans, <String>['annual', 'monthly']);
    expect(find.text('Preview purchase'), findsOneWidget);
  });

  testWidgets(
    'custom paywall keeps restore wired through RevenueCat handling',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 1800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      var restored = false;

      await tester.pumpWidget(
        MaterialApp(
          theme: SivraTheme.light(),
          darkTheme: SivraTheme.dark(),
          themeMode: ThemeMode.dark,
          home: PaywallScreen(
            previewPlans: const <PaywallPlan>[
              PaywallPlan(
                id: 'annual',
                price: r'$99.99/year',
                recommended: true,
                hasTrial: true,
              ),
              PaywallPlan(
                id: 'monthly',
                price: r'$12.99/month',
                recommended: false,
                hasTrial: false,
              ),
            ],
            previewRestore: () async {
              restored = true;
              return const EntitlementState.free(
                entitlementId: 'sivra_pro',
                message: 'No active purchase found.',
              );
            },
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.text('Restore Purchases'),
        500,
        scrollable: find.byType(Scrollable).last,
      );
      await tester.tap(find.text('Restore Purchases'));
      await tester.pumpAndSettle();

      expect(restored, isTrue);
      expect(find.text('No active purchase found.'), findsOneWidget);
    },
  );

  testWidgets('custom paywall opens privacy and terms links', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(800, 1800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final openedUris = <Uri>[];

    await tester.pumpWidget(
      MaterialApp(
        theme: SivraTheme.light(),
        darkTheme: SivraTheme.dark(),
        themeMode: ThemeMode.dark,
        home: PaywallScreen(
          previewPlans: const <PaywallPlan>[
            PaywallPlan(
              id: 'annual',
              price: r'$99.99/year',
              recommended: true,
              hasTrial: true,
            ),
            PaywallPlan(
              id: 'monthly',
              price: r'$12.99/month',
              recommended: false,
              hasTrial: false,
            ),
          ],
          launchExternalUrl: (uri) async {
            openedUris.add(uri);
            return true;
          },
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Privacy Policy'),
      500,
      scrollable: find.byType(Scrollable).last,
    );

    await tester.tap(find.text('Privacy Policy'));
    await tester.pump();
    await tester.tap(find.text('Terms of Use'));
    await tester.pump();

    expect(openedUris, <Uri>[
      Uri.parse('https://sivra.pro/privacy'),
      Uri.parse('https://sivra.pro/terms'),
    ]);
  });

  testWidgets('custom paywall scrolls cleanly across target iPhone viewports', (
    WidgetTester tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.viewPadding = const FakeViewPadding(bottom: 20);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetViewPadding);

    for (final size in const <Size>[
      Size(320, 568),
      Size(390, 844),
      Size(402, 874),
    ]) {
      tester.view.physicalSize = size;
      await tester.pumpWidget(
        MaterialApp(
          theme: SivraTheme.light(),
          darkTheme: SivraTheme.dark(),
          themeMode: ThemeMode.dark,
          home: const PaywallScreen(
            previewPlans: <PaywallPlan>[
              PaywallPlan(
                id: 'annual',
                price: r'$99.99/year',
                recommended: true,
                hasTrial: true,
              ),
              PaywallPlan(
                id: 'monthly',
                price: r'$12.99/month',
                recommended: false,
                hasTrial: false,
              ),
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();

      if (size.height <= 900) {
        expect(find.byType(SingleChildScrollView), findsNothing);
      } else {
        expect(find.byType(SingleChildScrollView), findsOneWidget);
      }
      expect(find.byKey(const ValueKey('plan-annual')), findsOneWidget);
      expect(find.byKey(const ValueKey('plan-monthly')), findsOneWidget);
      expect(tester.takeException(), isNull);

      final benefitRects = <Rect>[
        tester.getRect(
          find.byKey(const ValueKey('benefit-Personalized Daily Rituals')),
        ),
        tester.getRect(find.byKey(const ValueKey('benefit-Thinking Archive'))),
        tester.getRect(find.byKey(const ValueKey('benefit-Weekly Recaps'))),
        tester.getRect(
          find.byKey(const ValueKey('benefit-Fresh Source Context')),
        ),
      ];
      final firstBenefitHeight = benefitRects.first.height;
      expect(
        benefitRects.every(
          (rect) => (rect.height - firstBenefitHeight).abs() < 0.5,
        ),
        isTrue,
      );

      final annualRect = tester.getRect(
        find.byKey(const ValueKey('plan-annual')),
      );
      final monthlyRect = tester.getRect(
        find.byKey(const ValueKey('plan-monthly')),
      );
      final footerRect = tester.getRect(find.text('Restore Purchases'));
      final continueFreeRect = tester.getRect(find.text('Continue Free'));
      final privacyRect = tester.getRect(find.text('Privacy Policy'));
      final termsRect = tester.getRect(find.text('Terms of Use'));

      expect(monthlyRect.top, closeTo(annualRect.top, 0.1));
      expect(monthlyRect.height, closeTo(annualRect.height, 0.1));
      expect(monthlyRect.bottom, closeTo(annualRect.bottom, 0.1));
      expect(footerRect.top, greaterThan(annualRect.bottom));
      expect(footerRect.bottom, lessThanOrEqualTo(size.height));
      expect(continueFreeRect.bottom, lessThanOrEqualTo(size.height));
      expect(privacyRect.bottom, lessThanOrEqualTo(size.height));
      expect(termsRect.bottom, lessThanOrEqualTo(size.height));
      expect(find.text(r'Equivalent to $8.33/month'), findsNothing);
      expect(find.text('Privacy Policy'), findsOneWidget);
      expect(find.text('Terms of Use'), findsOneWidget);
      expect(tester.takeException(), isNull);

      await tester.pumpWidget(const SizedBox.shrink());
    }
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

  test('thought repository selects a stable theme-aware thought', () {
    const repository = LocalThoughtRepository();

    final first = repository.getThoughtForTheme(
      'Product strategy',
      seed: '2026-06-08',
    );
    final second = repository.getThoughtForTheme(
      'Product strategy',
      seed: '2026-06-08',
    );

    expect(first.id, second.id);
    expect(first.theme, 'product_strategy');
    expect(first.active, isTrue);
  });

  test('daily thought engine rotates selected themes and their thoughts', () {
    const engine = DailyThoughtEngine();
    const focusAreas = <String>['Product strategy', 'Infra & costs'];

    final first = engine.thoughtForDay(
      dayId: '2026-06-08',
      focusAreas: focusAreas,
    );
    final second = engine.thoughtForDay(
      dayId: '2026-06-09',
      focusAreas: focusAreas,
    );
    final third = engine.thoughtForDay(
      dayId: '2026-06-10',
      focusAreas: focusAreas,
    );

    expect(first.theme, isNot(second.theme));
    expect(third.theme, first.theme);
    expect(third.id, isNot(first.id));
  });

  test(
    'daily thought engine uses Founder when no focus areas are selected',
    () {
      const engine = DailyThoughtEngine();

      final thought = engine.thoughtForDay(
        dayId: '2026-06-08',
        focusAreas: const <String>[],
      );

      expect(thought.theme, 'founder');
    },
  );

  test('thought repository normalizes themes and falls back to Founder', () {
    const repository = LocalThoughtRepository();

    final infrastructure = repository.getThoughtForTheme(
      'Infra & costs',
      seed: '2026-06-08',
    );
    final fallback = repository.getThoughtForTheme(
      'Unmapped theme',
      seed: '2026-06-08',
    );

    expect(infrastructure.theme, 'infrastructure_costs');
    expect(fallback.theme, 'founder');
  });

  test('local thoughts are curated for short-form display', () {
    expect(
      localThoughts.every(
        (thought) => thought.quote.length >= 20 && thought.quote.length <= 70,
      ),
      isTrue,
    );
  });

  test('thought model uses the future Firestore document shape', () {
    const thought = Thought(
      id: 'leadership_1',
      theme: 'leadership',
      quote: 'Trust travels faster than authority.',
      tags: <String>['leadership', 'trust'],
    );

    final restored = Thought.fromMap(id: thought.id, data: thought.toMap());

    expect(restored.id, thought.id);
    expect(restored.quote, thought.quote);
    expect(restored.theme, thought.theme);
    expect(restored.tags, thought.tags);
    expect(restored.active, isTrue);
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

  test('weekly recap reveals ranked themes and reflection patterns', () {
    final items = MockDailyPack.forFocus(const <String>['Product strategy']);

    DailyPack completedPack(
      String dayId,
      List<String> themes, {
      String? insight,
    }) {
      return DailyPack(
        dayId: dayId,
        focusAreas: themes,
        items: items,
        completedItemIds: items.take(3).map((item) => item.id).toList(),
        answersByItemId: insight == null
            ? const <String, String>{}
            : <String, String>{items[6].id: insight},
        completedAt: DateTime.parse(dayId),
      );
    }

    final recap = WeeklyRecap.fromPacks(<DailyPack>[
      completedPack('2026-06-02', const <String>['Product strategy']),
      completedPack('2026-06-03', const <String>['Product strategy']),
      completedPack('2026-06-05', const <String>[
        'Product strategy',
        'Infra & costs',
      ]),
      completedPack('2026-06-07', const <String>[
        'Infra & costs',
        'Hiring & team',
      ]),
      completedPack('2026-06-08', const <String>[
        'Product strategy',
        'Infra & costs',
        'Hiring & team',
      ], insight: 'The constraint is clarity, not capacity.'),
      completedPack('2026-05-31', const <String>[
        'GTM & sales',
      ], insight: 'This is outside the recap window.'),
    ], referenceDate: DateTime(2026, 6, 8));

    expect(recap.completedPackCount, 5);
    expect(recap.primaryThemes.map((theme) => theme.name), <String>[
      'Product Strategy',
      'Infrastructure & Costs',
      'Hiring & Team',
    ]);
    expect(recap.primaryThemes.first.ritualCount, 4);
    expect(
      recap.thinkingPatterns,
      contains('You returned to Product Strategy 4 times this week.'),
    );
    expect(
      recap.thinkingPatterns,
      contains(
        'Your focus shifted toward execution during the second half of the week.',
      ),
    );
    expect(
      recap.mostValuableInsight,
      'The constraint is clarity, not capacity.',
    );
    expect(recap.lookingAhead, contains('Product Strategy'));
  });

  test('weekly recap ignores incomplete rituals and handles no insight', () {
    final items = MockDailyPack.forFocus(const <String>['Product strategy']);
    final recap = WeeklyRecap.fromPacks(<DailyPack>[
      DailyPack(
        dayId: '2026-06-08',
        focusAreas: const <String>['Product strategy'],
        items: items,
      ),
      DailyPack(
        dayId: '2026-06-07',
        focusAreas: const <String>['GTM & sales'],
        items: items,
        completedAt: DateTime(2026, 6, 7),
      ),
    ], referenceDate: DateTime(2026, 6, 8));

    expect(recap.packCount, 2);
    expect(recap.completedPackCount, 1);
    expect(recap.focusAreas, <String>['GTM & Sales']);
    expect(recap.mostValuableInsight, isNull);
  });

  testWidgets('weekly recap presents reflection sections without analytics', (
    WidgetTester tester,
  ) async {
    final items = MockDailyPack.forFocus(const <String>['Product strategy']);
    final pack = DailyPack(
      dayId: '2026-06-08',
      focusAreas: const <String>['Product strategy', 'Infra & costs'],
      items: items,
      completedItemIds: items.map((item) => item.id).toList(),
      answersByItemId: <String, String>{
        items[6].id: 'The best next step is to reduce uncertainty.',
      },
      completedAt: DateTime(2026, 6, 8),
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: SivraTheme.light(),
        darkTheme: SivraTheme.dark(),
        themeMode: ThemeMode.dark,
        home: WeeklyRecapScreen(
          previewPacks: <DailyPack>[pack],
          referenceDate: DateTime(2026, 6, 8),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Week In Review'), findsOneWidget);
    expect(
      find.text(
        'A reflection on the ideas, decisions, and themes that shaped your week.',
      ),
      findsOneWidget,
    );
    expect(find.text('Your strongest themes this week'), findsOneWidget);
    expect(find.text('Product Strategy'), findsWidgets);
    expect(find.byType(LinearProgressIndicator), findsNothing);

    await tester.scrollUntilVisible(
      find.text('Most Valuable Insight'),
      300,
      scrollable: find.byType(Scrollable).last,
    );
    expect(
      find.text('“The best next step is to reduce uncertainty.”'),
      findsOneWidget,
    );

    await tester.scrollUntilVisible(
      find.text('Rituals Completed'),
      300,
      scrollable: find.byType(Scrollable).last,
    );
    expect(find.text('1 of 7 days'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('Carry one thread forward'),
      300,
      scrollable: find.byType(Scrollable).last,
    );
    expect(find.textContaining('Product Strategy'), findsWidgets);
  });

  testWidgets('weekly recap has a graceful empty state', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: SivraTheme.light(),
        darkTheme: SivraTheme.dark(),
        themeMode: ThemeMode.dark,
        home: WeeklyRecapScreen(
          previewPacks: const <DailyPack>[],
          referenceDate: DateTime(2026, 6, 8),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Week In Review'), findsOneWidget);
    expect(
      find.text('Complete more rituals to unlock your first Weekly Recap.'),
      findsOneWidget,
    );
  });

  test('thinking archive builds a reverse-chronological repository', () {
    final items = MockDailyPack.forFocus(const <String>['Product strategy']);

    DailyPack archivedPack(String dayId, String theme, String insight) {
      return DailyPack(
        dayId: dayId,
        focusAreas: <String>[theme],
        items: items,
        completedItemIds: items.map((item) => item.id).toList(),
        answersByItemId: <String, String>{items[6].id: insight},
        completedAt: DateTime.parse(dayId),
      );
    }

    final archive = ThinkingArchive.fromPacks(<DailyPack>[
      archivedPack('2026-06-01', 'Product strategy', 'The first insight.'),
      archivedPack('2026-06-05', 'Infra & costs', 'The second insight.'),
      archivedPack('2026-06-08', 'Product strategy', 'The newest insight.'),
      DailyPack(
        dayId: '2026-06-07',
        focusAreas: const <String>['GTM & sales'],
        items: items,
      ),
    ]);

    expect(archive.entries.map((entry) => entry.text), <String>[
      'The newest insight.',
      'The second insight.',
      'The first insight.',
    ]);
    expect(archive.completedRitualCount, 3);
    expect(archive.strongestTheme, 'Product Strategy');
    expect(archive.revisitEntry?.text, 'The first insight.');
    expect(archive.entries.first.ritualId, '2026-06-08');
    expect(archive.entries.first.id, '2026-06-08-${items[6].id}');
  });

  testWidgets('thinking archive filters themes and surfaces older thinking', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(800, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final items = MockDailyPack.forFocus(const <String>['Product strategy']);

    DailyPack archivedPack(String dayId, String theme, String insight) {
      return DailyPack(
        dayId: dayId,
        focusAreas: <String>[theme],
        items: items,
        completedItemIds: items.map((item) => item.id).toList(),
        answersByItemId: <String, String>{items[6].id: insight},
        completedAt: DateTime.parse(dayId),
      );
    }

    await tester.pumpWidget(
      MaterialApp(
        theme: SivraTheme.light(),
        darkTheme: SivraTheme.dark(),
        themeMode: ThemeMode.dark,
        home: LearningMemoryScreen(
          previewPacks: <DailyPack>[
            archivedPack(
              '2026-06-03',
              'Infra & costs',
              'Reliability should be designed before scale.',
            ),
            archivedPack(
              '2026-06-08',
              'Product strategy',
              'Distribution belongs in the product plan.',
            ),
          ],
          referenceDate: DateTime(2026, 6, 8),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.text(
        'A record of the ideas, insights, and decisions captured through your rituals.',
      ),
      findsOneWidget,
    );
    expect(find.text('2'), findsNWidgets(2));
    expect(
      find.text('Distribution belongs in the product plan.'),
      findsNothing,
    );
    expect(
      find.text('“Distribution belongs in the product plan.”'),
      findsOneWidget,
    );
    expect(find.text('Captured today'), findsOneWidget);
    expect(find.text('Captured 5 days ago'), findsOneWidget);

    await tester.tap(find.widgetWithText(FilterChip, 'Infrastructure & Costs'));
    await tester.pumpAndSettle();

    expect(
      find.text('“Distribution belongs in the product plan.”'),
      findsNothing,
    );
    expect(
      find.text('“Reliability should be designed before scale.”'),
      findsWidgets,
    );

    await tester.scrollUntilVisible(
      find.text('Revisit This Insight'),
      300,
      scrollable: find.byType(Scrollable).last,
    );
    expect(find.text('Ideas become valuable when revisited.'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('Strongest Theme'),
      300,
      scrollable: find.byType(Scrollable).last,
    );
    expect(
      find.text('This theme appeared most often in your recent rituals.'),
      findsOneWidget,
    );
  });

  testWidgets('thinking archive empty state returns to today', (
    WidgetTester tester,
  ) async {
    var returned = false;

    await tester.pumpWidget(
      MaterialApp(
        theme: SivraTheme.light(),
        darkTheme: SivraTheme.dark(),
        themeMode: ThemeMode.dark,
        home: LearningMemoryScreen(
          previewPacks: const <DailyPack>[],
          onReturnToRitual: () {
            returned = true;
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Your archive is empty.'), findsOneWidget);
    await tester.tap(find.text('Return to Today’s Ritual'));
    expect(returned, isTrue);
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

void _noop() {}
