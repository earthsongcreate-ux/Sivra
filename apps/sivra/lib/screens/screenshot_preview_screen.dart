import 'package:flutter/material.dart';

import '../data/mock_daily_pack.dart';
import '../models/daily_pack.dart';
import '../models/drill_item.dart';
import '../utils/day_id.dart';
import 'drill_flow_screen.dart';
import 'learning_memory_screen.dart';
import 'onboarding_screen.dart';
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
      'source-context' => _SourceContextPreview(
        item: pack.items.firstWhere((item) => item.hasSource),
      ),
      'learning-memory' => LearningMemoryScreen(pack: pack),
      'paywall' => const _PaywallPreview(),
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
      appBar: AppBar(title: const Text('Daily Pack')),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ActionChip(label: const Text('Source'), onPressed: () {}),
                    const SizedBox(height: 12),
                    Text(
                      item.prompt,
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Answer',
                      style: Theme.of(context).textTheme.titleMedium,
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

class _PaywallPreview extends StatelessWidget {
  const _PaywallPreview();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Sivra Pro')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
          children: [
            Text('Unlock AI Pack Generation', style: textTheme.headlineSmall),
            const SizedBox(height: 10),
            Text(
              'Start with a 7-day free trial. Sivra Pro creates fresh daily packs from your focus areas, learning memory, and trusted source rules.',
              style: textTheme.bodyMedium?.copyWith(
                color: colors.onSurface.withValues(alpha: 0.74),
              ),
            ),
            const SizedBox(height: 22),
            const _PreviewBenefit(
              icon: Icons.auto_awesome_outlined,
              label: 'Personalized AI-generated daily packs',
            ),
            const _PreviewBenefit(
              icon: Icons.verified_outlined,
              label: 'Source trust and content QA checks',
            ),
            const _PreviewBenefit(
              icon: Icons.insights_outlined,
              label: 'Learning memory that adapts over time',
            ),
            const SizedBox(height: 22),
            const _PreviewPlanTile(
              title: 'Annual',
              detail: '7-day free trial, then \$99.99 per year.',
              badge: 'Best value',
            ),
            const SizedBox(height: 12),
            const _PreviewPlanTile(
              title: 'Monthly',
              detail: '7-day free trial, then \$12.99 per month.',
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () {},
              child: const Text('Restore purchases'),
            ),
            TextButton(onPressed: () {}, child: const Text('Continue free')),
          ],
        ),
      ),
    );
  }
}

class _PreviewBenefit extends StatelessWidget {
  final IconData icon;
  final String label;

  const _PreviewBenefit({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Icon(icon, size: 20, color: colors.primary),
          const SizedBox(width: 10),
          Expanded(child: Text(label)),
        ],
      ),
    );
  }
}

class _PreviewPlanTile extends StatelessWidget {
  final String title;
  final String detail;
  final String? badge;

  const _PreviewPlanTile({
    required this.title,
    required this.detail,
    this.badge,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border.all(color: colors.primary.withValues(alpha: 0.48)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(child: Text(title, style: textTheme.titleMedium)),
                if (badge != null)
                  Text(
                    badge!,
                    style: textTheme.labelMedium?.copyWith(
                      color: colors.primary,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              detail,
              style: textTheme.bodyMedium?.copyWith(
                color: colors.onSurface.withValues(alpha: 0.72),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () {},
                child: const Text('Start free trial'),
              ),
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
