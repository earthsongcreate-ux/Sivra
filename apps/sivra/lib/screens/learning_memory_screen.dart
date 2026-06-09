import 'package:flutter/material.dart';

import '../design/sivra_colors.dart';
import '../models/archive_entry.dart';
import '../models/daily_pack.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';

class LearningMemoryScreen extends StatefulWidget {
  final String? uid;
  final DailyPack? pack;
  final List<DailyPack>? previewPacks;
  final VoidCallback? onReturnToRitual;
  final DateTime? referenceDate;

  const LearningMemoryScreen({
    super.key,
    this.uid,
    this.pack,
    this.previewPacks,
    this.onReturnToRitual,
    this.referenceDate,
  });

  @override
  State<LearningMemoryScreen> createState() => _LearningMemoryScreenState();
}

class _LearningMemoryScreenState extends State<LearningMemoryScreen> {
  late Future<ThinkingArchive> _future;
  String? _selectedTheme;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<ThinkingArchive> _load() async {
    final previewPacks = widget.previewPacks;
    if (previewPacks != null) {
      return ThinkingArchive.fromPacks(previewPacks);
    }
    final pack = widget.pack;
    if (pack != null) {
      return ThinkingArchive.fromPacks(<DailyPack>[pack]);
    }

    final uid = widget.uid ?? AuthService.instance.currentUser?.uid;
    if (uid == null) {
      return const ThinkingArchive.empty();
    }
    final packs = await FirestoreService.instance.getRecentDailyPacks(
      uid: uid,
      limit: 100,
    );
    return ThinkingArchive.fromPacks(packs);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Thinking Archive')),
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
          child: FutureBuilder<ThinkingArchive>(
            future: _future,
            builder: (context, snapshot) {
              if (snapshot.connectionState != ConnectionState.done) {
                return const Center(child: Text('Opening your archive...'));
              }

              final archive = snapshot.data ?? const ThinkingArchive.empty();
              if (archive.entries.isEmpty) {
                return _EmptyArchive(onReturn: _returnToRitual);
              }

              return _ArchiveContent(
                archive: archive,
                selectedTheme: _selectedTheme,
                referenceDate: widget.referenceDate ?? DateTime.now(),
                onThemeSelected: (theme) {
                  setState(() {
                    _selectedTheme = theme == _selectedTheme ? null : theme;
                  });
                },
              );
            },
          ),
        ),
      ),
    );
  }

  void _returnToRitual() {
    final callback = widget.onReturnToRitual;
    if (callback != null) {
      callback();
      return;
    }
    Navigator.of(context).maybePop();
  }
}

class _ArchiveContent extends StatelessWidget {
  final ThinkingArchive archive;
  final String? selectedTheme;
  final DateTime referenceDate;
  final ValueChanged<String> onThemeSelected;

  const _ArchiveContent({
    required this.archive,
    required this.selectedTheme,
    required this.referenceDate,
    required this.onThemeSelected,
  });

  @override
  Widget build(BuildContext context) {
    final recentEntries = archive.entries
        .where((entry) => selectedTheme == null || entry.theme == selectedTheme)
        .toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 40),
      children: [
        _ArchiveOverview(archive: archive),
        const SizedBox(height: 30),
        const _SectionLabel(
          eyebrow: 'THEMES',
          title: 'Follow the threads in your thinking',
        ),
        const SizedBox(height: 14),
        Wrap(
          spacing: 9,
          runSpacing: 9,
          children: archive.themes
              .map(
                (theme) => FilterChip(
                  label: Text(theme),
                  selected: selectedTheme == theme,
                  onSelected: (_) => onThemeSelected(theme),
                  selectedColor: SivraColors.bronze.withValues(alpha: 0.2),
                  backgroundColor: SivraColors.surface.withValues(alpha: 0.62),
                  side: BorderSide(
                    color: SivraColors.bronze.withValues(alpha: 0.18),
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              )
              .toList(),
        ),
        const SizedBox(height: 32),
        const _SectionLabel(
          eyebrow: 'RECENT INSIGHTS',
          title: 'Ideas you chose to keep',
        ),
        const SizedBox(height: 14),
        ...recentEntries.map(
          (entry) => Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: _InsightCard(entry: entry, referenceDate: referenceDate),
          ),
        ),
        const SizedBox(height: 18),
        const _SectionLabel(
          eyebrow: 'REDISCOVER',
          title: 'Revisit This Insight',
        ),
        const SizedBox(height: 14),
        _RevisitCard(entry: archive.revisitEntry!),
        const SizedBox(height: 32),
        const _SectionLabel(
          eyebrow: 'RECURRING THREAD',
          title: 'Strongest Theme',
        ),
        const SizedBox(height: 14),
        _StrongestThemeCard(theme: archive.strongestTheme!),
      ],
    );
  }
}

