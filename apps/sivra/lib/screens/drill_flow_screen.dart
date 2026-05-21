import 'package:flutter/material.dart';

import '../data/mock_daily_pack.dart';
import '../models/drill_item.dart';
import 'source_sheet.dart';

class DrillFlowScreen extends StatefulWidget {
  const DrillFlowScreen({super.key});

  @override
  State<DrillFlowScreen> createState() => _DrillFlowScreenState();
}

class _DrillFlowScreenState extends State<DrillFlowScreen> {
  final _items = MockDailyPack.items;
  int _index = 0;
  bool _revealed = false;
  final _articulationController = TextEditingController();

  @override
  void dispose() {
    _articulationController.dispose();
    super.dispose();
  }

  DrillItem get _current => _items[_index];

  void _next() {
    if (_index >= _items.length - 1) {
      Navigator.of(context).pop();
      return;
    }

    setState(() {
      _index += 1;
      _revealed = false;
      if (_current.type != DrillItemType.articulation) {
        _articulationController.clear();
      }
    });
  }

  void _reveal() {
    setState(() {
      _revealed = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final progressLabel = '${_index + 1}/${_items.length}';

    return Scaffold(
      appBar: AppBar(
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
                      builder: (context) => SourceSheet(source: _current.source!),
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
            Expanded(
              child: _buildBody(context, _current),
            ),
            const SizedBox(height: 12),
            _buildFooter(context, _current),
          ],
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
              maxLines: null,
              expands: true,
              textInputAction: TextInputAction.newline,
              decoration: const InputDecoration(
                hintText: 'Type your answer…',
                border: OutlineInputBorder(),
              ),
            ),
          ),
          if (_revealed && (item.explanation?.isNotEmpty ?? false)) ...[
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
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.72),
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
              'Answer',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              item.answer!,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
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
      return Row(
        children: [
          Expanded(
            child: FilledButton(
              onPressed: _revealed ? _next : _reveal,
              child: Text(_revealed ? (isLast ? 'Finish' : 'Next') : 'Continue'),
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

