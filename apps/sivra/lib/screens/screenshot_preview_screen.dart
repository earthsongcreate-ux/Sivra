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
import 'weekly_recap_screen.dart';

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
      'onboarding-promise' => _onboardingPreview(stepIndex: 0),
      'onboarding-ritual' => _onboardingPreview(stepIndex: 1),
      'onboarding-focus' => _onboardingPreview(
        stepIndex: 2,
        includeSelections: true,
      ),
      'onboarding-memory' => _onboardingPreview(
        stepIndex: 3,
        includeSelections: true,
      ),
      'onboarding-ready' => _onboardingPreview(
        stepIndex: 4,
        includeSelections: true,
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
      'source-context' => _SourceContextPreview(item: _briefingItem()),
      'learning-memory' => LearningMemoryScreen(
        previewPacks: _screenshotHistory(),
        referenceDate: DateTime(2026, 6, 12),
      ),
      'weekly-recap' => WeeklyRecapScreen(
        previewPacks: _screenshotHistory(),
        referenceDate: DateTime(2026, 6, 12),
      ),
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

  OnboardingScreen _onboardingPreview({
    required int stepIndex,
    bool includeSelections = false,
  }) {
    return OnboardingScreen(
      uid: 'screenshot',
      analyticsEnabled: false,
      initialSelectedFocus: includeSelections
          ? const <String>['Founder', 'Product / Strategy', 'Operator']
          : const <String>[],
      initialStepIndex: stepIndex,
      onCompleted: () {},
    );
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

  DrillItem _briefingItem() {
    return const DrillItem(
      id: 'briefing-trust',
      type: DrillItemType.briefing,
      prompt: 'Operational readiness matters more than model novelty.',
      answer:
          'The strongest teams separate capability from readiness. They pair each new model with clear evaluation criteria, human review, and a rollback path before it reaches a critical workflow.',
      explanation:
          'Good judgment starts with evidence you can inspect, not a headline you have to trust.',
      source: DrillItemSource(
        title: 'Artificial Intelligence Risk Management Framework',
        publisher: 'National Institute of Standards and Technology',
        dateLabel: 'NIST AI 100-1',
        url: 'https://www.nist.gov/itl/ai-risk-management-framework',
        snippet:
            'A practical framework for governing, mapping, measuring, and managing AI risk across real-world systems.',
      ),
    );
  }

  List<DailyPack> _screenshotHistory() {
    final items = MockDailyPack.forFocus(const <String>['Product strategy']);

    DailyPack completedPack({
      required String dayId,
      required List<String> focusAreas,
      required String insight,
    }) {
      return DailyPack(
        dayId: dayId,
        focusAreas: focusAreas,
        items: items,
        completedItemIds: items.map((item) => item.id).toList(),
        answersByItemId: <String, String>{items[6].id: insight},
        completedAt: DateTime.parse(dayId),
      );
    }

    return <DailyPack>[
      completedPack(
        dayId: '2026-06-07',
        focusAreas: const <String>['Product strategy'],
        insight:
            'The moat is not model access. It is the workflow, trust, and learning loop around it.',
      ),
      completedPack(
        dayId: '2026-06-08',
        focusAreas: const <String>['Product strategy', 'GTM & sales'],
        insight:
            'A sharper strategy names the decision it changes, not just the technology it uses.',
      ),
      completedPack(
        dayId: '2026-06-10',
        focusAreas: const <String>['Infra & costs', 'Product strategy'],
        insight:
            'Reliability should be designed before scale, with evals and rollback paths made explicit.',
      ),
      completedPack(
        dayId: '2026-06-11',
        focusAreas: const <String>['Product strategy', 'Hiring & team'],
        insight:
            'The clearest executive answer begins with the tradeoff, then the recommendation.',
      ),
      completedPack(
        dayId: '2026-06-12',
        focusAreas: const <String>['Product strategy', 'Infra & costs'],
        insight:
            'Move faster by reducing uncertainty first, then committing the team to one clear direction.',
      ),
    ];
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
