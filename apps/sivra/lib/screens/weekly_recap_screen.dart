import 'package:flutter/material.dart';

import '../design/sivra_colors.dart';
import '../models/daily_pack.dart';
import '../models/weekly_recap.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';

class WeeklyRecapScreen extends StatefulWidget {
  final String? uid;
  final List<DailyPack>? previewPacks;
  final DateTime? referenceDate;

  const WeeklyRecapScreen({
    super.key,
    this.uid,
    this.previewPacks,
    this.referenceDate,
  });

  @override
  State<WeeklyRecapScreen> createState() => _WeeklyRecapScreenState();
}

class _WeeklyRecapScreenState extends State<WeeklyRecapScreen> {
  late Future<WeeklyRecap> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<WeeklyRecap> _load() async {
    final previewPacks = widget.previewPacks;
    if (previewPacks != null) {
      return WeeklyRecap.fromPacks(
        previewPacks,
        referenceDate: widget.referenceDate,
      );
    }

    final uid = widget.uid ?? AuthService.instance.currentUser?.uid;
    if (uid == null) {
      return const WeeklyRecap.empty();
    }

    final packs = await FirestoreService.instance.getRecentDailyPacks(
      uid: uid,
      limit: 14,
    );
    return WeeklyRecap.fromPacks(packs, referenceDate: widget.referenceDate);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Weekly Recap')),
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              SivraColors.ritualGradientTop,
              SivraColors.deepInk,
              SivraColors.ritualGradientBottom,
            ],
            stops: [0, 0.52, 1],
          ),
        ),
        child: SafeArea(
          child: FutureBuilder<WeeklyRecap>(
            future: _future,
            builder: (context, snapshot) {
              if (snapshot.connectionState != ConnectionState.done) {
                return const Center(
                  child: Text('Preparing your reflection...'),
                );
              }

              final recap = snapshot.data ?? const WeeklyRecap.empty();
              if (!recap.hasCompletedRituals) {
                return const _EmptyRecap();
              }

              return _RecapContent(recap: recap);
            },
          ),
        ),
      ),
    );
  }
}

class _RecapContent extends StatelessWidget {
  final WeeklyRecap recap;

  const _RecapContent({required this.recap});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 40),
      children: [
        const _ReviewHeader(),
        const SizedBox(height: 30),
        _SectionLabel(
          eyebrow: 'PRIMARY THEMES',
          title: 'Your strongest themes this week',
        ),
        const SizedBox(height: 14),
        Wrap(
          spacing: 9,
          runSpacing: 9,
          children: recap.primaryThemes
              .map((theme) => _ThemeChip(theme: theme))
              .toList(),
        ),
        const SizedBox(height: 32),
        const _SectionLabel(
          eyebrow: 'THINKING PATTERNS',
          title: 'What kept returning',
        ),
        const SizedBox(height: 14),
        _ReflectionCard(
          child: Column(
            children: recap.thinkingPatterns
                .map((pattern) => _PatternRow(text: pattern))
                .toList(),
          ),
        ),
        const SizedBox(height: 32),
        const _SectionLabel(
          eyebrow: 'SAVED THINKING',
          title: 'Most Valuable Insight',
        ),
        const SizedBox(height: 14),
        _InsightCard(
          insight: recap.mostValuableInsight,
          theme: recap.insightTheme,
        ),
        const SizedBox(height: 32),
        const _SectionLabel(
          eyebrow: 'RITUAL CONSISTENCY',
          title: 'A simple view of the week',
        ),
        const SizedBox(height: 14),
        _ConsistencyCard(completed: recap.completedPackCount),
        const SizedBox(height: 32),
        const _SectionLabel(
          eyebrow: 'LOOKING AHEAD',
          title: 'Carry one thread forward',
        ),
        const SizedBox(height: 14),
        _LookingAheadCard(text: recap.lookingAhead),
      ],
    );
  }
}

class _ReviewHeader extends StatelessWidget {
  const _ReviewHeader();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(22, 24, 22, 23),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            SivraColors.surfaceSoft.withValues(alpha: 0.96),
            SivraColors.surface.withValues(alpha: 0.88),
            SivraColors.ritualGradientBottom,
          ],
        ),
        border: Border.all(color: SivraColors.bronze.withValues(alpha: 0.22)),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 34,
            spreadRadius: -12,
            offset: const Offset(0, 20),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'WEEKLY REFLECTION',
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: SivraColors.bronze,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.4,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Week In Review',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              color: SivraColors.warmIvory,
              fontWeight: FontWeight.w600,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'A reflection on the ideas, decisions, and themes that shaped your week.',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: SivraColors.mutedText,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String eyebrow;
  final String title;

  const _SectionLabel({required this.eyebrow, required this.title});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          eyebrow,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
            color: SivraColors.bronze,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 7),
        Text(
          title,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            color: SivraColors.warmIvory,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.2,
          ),
        ),
      ],
    );
  }
}

