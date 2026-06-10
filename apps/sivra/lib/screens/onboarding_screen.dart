import 'dart:async';

import 'package:flutter/material.dart';

import '../design/sivra_colors.dart';
import '../services/firestore_service.dart';
import 'app_shell.dart';
import 'paywall_screen.dart';

class OnboardingScreen extends StatefulWidget {
  final String uid;
  final VoidCallback onCompleted;
  final ValueChanged<List<String>>? onCompletedWithFocus;
  final bool analyticsEnabled;
  final List<String> initialSelectedFocus;
  final int initialStepIndex;
  final bool allowLocalCompletion;
  final WidgetBuilder? paywallBuilder;

  const OnboardingScreen({
    super.key,
    required this.uid,
    required this.onCompleted,
    this.onCompletedWithFocus,
    this.analyticsEnabled = true,
    this.initialSelectedFocus = const <String>[],
    this.initialStepIndex = 0,
    this.allowLocalCompletion = false,
    this.paywallBuilder,
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
  bool _brandAssetsCached = false;

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

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_brandAssetsCached) {
      return;
    }
    _brandAssetsCached = true;
    precacheImage(const AssetImage('assets/brand/sivra-sigil.png'), context);
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
      if (widget.allowLocalCompletion) {
        await _finish(focusAreas);
        return;
      }

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

    await _finish(focusAreas);
  }

  Future<void> _finish(List<String> focusAreas) async {
    if (!mounted) {
      return;
    }

    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: widget.paywallBuilder ?? (_) => const PaywallScreen(),
      ),
    );

    if (!mounted) {
      return;
    }

    widget.onCompleted();
    final completionWithFocus = widget.onCompletedWithFocus;
    if (completionWithFocus != null) {
      completionWithFocus(focusAreas);
      return;
    }

    Navigator.of(context).pushReplacementNamed(AppShell.routeName);
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
      3 => 'Begin My Ritual',
      _ => 'Continue',
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SivraColors.deepInk,
      body: _ChamberBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
            child: Column(
              children: [
                _OnboardingHeader(canGoBack: _stepIndex > 0, onBack: _back),
                const SizedBox(height: 8),
                _ProgressDots(index: _stepIndex, count: _stepCount),
                const SizedBox(height: 12),
                Expanded(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 320),
                    switchInCurve: Curves.easeOutCubic,
                    switchOutCurve: Curves.easeInCubic,
                    transitionBuilder: (child, animation) {
                      final offset = Tween<Offset>(
                        begin: const Offset(0.035, 0),
                        end: Offset.zero,
                      ).animate(animation);
                      return FadeTransition(
                        opacity: animation,
                        child: SlideTransition(position: offset, child: child),
                      );
                    },
                    child: KeyedSubtree(
                      key: ValueKey(_stepIndex),
                      child: _buildStep(context),
                    ),
                  ),
                ),
                const SizedBox(height: 22),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(58),
                      backgroundColor: SivraColors.bronze,
                      foregroundColor: SivraColors.deepInk,
                      disabledBackgroundColor: SivraColors.bronze.withValues(
                        alpha: 0.28,
                      ),
                      disabledForegroundColor: SivraColors.warmIvory.withValues(
                        alpha: 0.42,
                      ),
                      elevation: 8,
                      shadowColor: SivraColors.bronze.withValues(alpha: 0.25),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(22),
                      ),
                      textStyle: Theme.of(context).textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    onPressed: _canContinue && !_saving ? _continue : null,
                    child: Text(_continueLabel),
                  ),
                ),
              ],
            ),
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
        if (_selectedRoles.length >= 3) {
          return;
        }
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
      key: const ValueKey('onboarding-progress'),
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (dotIndex) {
        final completed = dotIndex <= index;

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 5),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 240),
            curve: Curves.easeOutCubic,
            height: 8,
            width: 8,
            decoration: BoxDecoration(
              color: completed
                  ? colors.primary
                  : colors.onSurface.withValues(alpha: 0.2),
              shape: BoxShape.circle,
              boxShadow: completed
                  ? [
                      BoxShadow(
                        color: colors.primary.withValues(alpha: 0.34),
                        blurRadius: 8,
                      ),
                    ]
                  : null,
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
    return const _CenteredStep(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _SigilGlow(),
          SizedBox(height: 40),
          _HeroTitle(
            text: 'Walk Into Any Room Prepared',
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 28),
          Text(
            'A daily thinking ritual for founders,\noperators, and builders.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: SivraColors.mutedText,
              fontSize: 17,
              height: 1.5,
            ),
          ),
          SizedBox(height: 30),
          _RitualSummary(),
        ],
      ),
    );
  }
}

class _RitualStep extends StatelessWidget {
  const _RitualStep();

