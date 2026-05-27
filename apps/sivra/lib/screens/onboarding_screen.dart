import 'dart:async';

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
  static const _focusOptions = <String>[
    'Product strategy',
    'GTM & sales',
    'Hiring & team',
    'Infra & costs',
  ];

  static const _levelOptions = <_OnboardingOption>[
    _OnboardingOption(
      value: 'new',
      title: 'New to AI',
      subtitle: 'I want plain language and useful basics.',
    ),
    _OnboardingOption(
      value: 'experimenting',
      title: 'Experimenting',
      subtitle: 'I have tried tools, but need sharper judgment.',
    ),
    _OnboardingOption(
      value: 'weekly_user',
      title: 'Using AI weekly',
      subtitle: 'I want better patterns and clearer decisions.',
    ),
    _OnboardingOption(
      value: 'leading_adoption',
      title: 'Leading adoption',
      subtitle: 'I need to explain, evaluate, and guide others.',
    ),
    _OnboardingOption(
      value: 'not_sure',
      title: 'Not sure',
      subtitle: 'Start me at a practical baseline.',
    ),
  ];

  static const _obstacleOptions = <_OnboardingOption>[
    _OnboardingOption(
      value: 'too_much_noise',
      title: 'Too much noise',
      subtitle: 'It is hard to know what actually matters.',
    ),
    _OnboardingOption(
      value: 'explaining_to_others',
      title: 'Explaining it clearly',
      subtitle: 'I need simple language for stakeholders.',
    ),
    _OnboardingOption(
      value: 'trust_and_risk',
      title: 'Trust and risk',
      subtitle: 'I want to spot bad outputs before they spread.',
    ),
    _OnboardingOption(
      value: 'finding_use_cases',
      title: 'Finding useful cases',
      subtitle: 'I need sharper ideas for my actual work.',
    ),
    _OnboardingOption(
      value: 'not_sure',
      title: 'Not sure',
      subtitle: 'Help me find the right starting point.',
    ),
  ];

  static const _routineOptions = <_OnboardingOption>[
    _OnboardingOption(
      value: '3_min_daily',
      title: '3 min/day',
      subtitle: 'Tiny daily reps.',
    ),
    _OnboardingOption(
      value: '5_min_daily',
      title: '5 min/day',
      subtitle: 'The recommended pace.',
    ),
    _OnboardingOption(
      value: '10_min_daily',
      title: '10 min/day',
      subtitle: 'Deeper practice.',
    ),
    _OnboardingOption(
      value: '3x_week',
      title: '3x/week',
      subtitle: 'A lighter weekly rhythm.',
    ),
  ];

  final Set<String> _selectedFocus = {};
  int _stepIndex = 0;
  bool _saving = false;
  String? _level;
  String? _obstacle;
  String? _routine = '5_min_daily';

  static const _stepCount = 5;

  bool get _canContinue {
    return switch (_stepIndex) {
      0 => _selectedFocus.isNotEmpty && _selectedFocus.length <= 3,
      1 => _level != null,
      2 => _obstacle != null,
      3 => _routine != null,
      _ => true,
    };
  }

  @override
  void initState() {
    super.initState();
    _logEventSafely(
      name: 'onboarding_started',
      properties: const <String, dynamic>{'version': 2},
    );
  }

  void _back() {
    if (_saving) {
      return;
    }

    if (_stepIndex == 0) {
      return;
    }

    setState(() {
      _stepIndex -= 1;
    });
  }

  Future<void> _continue() async {
    if (!_canContinue || _saving) {
      return;
    }

    _logEventSafely(
      name: 'onboarding_step_completed',
      properties: <String, dynamic>{
        'version': 2,
        'step': _stepIndex + 1,
        'stepId': _stepId,
      },
    );

    if (_stepIndex < _stepCount - 1) {
      setState(() {
        _stepIndex += 1;
      });
      return;
    }

    await _complete();
  }

  Future<void> _complete() async {
    setState(() {
      _saving = true;
    });

    try {
      await FirestoreService.instance.upsertProfile(
        uid: widget.uid,
        focusAreas: _selectedFocus.toList(),
        aiFluencyLevel: _level,
        onboardingObstacle: _obstacle,
        routineTarget: _routine,
      );
      await FirestoreService.instance.logEvent(
        uid: widget.uid,
        name: 'onboarding_completed',
        properties: <String, dynamic>{
          'version': 2,
          'focusAreas': _selectedFocus.toList(),
          'aiFluencyLevel': _level,
          'obstacle': _obstacle,
          'routineTarget': _routine,
        },
      );
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _saving = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unable to save your plan. Please try again.'),
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

  void _logEventSafely({
    required String name,
    required Map<String, dynamic> properties,
  }) {
    try {
      unawaited(
        FirestoreService.instance
            .logEvent(uid: widget.uid, name: name, properties: properties)
            .catchError((_) {}),
      );
    } catch (_) {
      // Onboarding should render even when analytics is unavailable.
    }
  }

  String get _stepId {
    return switch (_stepIndex) {
      0 => 'focus',
      1 => 'level',
      2 => 'obstacle',
      3 => 'routine',
      _ => 'plan_preview',
    };
  }

  String get _continueLabel {
    if (_saving) {
      return 'Saving...';
    }
    return _stepIndex == _stepCount - 1 ? 'Start first pack' : 'Continue';
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final progress = (_stepIndex + 1) / _stepCount;

    return Scaffold(
      appBar: AppBar(
        leading: _stepIndex == 0
            ? null
            : IconButton(
                tooltip: 'Back',
                icon: const Icon(Icons.chevron_left),
                onPressed: _back,
              ),
        title: const Text('Sivra'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 6,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    '${_stepIndex + 1}/$_stepCount',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: colors.onSurface.withValues(alpha: 0.72),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Expanded(child: _buildStep(context)),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _canContinue && !_saving ? _continue : null,
                  child: Text(_continueLabel),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStep(BuildContext context) {
    return switch (_stepIndex) {
      0 => _FocusStep(
        selected: _selectedFocus,
        options: _focusOptions,
        onChanged: _setFocusSelected,
      ),
      1 => _SingleChoiceStep(
        title: 'How fluent are you with AI today?',
        subtitle:
            'This keeps your daily pack useful, not too basic or too advanced.',
        options: _levelOptions,
        value: _level,
        onChanged: (value) => setState(() => _level = value),
      ),
      2 => _SingleChoiceStep(
        title: 'What usually gets in the way?',
        subtitle: 'Sivra will use this to shape your drills and examples.',
        options: _obstacleOptions,
        value: _obstacle,
        onChanged: (value) => setState(() => _obstacle = value),
      ),
      3 => _SingleChoiceStep(
        title: 'What pace feels realistic?',
        subtitle: 'Small reps are enough. You can change this later.',
        options: _routineOptions,
        value: _routine,
        onChanged: (value) => setState(() => _routine = value),
      ),
      _ => _PlanPreviewStep(
        focusAreas: _selectedFocus.toList(),
        level: _labelFor(_levelOptions, _level),
        obstacle: _labelFor(_obstacleOptions, _obstacle),
        routine: _labelFor(_routineOptions, _routine),
      ),
    };
  }

  void _setFocusSelected(String option, bool selected) {
    setState(() {
      if (selected) {
        _selectedFocus.add(option);
      } else {
        _selectedFocus.remove(option);
      }
    });
  }

  String _labelFor(List<_OnboardingOption> options, String? value) {
    for (final option in options) {
      if (option.value == value) {
        return option.title;
      }
    }
    return 'A practical baseline';
  }
}

class _FocusStep extends StatelessWidget {
  final Set<String> selected;
  final List<String> options;
  final void Function(String option, bool selected) onChanged;

  const _FocusStep({
    required this.selected,
    required this.options,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
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
        ...options.map((option) {
          final isSelected = selected.contains(option);
          final disabled = !isSelected && selected.length >= 3;

          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Opacity(
              opacity: disabled ? 0.5 : 1,
              child: _ChoiceTile(
                title: option,
                selected: isSelected,
                trailing: Checkbox(
                  value: isSelected,
                  onChanged: disabled
                      ? null
                      : (value) => onChanged(option, value ?? false),
                ),
                onTap: disabled ? null : () => onChanged(option, !isSelected),
              ),
            ),
          );
        }),
      ],
    );
  }
}

class _SingleChoiceStep extends StatelessWidget {
  final String title;
  final String subtitle;
  final List<_OnboardingOption> options;
  final String? value;
  final ValueChanged<String> onChanged;

  const _SingleChoiceStep({
    required this.title,
    required this.subtitle,
    required this.options,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return ListView(
      children: [
        Text(title, style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 8),
        Text(
          subtitle,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: colors.onSurface.withValues(alpha: 0.72),
          ),
        ),
        const SizedBox(height: 16),
        ...options.map((option) {
          final selected = option.value == value;

          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _ChoiceTile(
              title: option.title,
              subtitle: option.subtitle,
              selected: selected,
              trailing: Icon(
                selected
                    ? Icons.radio_button_checked
                    : Icons.radio_button_unchecked,
                color: selected ? colors.primary : null,
              ),
              onTap: () => onChanged(option.value),
            ),
          );
        }),
      ],
    );
  }
}

class _PlanPreviewStep extends StatelessWidget {
  final List<String> focusAreas;
  final String level;
  final String obstacle;
  final String routine;

  const _PlanPreviewStep({
    required this.focusAreas,
    required this.level,
    required this.obstacle,
    required this.routine,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final focusLabel = focusAreas.isEmpty
        ? 'general AI fluency'
        : focusAreas.join(', ');

    return ListView(
      children: [
        Text('Your first pack is ready', style: textTheme.headlineSmall),
        const SizedBox(height: 8),
        Text(
          'Based on your answers, Sivra will start with practical reps you can finish today.',
          style: textTheme.bodyMedium?.copyWith(
            color: colors.onSurface.withValues(alpha: 0.72),
          ),
        ),
        const SizedBox(height: 20),
        _PlanBullet(
          icon: Icons.track_changes_outlined,
          title: 'Focus',
          body: 'Start with $focusLabel.',
        ),
        _PlanBullet(
          icon: Icons.tune_outlined,
          title: 'Level',
          body: 'Calibrate examples for $level.',
        ),
        _PlanBullet(
          icon: Icons.psychology_alt_outlined,
          title: 'Practice',
          body: 'Include drills that help with $obstacle.',
        ),
        _PlanBullet(
          icon: Icons.schedule_outlined,
          title: 'Routine',
          body: 'Keep the habit realistic: $routine.',
        ),
      ],
    );
  }
}

class _PlanBullet extends StatelessWidget {
  final IconData icon;
  final String title;
  final String body;

  const _PlanBullet({
    required this.icon,
    required this.title,
    required this.body,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border.all(color: colors.onSurface.withValues(alpha: 0.14)),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: colors.primary),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: Theme.of(context).textTheme.titleSmall),
                    const SizedBox(height: 4),
                    Text(
                      body,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: colors.onSurface.withValues(alpha: 0.72),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ChoiceTile extends StatelessWidget {
  final String title;
  final String? subtitle;
  final bool selected;
  final Widget trailing;
  final VoidCallback? onTap;

  const _ChoiceTile({
    required this.title,
    this.subtitle,
    required this.selected,
    required this.trailing,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return ListTile(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(
          color: selected
              ? colors.primary
              : Theme.of(context).dividerColor.withValues(alpha: 0.35),
        ),
      ),
      title: Text(title),
      subtitle: subtitle == null ? null : Text(subtitle!),
      trailing: trailing,
      onTap: onTap,
    );
  }
}

class _OnboardingOption {
  final String value;
  final String title;
  final String subtitle;

  const _OnboardingOption({
    required this.value,
    required this.title,
    required this.subtitle,
  });
}
