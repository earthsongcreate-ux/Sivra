import 'package:flutter/material.dart';

import '../models/daily_pack.dart';
import '../models/drill_item.dart';

class LearningMemoryScreen extends StatelessWidget {
  final DailyPack pack;

  const LearningMemoryScreen({super.key, required this.pack});

  @override
  Widget build(BuildContext context) {
    final answerItems = pack.items
        .where((item) => pack.answersByItemId.containsKey(item.id))
        .toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Learning Memory')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
          children: [
            Text(
              'Today’s learning',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              '${pack.completedItemCount}/${pack.items.length} screens completed',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.72),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Written answers',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 10),
            if (answerItems.isEmpty)
              Text(
                'No written answers saved yet.',
                style: Theme.of(context).textTheme.bodyMedium,
              )
            else
              ...answerItems.map(
                (item) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _AnswerCard(
                    item: item,
                    answer: pack.answersByItemId[item.id]!,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _AnswerCard extends StatelessWidget {
  final DrillItem item;
  final String answer;

  const _AnswerCard({required this.item, required this.answer});

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
            Text(item.prompt, style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            Text(answer),
          ],
        ),
      ),
    );
  }
}
