import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';

import '../services/firestore_service.dart';
import 'today_screen.dart';

class OnboardingScreen extends StatefulWidget {
  final String uid;
  final VoidCallback onCompleted;
  final bool analyticsEnabled;
  final List<String> initialSelectedFocus;
  final int initialStepIndex;

  const OnboardingScreen({
    super.key,
    required this.uid,
    required this.onCompleted,
    this.analyticsEnabled = true,
    this.initialSelectedFocus = const <String>[],
    this.initialStepIndex = 0,
  });

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  static const _roleOptions = <String>[
    'Founder',
    'Product / Strategy',
    'Operator',
    'Investor',
    'Builder',
    'Marketing',
    'Other',
  ];

  final Set<String> _selectedRoles = {};
  int _stepIndex = 0;
  bool _saving = false;

  static const _stepCount = 4;

  bool get _canContinue {
    return switch (_stepIndex) {
      2 => _selectedRoles.isNotEmpty && _selectedRoles.length <= 3,
      _ => true,
    };
  }

  @override
  void initState() {
    super.initState();
    _selectedRoles.addAll(
      widget.initialSelectedFocus.map(_roleForLegacyFocus).take(3),
    );
    _stepIndex = widget.initialStepIndex.clamp(0, _stepCount - 1);
    if (!widget.analyticsEnabled) {
      return;
    }
    _logEventSafely(
      name: 'onboarding_started',
      properties: const <String, dynamic>{'version': 3},
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

    if (widget.analyticsEnabled) {
      _logEventSafely(
        name: 'onboarding_step_completed',
        properties: <String, dynamic>{
          'version': 3,
          'step': _stepIndex + 1,
          'stepId': _stepId,
        },
      );
    }

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

    final roles = _selectedRoles.toList();
    final focusAreas = _focusAreasForRoles(roles);

    try {
      await FirestoreService.instance.upsertProfile(
        uid: widget.uid,
        focusAreas: focusAreas,
        thinkingRoles: roles,
        onboardingVersion: 3,
      );
      await FirestoreService.instance.logEvent(
        uid: widget.uid,
        name: 'onboarding_completed',
        properties: <String, dynamic>{
          'version': 3,
          'thinkingRoles': roles,
          'focusAreas': focusAreas,
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
      0 => 'promise',
      1 => 'ritual',
      2 => 'personalization',
      _ => 'identity_shift',
    };
  }

  String get _continueLabel {
    if (_saving) {
      return 'Saving...';
    }
    return switch (_stepIndex) {
      1 => 'Build my pack',
      3 => 'Start Day 1',
      _ => 'Continue',
    };
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        leading: _stepIndex == 0
            ? null
            : IconButton(
                tooltip: 'Back',
                icon: const Icon(Icons.chevron_left),
                onPressed: _back,
              ),
        title: Image.asset(
          'assets/brand/sivra-logo-horizontal.png',
          height: 28,
          fit: BoxFit.contain,
          color: colors.onSurface,
          colorBlendMode: BlendMode.srcIn,
          semanticLabel: 'Sivra',
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
          child: Column(
            children: [
              _ProgressDots(index: _stepIndex, count: _stepCount),
              const SizedBox(height: 28),
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
      0 => const _PromiseStep(),
      1 => const _RitualStep(),
      2 => _RoleStep(
        selected: _selectedRoles,
        options: _roleOptions,
        onChanged: _setRoleSelected,
      ),
      _ => const _IdentityStep(),
    };
  }

  void _setRoleSelected(String option, bool selected) {
    setState(() {
      if (selected) {
        _selectedRoles.add(option);
      } else {
        _selectedRoles.remove(option);
      }
    });
  }

  String _roleForLegacyFocus(String focus) {
    return switch (focus) {
      'Product strategy' => 'Product / Strategy',
      'GTM & sales' => 'Marketing',
      'Hiring & team' => 'Founder',
      'Infra & costs' => 'Operator',
      _ => _roleOptions.contains(focus) ? focus : 'Founder',
    };
  }

  List<String> _focusAreasForRoles(List<String> roles) {
    final focusAreas = <String>[];

    void add(String focus) {
      if (!focusAreas.contains(focus)) {
        focusAreas.add(focus);
      }
    }

    for (final role in roles) {
      switch (role) {
        case 'Founder':
          add('Product strategy');
          add('GTM & sales');
          add('Hiring & team');
          break;
        case 'Product / Strategy':
          add('Product strategy');
          break;
        case 'Operator':
          add('Infra & costs');
          add('Hiring & team');
          break;
        case 'Investor':
          add('Product strategy');
          add('GTM & sales');
          break;
        case 'Builder':
          add('Product strategy');
          add('Infra & costs');
          break;
        case 'Marketing':
          add('GTM & sales');
          break;
        default:
          add('Product strategy');
      }
    }

    return focusAreas.take(3).toList();
  }
}

class _ProgressDots extends StatelessWidget {
  final int index;
  final int count;

  const _ProgressDots({required this.index, required this.count});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (dotIndex) {
        final active = dotIndex == index;

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOut,
            height: active ? 8 : 7,
            width: active ? 8 : 7,
            decoration: BoxDecoration(
              color: active
                  ? colors.primary
                  : colors.onSurface.withValues(alpha: 0.28),
              shape: BoxShape.circle,
            ),
          ),
        );
      }),
    );
  }
}

