import 'package:flutter/material.dart';

import '../models/daily_pack.dart';
import '../models/source_audit.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import 'content_qa_screen.dart';

class SourceTrustAdminScreen extends StatefulWidget {
  final String? uid;
  final List<DailyPack>? previewPacks;

  const SourceTrustAdminScreen({super.key, this.uid, this.previewPacks});

  @override
  State<SourceTrustAdminScreen> createState() => _SourceTrustAdminScreenState();
}

class _SourceTrustAdminScreenState extends State<SourceTrustAdminScreen> {
  late Future<List<DailyPack>> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<DailyPack>> _load() async {
    final previewPacks = widget.previewPacks;
    if (previewPacks != null) {
      return previewPacks;
    }

    final uid = widget.uid ?? AuthService.instance.currentUser?.uid;
    if (uid == null) {
      return const <DailyPack>[];
    }

    return FirestoreService.instance.getRecentDailyPacks(uid: uid, limit: 30);
  }

  Future<void> _refresh() async {
    setState(() {
      _future = _load();
    });
    await _future;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Source Admin')),
      body: SafeArea(
        child: FutureBuilder<List<DailyPack>>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Center(child: Text('Loading source review...'));
            }

            final packs = snapshot.data ?? const <DailyPack>[];
            if (packs.isEmpty) {
              return const _EmptyAdmin();
            }

            final audit = SourceAudit.fromPacks(packs);

            return RefreshIndicator(
              onRefresh: _refresh,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
                children: [
                  Text(
                    'Trust overview',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _AdminMetric(
                          label: 'Sources',
                          value:
                              '${audit.trustedSourceCount}/${audit.sourceCount}',
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _AdminMetric(
                          label: 'Fallbacks',
                          value: '${audit.fallbackPackCount}',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _AdminMetric(
                          label: 'Issues',
                          value: '${audit.issueCount}',
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _AdminMetric(
                          label: 'Warnings',
                          value: '${audit.warningCount}',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Text('Hosts', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: audit.hostCounts.entries
                        .map(
                          (entry) => Chip(
                            label: Text('${entry.key} · ${entry.value}'),
                          ),
                        )
                        .toList(),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Recent packs',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 10),
                  ...packs.map(
                    (pack) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _AdminPackTile(pack: pack),
                    ),
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

class _EmptyAdmin extends StatelessWidget {
  const _EmptyAdmin();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'No packs to review',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            'Generated packs will appear here for source trust review.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}

class _AdminMetric extends StatelessWidget {
  final String label;
  final String value;

  const _AdminMetric({required this.label, required this.value});

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

class _AdminPackTile extends StatelessWidget {
  final DailyPack pack;

  const _AdminPackTile({required this.pack});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final qa = pack.qaReport;
    final issueCount = qa?.issues.length ?? 0;
    final warningCount = qa?.warnings.length ?? 0;

    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border.all(color: colors.onSurface.withValues(alpha: 0.14)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    pack.dayId,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                Text(qa?.status ?? 'not checked'),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              '${pack.generator} • $issueCount issues • $warningCount warnings',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: colors.onSurface.withValues(alpha: 0.72),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () {
                  Navigator.of(context).push<void>(
                    MaterialPageRoute(
                      builder: (context) => ContentQaScreen(pack: pack),
                    ),
                  );
                },
                child: const Text('Open QA'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