class _ArchiveOverview extends StatelessWidget {
  final ThinkingArchive archive;

  const _ArchiveOverview({required this.archive});

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
            'YOUR BODY OF THINKING',
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: SivraColors.bronze,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.4,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Thinking Archive',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              color: SivraColors.warmIvory,
              fontWeight: FontWeight.w600,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'A record of the ideas, insights, and decisions captured through your rituals.',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: SivraColors.mutedText,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 22),
          Container(
            height: 1,
            color: SivraColors.bronze.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: _ArchiveCount(
                  value: '${archive.entries.length}',
                  label: archive.entries.length == 1 ? 'Insight' : 'Insights',
                ),
              ),
              Container(
                width: 1,
                height: 42,
                color: SivraColors.bronze.withValues(alpha: 0.24),
              ),
              Expanded(
                child: _ArchiveCount(
                  value: '${archive.completedRitualCount}',
                  label: archive.completedRitualCount == 1
                      ? 'Ritual'
                      : 'Rituals',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ArchiveCount extends StatelessWidget {
  final String value;
  final String label;

  const _ArchiveCount({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            color: SivraColors.warmIvory,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          label,
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: SivraColors.mutedText),
        ),
      ],
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
          ),
        ),
      ],
    );
  }
}

class _InsightCard extends StatelessWidget {
  final ArchiveEntry entry;
  final DateTime referenceDate;

  const _InsightCard({required this.entry, required this.referenceDate});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(19),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            SivraColors.surfaceSoft.withValues(alpha: 0.93),
            SivraColors.surface.withValues(alpha: 0.78),
          ],
        ),
        border: Border.all(color: SivraColors.bronze.withValues(alpha: 0.17)),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.24),
            blurRadius: 26,
            spreadRadius: -14,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            entry.theme,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: SivraColors.bronze,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.6,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            '“${entry.text}”',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: SivraColors.warmIvory,
              fontWeight: FontWeight.w500,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            _capturedLabel(entry.createdAt, referenceDate),
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: SivraColors.mutedText),
          ),
        ],
      ),
    );
  }

  static String _capturedLabel(DateTime createdAt, DateTime referenceDate) {
    final captured = DateTime(createdAt.year, createdAt.month, createdAt.day);
    final reference = DateTime(
      referenceDate.year,
      referenceDate.month,
      referenceDate.day,
    );
    final days = reference.difference(captured).inDays;
    if (days <= 0) {
      return 'Captured today';
    }
    if (days == 1) {
      return 'Captured yesterday';
    }
    return 'Captured $days days ago';
  }
}

class _RevisitCard extends StatelessWidget {
  final ArchiveEntry entry;

  const _RevisitCard({required this.entry});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(22, 22, 22, 21),
      decoration: BoxDecoration(
        color: SivraColors.bronze.withValues(alpha: 0.09),
        border: Border.all(color: SivraColors.bronze.withValues(alpha: 0.26)),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.auto_stories_outlined,
            color: SivraColors.bronze,
            size: 25,
          ),
          const SizedBox(height: 13),
          Text(
            '“${entry.text}”',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: SivraColors.warmIvory,
              fontWeight: FontWeight.w500,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'Ideas become valuable when revisited.',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: SivraColors.mutedText),
          ),
        ],
      ),
    );
  }
}

class _StrongestThemeCard extends StatelessWidget {
  final String theme;

  const _StrongestThemeCard({required this.theme});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: SivraColors.surface.withValues(alpha: 0.62),
        border: Border.all(color: SivraColors.bronze.withValues(alpha: 0.14)),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            theme,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: SivraColors.warmIvory,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'This theme appeared most often in your recent rituals.',
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

class _EmptyArchive extends StatelessWidget {
  final VoidCallback onReturn;

  const _EmptyArchive({required this.onReturn});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 40),
      children: [
        Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: SivraColors.surface.withValues(alpha: 0.68),
            border: Border.all(
              color: SivraColors.bronze.withValues(alpha: 0.16),
            ),
            borderRadius: BorderRadius.circular(22),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Your archive is empty.',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: SivraColors.warmIvory,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Complete rituals and capture insights to begin building your thinking archive.',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: SivraColors.mutedText,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 22),
              FilledButton(
                onPressed: onReturn,
                style: FilledButton.styleFrom(
                  backgroundColor: SivraColors.bronze,
                  foregroundColor: SivraColors.deepInk,
                ),
                child: const Text('Return to Today’s Ritual'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