  @override
  Widget build(BuildContext context) {
    return const _CenteredStep(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _SectionLabel(text: 'YOUR DAILY PRACTICE'),
          SizedBox(height: 14),
          _HeroTitle(text: 'Your Daily Ritual', textAlign: TextAlign.center),
          SizedBox(height: 36),
          _RitualCard(),
          SizedBox(height: 30),
          Text(
            '2 briefings to stay current.\n\n'
            '3 decisions to sharpen judgment.\n\n'
            '1 articulation prompt to express ideas clearly.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: SivraColors.mutedText,
              fontSize: 15,
              height: 1.4,
            ),
          ),
        ],
      ),
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
    return ListView(
      padding: const EdgeInsets.only(top: 24, bottom: 12),
      children: [
        const _HeroTitle(
          text: 'WHERE DO YOU WANT TO BECOME SHARPER?',
          textAlign: TextAlign.center,
          fontSize: 30,
        ),
        const SizedBox(height: 16),
        const Text(
          'Choose up to three areas.\n'
          'Your selections shape your daily ritual.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: SivraColors.mutedText,
            fontSize: 17,
            height: 1.45,
          ),
        ),
        const SizedBox(height: 44),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 12,
          runSpacing: 12,
          children: options.map((option) {
            final isSelected = selected.contains(option);
            final disabled = !isSelected && selected.length >= 3;

            return _IdentityChip(
              label: option == 'Product / Strategy'
                  ? 'Product Strategy'
                  : option,
              selected: isSelected,
              disabled: disabled,
              onTap: () => onChanged(option, !isSelected),
            );
          }).toList(),
        ),
      ],
    );
  }
}

class _IdentityStep extends StatelessWidget {
  const _IdentityStep();

  @override
  Widget build(BuildContext context) {
    return const _CenteredStep(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _SectionLabel(text: '365 DAYS. 365 OPPORTUNITIES.'),
          SizedBox(height: 18),
          _HeroTitle(
            text: 'FROM INFORMED → SHARP',
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 44),
          _FutureStatement(text: '365 opportunities to think better.'),
          _FutureStatement(text: 'Every ritual compounds.'),
          _FutureStatement(text: 'Every insight is saved.'),
          _FutureStatement(
            text: 'The archive becomes your personal thinking system.',
          ),
          _FutureStatement(
            text: 'Make better decisions under pressure.',
            emphasized: true,
          ),
        ],
      ),
    );
  }
}

class _ChamberBackground extends StatelessWidget {
  final Widget child;

  const _ChamberBackground({required this.child});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF07101D), Color(0xFF0A1729), Color(0xFF07111F)],
          stops: [0, 0.52, 1],
        ),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Positioned(
            top: -180,
            left: -80,
            right: -80,
            child: Container(
              height: 390,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    SivraColors.bronze.withValues(alpha: 0.11),
                    SivraColors.bronze.withValues(alpha: 0),
                  ],
                ),
              ),
            ),
          ),
          child,
        ],
      ),
    );
  }
}

class _OnboardingHeader extends StatelessWidget {
  final bool canGoBack;
  final VoidCallback onBack;

  const _OnboardingHeader({required this.canGoBack, required this.onBack});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 54,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: canGoBack
                ? IconButton(
                    tooltip: 'Back',
                    onPressed: onBack,
                    icon: const Icon(Icons.arrow_back_rounded),
                    color: SivraColors.warmIvory,
                  )
                : const SizedBox(width: 48, height: 48),
          ),
          const Text(
            'Sivra',
            semanticsLabel: 'Sivra',
            style: TextStyle(
              color: SivraColors.mutedText,
              fontSize: 17,
              fontWeight: FontWeight.w400,
              letterSpacing: 1.2,
            ),
          ),
        ],
      ),
    );
  }
}

class _CenteredStep extends StatelessWidget {
  final Widget child;

  const _CenteredStep({required this.child});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight - 40),
            child: Center(child: child),
          ),
        );
      },
    );
  }
}

class _HeroTitle extends StatelessWidget {
  final String text;
  final TextAlign textAlign;
  final double fontSize;

  const _HeroTitle({
    required this.text,
    required this.textAlign,
    this.fontSize = 40,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      textAlign: textAlign,
      style: TextStyle(
        color: SivraColors.warmIvory,
        fontSize: fontSize,
        height: 1.08,
        fontWeight: FontWeight.w700,
        letterSpacing: -1.1,
        shadows: [
          Shadow(
            color: SivraColors.bronze.withValues(alpha: 0.18),
            blurRadius: 28,
          ),
        ],
      ),
    );
  }
}

class _SigilGlow extends StatelessWidget {
  const _SigilGlow();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 112,
      height: 112,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: SivraColors.surface.withValues(alpha: 0.32),
        boxShadow: [
          BoxShadow(
            color: SivraColors.bronze.withValues(alpha: 0.14),
            blurRadius: 45,
            spreadRadius: 6,
          ),
        ],
      ),
      child: Image.asset(
        'assets/brand/sivra-sigil.png',
        color: SivraColors.bronze,
        colorBlendMode: BlendMode.srcIn,
      ),
    );
  }
}

