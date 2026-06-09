import 'package:flutter/material.dart';

import '../data/mock_daily_pack.dart';
import '../design/sivra_colors.dart';
import '../models/daily_pack.dart';
import '../models/drill_item.dart';
import '../utils/day_id.dart';
import 'drill_flow_screen.dart';
import 'learning_memory_screen.dart';
import 'onboarding_screen.dart';
import 'paywall_screen.dart';
import 'source_sheet.dart';
import 'today_screen.dart';

class ScreenshotPreviewScreen extends StatelessWidget {
  final String screen;

  const ScreenshotPreviewScreen({super.key, required this.screen});

  @override
  Widget build(BuildContext context) {
    final pack = _screenshotPack();

    return switch (screen) {
      'today-ready' => const TodayScreen.preview(
        initialFocusAreas: <String>['Product strategy', 'Infra & costs'],
      ),
      'onboarding-focus' => OnboardingScreen(
        uid: 'screenshot',
        analyticsEnabled: false,
        initialSelectedFocus: const <String>['Product strategy'],
        initialStepIndex: 2,
        onCompleted: () {},
      ),
      'articulation-answer' => DrillFlowScreen(
        items: pack.items,
        dayId: pack.dayId,
        initialIndex: 6,
        initialArticulationAnswer:
            'AI reduces avoidable work by giving teams clearer starting points, faster review cycles, and stronger checks before launch.\n\nThe value is not replacing judgment.\n\nThe value is helping good judgment move faster with less confusion.',
      ),
      'drill-navigation' => DrillFlowScreen(
        items: pack.items,
        dayId: pack.dayId,
        initialIndex: 4,
      ),
      'source-context' => _SourceContextPreview(
        item: pack.items.firstWhere((item) => item.hasSource),
      ),
      'learning-memory' => LearningMemoryScreen(pack: pack),
      'paywall' => const PaywallScreen(
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
      _ => _UnknownScreenshotScreen(screen: screen),
    };
  }

  DailyPack _screenshotPack() {
    final items = MockDailyPack.forFocus(const <String>[
      'Product strategy',
      'Infra & costs',
    ]);
    final answerItem = items.firstWhere(
      (item) => item.type == DrillItemType.articulation,
    );

    return DailyPack(
      dayId: dayIdFromDate(DateTime.now()),
      focusAreas: const <String>['Product strategy', 'Infra & costs'],
      items: items,
      completedItemIds: items.map((item) => item.id).toList(),
      answersByItemId: <String, String>{
        answerItem.id:
            'AI reduces avoidable work by giving teams clearer starting points, faster review cycles, and stronger checks before launch.\n\nThe value is not replacing judgment.\n\nThe value is helping good judgment move faster with less confusion.',
      },
      completedAt: DateTime.now(),
    );
  }
}

class _SourceContextPreview extends StatelessWidget {
  final DrillItem item;

  const _SourceContextPreview({required this.item});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Today’s Ritual')),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ActionChip(
                      label: const Text('Source Context'),
                      onPressed: () {},
                    ),
                    const SizedBox(height: 12),
                    Text(
                      item.prompt,
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'ANSWER',
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: SivraColors.bronze,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(item.answer ?? ''),
                  ],
                ),
              ),
            ),
            DecoratedBox(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                border: Border(
                  top: BorderSide(
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withValues(alpha: 0.12),
                  ),
                ),
              ),
              child: SourceSheet(source: item.source!),
            ),
          ],
        ),
      ),
    );
  }
}

class _UnknownScreenshotScreen extends StatelessWidget {
  final String screen;

  const _UnknownScreenshotScreen({required this.screen});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(child: Text('Unknown screenshot screen: $screen')),
    );
  }
}