class _ThemeChip extends StatelessWidget {
  final WeeklyTheme theme;

  const _ThemeChip({required this.theme});

  @override
  Widget build(BuildContext context) {
    return Chip(
      avatar: Text(
        '${theme.ritualCount}',
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: SivraColors.bronze,
          fontWeight: FontWeight.w700,
        ),
      ),
      label: Text(theme.name),
      backgroundColor: SivraColors.surface.withValues(alpha: 0.62),
      side: BorderSide(color: SivraColors.bronze.withValues(alpha: 0.18)),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    );
  }
}

class _ReflectionCard extends StatelessWidget {
  final Widget child;

  const _ReflectionCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 7, 18, 7),
      decoration: BoxDecoration(
        color: SivraColors.surface.withValues(alpha: 0.62),
        border: Border.all(color: SivraColors.bronze.withValues(alpha: 0.13)),
        borderRadius: BorderRadius.circular(20),
      ),
      child: child,
    );
  }
}

class _PatternRow extends StatelessWidget {
  final String text;

  const _PatternRow({required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 6,
            height: 6,
            margin: const EdgeInsets.only(top: 8),
            decoration: const BoxDecoration(
              color: SivraColors.bronze,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: SivraColors.warmIvory.withValues(alpha: 0.9),
                height: 1.48,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InsightCard extends StatelessWidget {
  final String? insight;
  final String? theme;

  const _InsightCard({required this.insight, required this.theme});

  @override
  Widget build(BuildContext context) {
    final value = insight;
    return Container(
      padding: const EdgeInsets.fromLTRB(22, 22, 22, 21),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            SivraColors.surfaceSoft,
            SivraColors.surface.withValues(alpha: 0.92),
          ],
        ),
        border: Border.all(color: SivraColors.bronze.withValues(alpha: 0.28)),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.28),
            blurRadius: 30,
            spreadRadius: -14,
            offset: const Offset(0, 18),
          ),
        ],
      ),
      child: value == null
          ? Text(
              'Save a written response during a ritual to surface an insight here.',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: SivraColors.mutedText,
                height: 1.5,
              ),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.format_quote_rounded,
                  color: SivraColors.bronze,
                  size: 28,
                ),
                const SizedBox(height: 12),
                Text(
                  '“$value”',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: SivraColors.warmIvory,
                    fontWeight: FontWeight.w500,
                    height: 1.45,
                  ),
                ),
                if (theme != null) ...[
                  const SizedBox(height: 16),
                  Text(
                    theme!,
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: SivraColors.bronze,
                      letterSpacing: 0.7,
                    ),
                  ),
                ],
              ],
            ),
    );
  }
}

class _ConsistencyCard extends StatelessWidget {
  final int completed;

  const _ConsistencyCard({required this.completed});

  @override
  Widget build(BuildContext context) {
    return _ReflectionCard(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 15),
        child: Row(
          children: [
            Expanded(
              child: Text(
                'Rituals Completed',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: SivraColors.warmIvory,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Text(
              '$completed of 7 days',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: SivraColors.bronze,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LookingAheadCard extends StatelessWidget {
  final String text;

  const _LookingAheadCard({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: SivraColors.bronze.withValues(alpha: 0.09),
        border: Border.all(color: SivraColors.bronze.withValues(alpha: 0.24)),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          color: SivraColors.warmIvory,
          fontWeight: FontWeight.w500,
          height: 1.5,
        ),
      ),
    );
  }
}

class _EmptyRecap extends StatelessWidget {
  const _EmptyRecap();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 40),
      children: [
        const _ReviewHeader(),
        const SizedBox(height: 28),
        Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: SivraColors.surface.withValues(alpha: 0.62),
            border: Border.all(
              color: SivraColors.bronze.withValues(alpha: 0.14),
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Your first reflection is taking shape.',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: SivraColors.warmIvory,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Complete more rituals to unlock your first Weekly Recap.',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: SivraColors.mutedText,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
