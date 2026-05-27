import 'package:flutter/material.dart';

import '../models/daily_pack.dart';
import '../services/source_trust_policy.dart';

class ContentQaScreen extends StatelessWidget {
  final DailyPack pack;

  const ContentQaScreen({super.key, required this.pack});

  @override
  Widget build(BuildContext context) {
    final qa = pack.qaReport;
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final issues = qa?.issues ?? const <String>[];
    final warnings = qa?.warnings ?? const <String>[];

    return Scaffold(
      appBar: AppBar(title: const Text('Content QA')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
          children: [
            Text('Pack review', style: textTheme.headlineSmall),
            const SizedBox(height: 8),
            Text(
              '${pack.dayId} • ${pack.generator}',
              style: textTheme.bodyMedium?.copyWith(
                color: colors.onSurface.withValues(alpha: 0.72),
              ),
            ),
            const SizedBox(height: 20),
            _QaSummary(
              label: qa?.status ?? 'not_checked',
              score: qa?.score ?? 0,
            ),
            const SizedBox(height: 20),
            _SectionList(
              title: 'Issues',
              emptyText: 'No blocking issues.',
              items: issues,
            ),
            const SizedBox(height: 20),
            _SectionList(
              title: 'Warnings',
              emptyText: 'No warnings.',
              items: warnings,
            ),
            const SizedBox(height: 20),
            Text('Sources', style: textTheme.titleMedium),
            const SizedBox(height: 8),
            ...pack.items
                .where((item) => item.source != null)
                .map(
                  (item) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _SourceRow(
                      title: item.source!.title,
                      publisher: item.source!.publisher,
                      url: item.source!.url,
                      trust: const SourceTrustPolicy().evaluate(item.source!),
                    ),
                  ),
                ),
          ],
        ),
      ),
    );
  }
}

class _QaSummary extends StatelessWidget {
  final String label;
  final int score;

  const _QaSummary({required this.label, required this.score});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border.all(color: colors.onSurface.withValues(alpha: 0.18)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label.replaceAll('_', ' '),
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            Text('$score', style: Theme.of(context).textTheme.headlineSmall),
          ],
        ),
      ),
    );
  }
}

class _SectionList extends StatelessWidget {
  final String title;
  final String emptyText;
  final List<String> items;

  const _SectionList({
    required this.title,
    required this.emptyText,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        if (items.isEmpty)
          Text(
            emptyText,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: colors.onSurface.withValues(alpha: 0.72),
            ),
          )
        else
          ...items.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(item),
            ),
          ),
      ],
    );
  }
}

class _SourceRow extends StatelessWidget {
  final String title;
  final String publisher;
  final String url;
  final SourceTrustResult trust;

  const _SourceRow({
    required this.title,
    required this.publisher,
    required this.url,
    required this.trust,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final host = Uri.tryParse(url)?.host.replaceFirst(RegExp(r'^www\.'), '');

    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border.all(color: colors.onSurface.withValues(alpha: 0.14)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 4),
            Text(
              host == null || host.isEmpty ? publisher : '$publisher • $host',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: colors.onSurface.withValues(alpha: 0.72),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              trust.isTrusted
                  ? 'Trusted source'
                  : '${trust.issues.length} issue(s)',
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: trust.isTrusted ? colors.primary : colors.error,
              ),
            ),
            if (trust.warnings.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                '${trust.warnings.length} warning(s)',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: colors.onSurface.withValues(alpha: 0.72),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
