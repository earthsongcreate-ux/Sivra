import 'package:flutter/material.dart';

import '../services/firestore_service.dart';
import 'today_screen.dart';

class OnboardingScreen extends StatefulWidget {
  final String uid;
  final VoidCallback onCompleted;

  const OnboardingScreen({
    super.key,
    required this.uid,
    required this.onCompleted,
  });

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final Set<String> _selected = {};
  bool _saving = false;

  static const _options = <String>[
    'Product strategy',
    'GTM & sales',
    'Hiring & team',
    'Infra & costs',
  ];

  bool get _canContinue => _selected.isNotEmpty && _selected.length <= 3;

  Future<void> _continue() async {
    if (!_canContinue || _saving) {
      return;
    }

    setState(() {
      _saving = true;
    });

    try {
      await FirestoreService.instance.upsertProfile(
        uid: widget.uid,
        focusAreas: _selected.toList(),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _saving = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unable to save your focus. Please try again.'),
        ),
      );
      return;
    }

    if (!mounted) {
      return;
    }

    widget.onCompleted();

    Navigator.of(context).pushReplacementNamed(TodayScreen.routeName);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sivra')),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Choose your focus',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              'Pick up to 3. This shapes your daily pack.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.72),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.separated(
                itemCount: _options.length,
                separatorBuilder: (context, index) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final option = _options[index];
                  final selected = _selected.contains(option);
                  final disabled = !selected && _selected.length >= 3;

                  return Opacity(
                    opacity: disabled ? 0.5 : 1,
                    child: ListTile(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(
                          color: Theme.of(
                            context,
                          ).dividerColor.withValues(alpha: 0.35),
                        ),
                      ),
                      title: Text(option),
                      trailing: Checkbox(
                        value: selected,
                        onChanged: disabled || _saving
                            ? null
                            : (value) {
                                setState(() {
                                  if (value ?? false) {
                                    _selected.add(option);
                                  } else {
                                    _selected.remove(option);
                                  }
                                });
                              },
                      ),
                      onTap: disabled || _saving
                          ? null
                          : () {
                              setState(() {
                                if (selected) {
                                  _selected.remove(option);
                                } else {
                                  _selected.add(option);
                                }
                              });
                            },
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _canContinue && !_saving ? _continue : null,
                child: _saving ? const Text('Saving…') : const Text('Continue'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
