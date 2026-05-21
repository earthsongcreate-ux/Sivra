import 'package:flutter/material.dart';

import 'today_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final Set<String> _selected = {};

  static const _options = <String>[
    'Product',
    'GTM',
    'Hiring',
    'Infra/Costs',
  ];

  bool get _canContinue => _selected.isNotEmpty && _selected.length <= 3;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sivra'),
      ),
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
              'Pick up to 3. This shapes your daily brief.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.72),
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
                          color: Theme.of(context).dividerColor.withOpacity(0.35),
                        ),
                      ),
                      title: Text(option),
                      trailing: Checkbox(
                        value: selected,
                        onChanged: disabled
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
                      onTap: disabled
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
                onPressed: _canContinue
                    ? () {
                        Navigator.of(context).pushReplacementNamed(
                          TodayScreen.routeName,
                        );
                      }
                    : null,
                child: const Text('Continue'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