class _RitualSummary extends StatelessWidget {
  const _RitualSummary();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final dividerMargin = constraints.maxWidth < 330 ? 10.0 : 22.0;

        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Expanded(
              child: _SummaryItem(value: '2', label: 'Briefings'),
            ),
            _SummaryDivider(horizontalMargin: dividerMargin),
            const Expanded(
              child: _SummaryItem(value: '3', label: 'Decisions'),
            ),
            _SummaryDivider(horizontalMargin: dividerMargin),
            const Expanded(
              child: _SummaryItem(value: '7', label: 'Minutes'),
            ),
          ],
        );
      },
    );
  }
}

class _SummaryItem extends StatelessWidget {
  final String value;
  final String label;

  const _SummaryItem({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            color: SivraColors.bronze,
            fontSize: 23,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 3),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            label,
            maxLines: 1,
            style: const TextStyle(
              color: SivraColors.mutedText,
              fontSize: 13,
              letterSpacing: 0.2,
            ),
          ),
        ),
      ],
    );
  }
}

class _SummaryDivider extends StatelessWidget {
  final double horizontalMargin;

  const _SummaryDivider({required this.horizontalMargin});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 34,
      margin: EdgeInsets.symmetric(horizontal: horizontalMargin),
      color: SivraColors.warmIvory.withValues(alpha: 0.12),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;

  const _SectionLabel({required this.text});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: SivraColors.bronze,
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 2.1,
      ),
    );
  }
}

class _RitualCard extends StatelessWidget {
  const _RitualCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(maxWidth: 390),
      padding: const EdgeInsets.fromLTRB(26, 26, 26, 28),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            SivraColors.surfaceSoft.withValues(alpha: 0.95),
            SivraColors.surface.withValues(alpha: 0.78),
          ],
        ),
        border: Border.all(color: SivraColors.bronze.withValues(alpha: 0.22)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 36,
            offset: const Offset(0, 20),
          ),
          BoxShadow(
            color: SivraColors.bronze.withValues(alpha: 0.09),
            blurRadius: 40,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionLabel(text: 'TODAY’S INVESTMENT'),
          const SizedBox(height: 12),
          const Text(
            '7 minutes.',
            style: TextStyle(
              color: SivraColors.warmIvory,
              fontSize: 27,
              fontWeight: FontWeight.w600,
              letterSpacing: -0.4,
            ),
          ),
          const SizedBox(height: 34),
          Container(
            height: 1,
            color: SivraColors.warmIvory.withValues(alpha: 0.1),
          ),
          const SizedBox(height: 24),
          const Row(
            children: [
              Expanded(
                child: _CardMetric(value: '2', label: 'Briefings'),
              ),
              Expanded(
                child: _CardMetric(value: '3', label: 'Decisions'),
              ),
              Expanded(
                child: _CardMetric(value: '1', label: 'Articulation'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CardMetric extends StatelessWidget {
  final String value;
  final String label;

  const _CardMetric({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            color: SivraColors.bronze,
            fontSize: 28,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 3),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            label,
            maxLines: 1,
            style: const TextStyle(color: SivraColors.mutedText, fontSize: 13),
          ),
        ),
      ],
    );
  }
}

class _IdentityChip extends StatelessWidget {
  final String label;
  final bool selected;
  final bool disabled;
  final VoidCallback onTap;

  const _IdentityChip({
    required this.label,
    required this.selected,
    required this.disabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      selected: selected,
      button: true,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 180),
        opacity: disabled ? 0.42 : 1,
        child: AnimatedScale(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutBack,
          scale: selected ? 1.025 : 1,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              key: ValueKey(
                selected ? 'role-chip-selected-$label' : 'role-chip-$label',
              ),
              onTap: disabled ? null : onTap,
              borderRadius: BorderRadius.circular(24),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOutCubic,
                padding: const EdgeInsets.symmetric(
                  horizontal: 21,
                  vertical: 15,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  color: selected
                      ? SivraColors.bronze.withValues(alpha: 0.92)
                      : SivraColors.surfaceSoft.withValues(alpha: 0.68),
                  border: Border.all(
                    color: selected
                        ? SivraColors.bronze
                        : SivraColors.warmIvory.withValues(alpha: 0.1),
                  ),
                  boxShadow: selected
                      ? [
                          BoxShadow(
                            color: SivraColors.bronze.withValues(alpha: 0.22),
                            blurRadius: 18,
                            offset: const Offset(0, 8),
                          ),
                        ]
                      : null,
                ),
                child: Text(
                  label,
                  style: TextStyle(
                    color: selected
                        ? SivraColors.deepInk
                        : SivraColors.warmIvory,
                    fontSize: 15,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _FutureStatement extends StatelessWidget {
  final String text;
  final bool emphasized;

  const _FutureStatement({required this.text, this.emphasized = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 19),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: TextStyle(
          color: emphasized ? SivraColors.bronze : SivraColors.warmIvory,
          fontSize: emphasized ? 22 : 20,
          height: 1.35,
          fontWeight: emphasized ? FontWeight.w700 : FontWeight.w400,
        ),
      ),
    );
  }
}
