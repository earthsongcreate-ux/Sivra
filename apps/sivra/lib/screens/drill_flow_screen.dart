import 'dart:async';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../data/mock_daily_pack.dart';
import '../design/sivra_colors.dart';
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
  bool _exitApproved = false;
  final Set<String> _completedItemIds = <String>{};
  final Map<String, String> _answersByItemId = <String, String>{};
  final _articulationController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _items = widget.items ?? MockDailyPack.items;
    _index = widget.initialIndex.clamp(0, _items.length - 1);
    _revealed = _current.type == DrillItemType.review;
    _articulationController.text = widget.initialArticulationAnswer;
  }

  @override
  void dispose() {
    _articulationController.dispose();
    super.dispose();
  }

  DrillItem get _current => _items[_index];

  bool get _hasInProgressState =>
      _index > 0 ||
      _completedItemIds.isNotEmpty ||
      _revealed ||
      _articulationController.text.trim().isNotEmpty;

  void _previous() {
    if (_index == 0) {
      return;
    }
    setState(() {
      _index -= 1;
      _revealed =
          _completedItemIds.contains(_current.id) ||
          _current.type == DrillItemType.review;
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
      _revealed =
          _completedItemIds.contains(_current.id) ||
          _current.type == DrillItemType.review;
    });
  }

  Future<void> _requestExit() async {
    if (_exitApproved) {
      return;
    }

    var shouldLeave = true;
    if (_hasInProgressState) {
      shouldLeave =
          await showDialog<bool>(
            context: context,
            builder: (dialogContext) => AlertDialog(
              title: const Text('Leave this drill?'),
              content: const Text('Your progress will be saved.'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(false),
                  child: const Text('Continue Drill'),
                ),
                FilledButton(
                  onPressed: () => Navigator.of(dialogContext).pop(true),
                  child: const Text('Leave'),
                ),
              ],
            ),
          ) ??
          false;
    }

    if (!shouldLeave || !mounted) {
      return;
    }

    setState(() {
      _exitApproved = true;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        Navigator.of(context).pop();
      }
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
    return PopScope(
      canPop: _exitApproved,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          unawaited(_requestExit());
        }
      },
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          leadingWidth: 96,
          leading: TextButton.icon(
            onPressed: _requestExit,
            icon: const Icon(Icons.arrow_back),
            label: const Text('Back'),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
          title: const Text('Today’s Ritual'),
        ),
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
              stops: [0, 0.58, 1],
            ),
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxHeight < 540;
              final verticalPadding = compact ? 12.0 : 20.0;
              final contentGap = compact ? 8.0 : 12.0;

              return Padding(
                padding: EdgeInsets.fromLTRB(
                  20,
                  verticalPadding,
                  20,
                  compact ? 12 : 24,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_current.hasSource)
                      Align(
                        alignment: Alignment.centerLeft,
                        child: ActionChip(
                          label: const Text('Source Context'),
                          side: BorderSide(
                            color: SivraColors.bronze.withValues(alpha: 0.38),
                          ),
                          backgroundColor: SivraColors.surface.withValues(
                            alpha: 0.56,
                          ),
                          onPressed: () {
                            showModalBottomSheet<void>(
                              context: context,
                              showDragHandle: true,
                              backgroundColor: SivraColors.deepInk,
                              builder: (context) =>
                                  SourceSheet(source: _current.source!),
                            );
                          },
                        ),
                      ),
                    SizedBox(height: contentGap),
                    Text(
                      _current.prompt,
                      style:
                          (compact
                                  ? Theme.of(context).textTheme.titleLarge
                                  : Theme.of(context).textTheme.headlineSmall)
                              ?.copyWith(
                                fontWeight: FontWeight.w600,
                                letterSpacing: -0.3,
                              ),
                    ),
                    SizedBox(height: compact ? 10 : 16),
                    Expanded(child: _buildBody(context, _current)),
                    SizedBox(height: contentGap),
                    _buildFooter(context, _current),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context, DrillItem item) {
    if (item.type == DrillItemType.articulation) {
      return LayoutBuilder(
        builder: (context, constraints) {
          final hasPrefilledAnswer = widget.initialArticulationAnswer
              .trim()
              .isNotEmpty;
          final answerSurface = _buildArticulationSurface();

          return Column(
            children: [
              if (hasPrefilledAnswer)
                SizedBox(
                  height: constraints.maxHeight * 0.72,
                  child: answerSurface,
                )
              else
                Expanded(child: answerSurface),
              if (item.explanation?.isNotEmpty ?? false) ...[
                const SizedBox(height: 12),
                Text(
                  item.explanation!,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ],
          );
        },
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
            Text(
              'ANSWER',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: SivraColors.bronze,
                fontWeight: FontWeight.w600,
                letterSpacing: 1.2,
              ),
            ),
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

  Widget _buildArticulationSurface() {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            SivraColors.surface.withValues(alpha: 0.76),
            SivraColors.surfaceSoft.withValues(alpha: 0.58),
            SivraColors.ritualGradientBottom.withValues(alpha: 0.72),
          ],
        ),
        border: Border.all(color: SivraColors.bronze.withValues(alpha: 0.22)),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.28),
            blurRadius: 28,
            spreadRadius: -12,
            offset: const Offset(0, 18),
          ),
        ],
      ),
      child: TextField(
        controller: _articulationController,
        onChanged: (_) {
          setState(() {});
        },
        maxLines: null,
        expands: true,
        textInputAction: TextInputAction.newline,
        decoration: InputDecoration(
          hintText: 'Type your answer…',
          filled: true,
          fillColor: Colors.transparent,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: BorderSide(
              color: SivraColors.bronze.withValues(alpha: 0.44),
            ),
          ),
          contentPadding: const EdgeInsets.all(16),
        ),
      ),
    );
  }

  Widget _buildFooter(BuildContext context, DrillItem item) {
    final isLast = _index >= _items.length - 1;
    final canMoveForward = item.type == DrillItemType.articulation
        ? _articulationController.text.trim().isNotEmpty
        : _revealed;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (item.type != DrillItemType.articulation && !_revealed) ...[
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _reveal,
              child: const Text('Reveal'),
            ),
          ),
          const SizedBox(height: 12),
        ],
        Row(
          children: [
            Expanded(
              flex: 2,
              child: TextButton.icon(
                key: const ValueKey('previous-question'),
                onPressed: _index == 0 ? null : _previous,
                icon: const Icon(Icons.chevron_left),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                ),
                label: const Text('Previous'),
              ),
            ),
            Expanded(
              flex: 3,
              child: Text(
                'Question ${_index + 1} of ${_items.length}',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.labelLarge,
              ),
            ),
            Expanded(
              flex: 2,
              child: TextButton(
                key: const ValueKey('next-question'),
                onPressed: canMoveForward ? _next : null,
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                ),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(isLast ? 'Finish' : 'Next'),
                      const Icon(Icons.chevron_right),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _QuestionProgressDots(
          currentIndex: _index,
          questionCount: _items.length,
        ),
      ],
    );
  }
}

class _QuestionProgressDots extends StatelessWidget {
  final int currentIndex;
  final int questionCount;

  const _QuestionProgressDots({
    required this.currentIndex,
    required this.questionCount,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Semantics(
      label: 'Question ${currentIndex + 1} of $questionCount',
      child: Wrap(
        alignment: WrapAlignment.center,
        spacing: 8,
        runSpacing: 8,
        children: List<Widget>.generate(questionCount, (index) {
          final isReached = index <= currentIndex;
          return AnimatedContainer(
            key: ValueKey('question-progress-dot-$index'),
            duration: const Duration(milliseconds: 180),
            width: 9,
            height: 9,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isReached ? colors.primary : Colors.transparent,
              border: Border.all(
                color: isReached
                    ? colors.primary
                    : colors.onSurface.withValues(alpha: 0.42),
              ),
            ),
          );
        }),
      ),
    );
  }
}