class _PromiseStep extends StatelessWidget {
  const _PromiseStep();

  @override
  Widget build(BuildContext context) {
    return const _CopyStep(
      title: 'Walk into any room prepared.',
      body:
          'Sivra turns information into clear thinking—and helps you express it with calm, executive precision.',
    );
  }
}

class _RitualStep extends StatelessWidget {
  const _RitualStep();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return ListView(
      children: [
        const _StepTitle(
          title: 'Your Daily Pack (7 min)',
          body:
              '2 briefings to stay current.\n\n3 thinking drills to sharpen judgment.\n\n1 articulation prompt to say it clearly.',
        ),
        const SizedBox(height: 28),
        DecoratedBox(
          decoration: BoxDecoration(
            border: Border.all(color: colors.onSurface.withValues(alpha: 0.12)),
            borderRadius: BorderRadius.circular(8),
            color: colors.surface.withValues(alpha: 0.36),
          ),
          child: const Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _RitualLine(label: 'Briefings', value: '2'),
                _RitualLine(label: 'Thinking drills', value: '3'),
                _RitualLine(label: 'Articulation prompt', value: '1'),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _RoleStep extends StatelessWidget {
  final Set<String> selected;
  final List<String> options;
  final void Function(String option, bool selected) onChanged;

  const _RoleStep({
    required this.selected,
    required this.options,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return ListView(
      children: [
        const _StepTitle(
          title: 'What do you think for a living?',
          body:
              'Choose what matters most. Sivra shapes your Daily Pack around how you think.',
        ),
        const SizedBox(height: 18),
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
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                onTap: disabled ? null : () => onChanged(option, !isSelected),
              ),
            ),
          );
        }),
        const SizedBox(height: 6),
        Text(
          'Choose up to 3.',
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
            color: colors.onSurface.withValues(alpha: 0.58),
          ),
        ),
      ],
    );
  }
}

class _IdentityStep extends StatelessWidget {
  const _IdentityStep();

  @override
  Widget build(BuildContext context) {
    return const Stack(
      children: [
        Positioned.fill(child: _DailyPackAtmosphere()),
        _CopyStep(
          title: 'From informed → sharp.',
          body:
              'Six months from now, you won’t just know more.\n\nYou’ll walk into meetings with a point of view, explain complexity simply, and think with greater precision under pressure.',
        ),
      ],
    );
  }
}

class _CopyStep extends StatelessWidget {
  final String title;
  final String body;

  const _CopyStep({required this.title, required this.body});

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        SizedBox(height: MediaQuery.sizeOf(context).height * 0.08),
        _StepTitle(title: title, body: body),
      ],
    );
  }
}

class _StepTitle extends StatelessWidget {
  final String title;
  final String body;

  const _StepTitle({required this.title, required this.body});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: textTheme.headlineMedium),
        const SizedBox(height: 14),
        Text(
          body,
          style: textTheme.bodyLarge?.copyWith(
            color: colors.onSurface.withValues(alpha: 0.76),
            height: 1.42,
          ),
        ),
      ],
    );
  }
}

class _RitualLine extends StatelessWidget {
  final String label;
  final String value;

  const _RitualLine({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        children: [
          Text(
            value,
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(color: colors.primary),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(label, style: Theme.of(context).textTheme.titleMedium),
          ),
        ],
      ),
    );
  }
}

class _DailyPackAtmosphere extends StatelessWidget {
  const _DailyPackAtmosphere();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return IgnorePointer(
      child: Opacity(
        opacity: 0.16,
        child: ImageFiltered(
          imageFilter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Transform.translate(
            offset: const Offset(22, 80),
            child: DecoratedBox(
              decoration: BoxDecoration(
                border: Border.all(
                  color: colors.primary.withValues(alpha: 0.28),
                ),
                borderRadius: BorderRadius.circular(8),
                color: colors.surface.withValues(alpha: 0.44),
              ),
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      height: 18,
                      width: 160,
                      decoration: BoxDecoration(
                        color: colors.onSurface,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Container(
                      height: 86,
                      decoration: BoxDecoration(
                        border: Border.all(color: colors.primary),
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      height: 86,
                      decoration: BoxDecoration(
                        border: Border.all(color: colors.onSurface),
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ChoiceTile extends StatelessWidget {
  final String title;
  final bool selected;
  final Widget trailing;
  final VoidCallback? onTap;

  const _ChoiceTile({
    required this.title,
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
      trailing: trailing,
      onTap: onTap,
    );
  }
}
