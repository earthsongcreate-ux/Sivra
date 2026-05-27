import 'package:flutter/material.dart';

import '../models/daily_pack.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import 'drill_flow_screen.dart';
import 'learning_memory_screen.dart';

class HistoryScreen extends StatefulWidget {
  final String? uid;
  final List<DailyPack>? previewPacks;

  const HistoryScreen({super.key, this.uid, this.previewPacks});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
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

    return FirestoreService.instance.getRecentDailyPacks(uid: uid);
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
      appBar: AppBar(title: const Text('History')),
      body: SafeArea(
        child: FutureBuilder<List<DailyPack>>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Center(child: Text('Loading history...'));
            }

            final packs = snapshot.data ?? const <DailyPack>[];
            if (packs.isEmpty) {
              return const _EmptyHistory();
            }

            return RefreshIndicator(
              onRefresh: _refresh,
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
                itemCount: packs.length,
                separatorBuilder: (context, index) =>
                    const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final pack = packs[index];
                  return _HistoryPackTile(pack: pack);
                },
              ),
            );
          },
        ),
      ),
    );
  }
}

class _EmptyHistory extends StatelessWidget {
  const _EmptyHistory();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'No history yet',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            'Completed packs and saved answers will appear here.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}

class _HistoryPackTile extends StatelessWidget {
  final DailyPack pack;

  const _HistoryPackTile({required this.pack});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final completedLabel = pack.isCompleted ? 'Done' : 'Open';

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
                Text(completedLabel),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              '${pack.completedItemCount}/${pack.items.length} screens • ${pack.writtenAnswerCount} answers',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: colors.onSurface.withValues(alpha: 0.72),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.of(context).push<void>(
                        MaterialPageRoute(
                          builder: (context) =>
                              LearningMemoryScreen(pack: pack),
                        ),
                      );
                    },
                    child: const Text('Review'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton(
                    onPressed: () {
                      Navigator.of(context).push<void>(
                        MaterialPageRoute(
                          builder: (context) => DrillFlowScreen(
                            items: pack.items,
                            dayId: pack.dayId,
                          ),
                        ),
                      );
                    },
                    child: const Text('Practice'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
