import 'package:flutter/material.dart';

import '../models/daily_pack.dart';
import '../models/weekly_recap.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';

class WeeklyRecapScreen extends StatefulWidget {
  final String? uid;
  final List<DailyPack>? previewPacks;

  const WeeklyRecapScreen({super.key, this.uid, this.previewPacks});

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
      return WeeklyRecap.fromPacks(previewPacks);
    }

    final uid = widget.uid ?? AuthService.instance.currentUser?.uid;
    if (uid == null) {
      return const WeeklyRecap(
        packCount: 0,
        completedPackCount: 0,
        completedScreenCount: 0,
        writtenAnswerCount: 0,
        focusAreas: <String>[],
        guidance: 'Complete more packs to unlock stronger personalization.',
      );
    }

    final packs = await FirestoreService.instance.getRecentDailyPacks(
      uid: uid,
      limit: 7,
    );
    return WeeklyRecap.fromPacks(packs);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Weekly Recap')),
      body: SafeArea(
        child: FutureBuilder<WeeklyRecap>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Center(child: Text('Loading recap...'));
            }

            final recap = snapshot.data;
            if (recap == null || recap.packCount == 0) {
              return const _EmptyRecap();
            }

            return Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'This week',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: _RecapMetric(
                          label: 'Packs',
                          value:
                              '${recap.completedPackCount}/${recap.packCount}',
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _RecapMetric(
                          label: 'Screens',
                          value: '${recap.completedScreenCount}',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _RecapMetric(
                          label: 'Answers',
                          value: '${recap.writtenAnswerCount}',
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _RecapMetric(
                          label: 'Focus',
                          value: '${recap.focusAreas.length}',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Personalization',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(recap.guidance),
                  const SizedBox(height: 20),
                  Text(
                    'Focus areas',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: recap.focusAreas
                        .map((focus) => Chip(label: Text(focus)))
                        .toList(),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _EmptyRecap extends StatelessWidget {
  const _EmptyRecap();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'No recap yet',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            'Complete packs this week to build your recap.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}

class _RecapMetric extends StatelessWidget {
  final String label;
  final String value;

  const _RecapMetric({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

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
            Text(value, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 4),
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: colors.onSurface.withValues(alpha: 0.72),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
