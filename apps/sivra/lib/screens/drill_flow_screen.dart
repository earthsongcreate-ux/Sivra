import 'dart:async';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../data/mock_daily_pack.dart';
import '../models/drill_item.dart';
import '../services/firestore_service.dart';
import '../utils/day_id.dart';
import 'source_sheet.dart';

class DrillFlowScreen extends StatefulWidget {
  final List<DrillItem>? items;
  final String? dayId;
  final String? uid;
  final int initialIndex;
  final String initialArticulationAnswer;
  final void Function(
    List<String> completedItemIds,
    Map<String, String> answersByItemId,
  )?
  onCompleted;

  const DrillFlowScreen({
    super.key,
    this.items,
    this.dayId,
    this.uid,
    this.initialIndex = 0,
    this.initialArticulationAnswer = '',
    this.onCompleted,
  });

  @override
  State<DrillFlowScreen> createState() => _DrillFlowScreenState();
}

class _DrillFlowScreenState extends State<DrillFlowScreen> {
  late final List<DrillItem> _items;
  int _index = 0;
  bool _revealed = false;
  final Set<String> _completedItemIds = <String>{};
  final Map<String, String> _answersByItemId = <String, String>{};
  final _articulationController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _items = widget.items ?? MockDailyPack.items;
    _index = widget.initialIndex.clamp(0, _items.length - 1);
    _articulationController.text = widget.initialArticulationAnswer;
  }

  @override
  void dispose() {
    _articulationController.dispose();
    super.dispose();
  }

  DrillItem get _current => _items[_index];

  void _goBack() {
    if (_index == 0) {
      Navigator.of(context).pop();
      return;
    }

    setState(() {
      _index -= 1;
      _revealed = _current.type != DrillItemType.articulation;
    });
  }

  void _next() {
    _saveCurrentProgress();

    if (_index >= _items.length - 1) {
      _finish();
      return;
    }

    setState(() {
      _index += 1;
      _revealed = _current.type == DrillItemType.review;
    });
  }

  void _finish() {
    String? currentUid;
    try {
      currentUid = FirebaseAuth.instance.currentUser?.uid;
    } catch (_) {
      currentUid = null;
    }
    final uid = widget.uid ?? currentUid;

    widget.onCompleted?.call(
      _completedItemIds.toList(),
      Map<String, String>.from(_answersByItemId),
    );
    if (mounted) {
      Navigator.of(context).pop();
    }

    if (uid == null) {
      return;
    }

    unawaited(
      FirestoreService.instance
          .markDailyCompleted(
            uid: uid,
            dayId: widget.dayId ?? dayIdFromDate(DateTime.now()),
            itemCount: _items.length,
          )
          .then(
            (_) => FirestoreService.instance.logEvent(
              uid: uid,
              name: 'daily_pack_completed',
              properties: <String, dynamic>{
                'dayId': widget.dayId ?? dayIdFromDate(DateTime.now()),
                'itemCount': _items.length,
              },
            ),
          )
          .catchError((_) {}),
    );
  }

  void _saveCurrentProgress() {
    final item = _current;
    final answer = item.type == DrillItemType.articulation
        ? _articulationController.text
        : null;
    final trimmedAnswer = answer?.trim();

    _completedItemIds.add(item.id);
    if (trimmedAnswer != null && trimmedAnswer.isNotEmpty) {
      _answersByItemId[item.id] = trimmedAnswer;
    }

    String? currentUid;
    try {
      currentUid = FirebaseAuth.instance.currentUser?.uid;
    } catch (_) {
      currentUid = null;
    }
    final uid = widget.uid ?? currentUid;
    if (uid == null) {
      return;
    }

    unawaited(
      FirestoreService.instance
          .markDailyItemCompleted(
            uid: uid,
            dayId: widget.dayId ?? dayIdFromDate(DateTime.now()),
            itemId: item.id,
            answer: answer,
          )
          .catchError((_) {}),
    );
  }

  void _reveal() {
    setState(() {
      _revealed = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final progressLabel = '${_index + 1}/${_items.length}';

    return PopScope(
      canPop: _index == 0,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          _goBack();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: _goBack,
          ),
          title: const Text('Daily Pack'),
          actions: [
            Center(
              child: Padding(
                padding: const EdgeInsets.only(right: 16),
                child: Text(
                  progressLabel,
                  style: Theme.of(context).textTheme.labelLarge,
                ),
              ),
            ),
          ],
        ),
        body: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_current.hasSource)
                Align(
                  alignment: Alignment.centerLeft,
                  child: ActionChip(
                    label: const Text('Source'),
                    onPressed: () {
                      showModalBottomSheet<void>(
                        context: context,
                        showDragHandle: true,
                        builder: (context) =>
                            SourceSheet(source: _current.source!),
                      );
                    },
                  ),
                ),
              const SizedBox(height: 12),
              Text(
                _current.prompt,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 16),
              Expanded(child: _buildBody(context, _current)),
              const SizedBox(height: 12),
              _buildFooter(context, _current),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context, DrillItem item) {
    if (item.type == DrillItemType.articulation) {
      return Column(
        children: [
          Expanded(
            child: TextField(
              controller: _articulationController,
              onChanged: (_) {
                setState(() {});
              },
              maxLines: null,
              expands: true,
              textInputAction: TextInputAction.newline,
              decoration: const InputDecoration(
                hintText: 'Type your answer…',
                border: OutlineInputBorder(),
              ),
            ),
          ),
          if (item.explanation?.isNotEmpty ?? false) ...[
            const SizedBox(height: 12),
            Text(
              item.explanation!,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ],
      );
    }

    if (!_revealed) {
      return Center(
        child: Text(
          'Think first. Then reveal.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(
              context,
            ).colorScheme.onSurface.withValues(alpha: 0.72),
          ),
        ),
      );
    }

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (item.answer != null) ...[
            Text('Answer', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(item.answer!, style: Theme.of(context).textTheme.bodyLarge),
          ],
          if (item.explanation != null) ...[
            const SizedBox(height: 16),
            Text(
              'Why it matters',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              item.explanation!,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFooter(BuildContext context, DrillItem item) {
    final isLast = _index >= _items.length - 1;

    if (item.type == DrillItemType.articulation) {
      final canContinue = _articulationController.text.trim().isNotEmpty;
      return Row(
        children: [
          Expanded(
            child: FilledButton(
              onPressed: canContinue ? _next : null,
              child: Text(isLast ? 'Finish' : 'Next'),
            ),
          ),
        ],
      );
    }

    return Row(
      children: [
        Expanded(
          child: FilledButton(
            onPressed: _revealed ? _next : _reveal,
            child: Text(_revealed ? (isLast ? 'Finish' : 'Next') : 'Reveal'),
          ),
        ),
      ],
    );
  }
}
