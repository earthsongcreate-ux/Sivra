import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../design/sivra_colors.dart';
import '../services/debug_onboarding_override.dart';
import '../services/firestore_service.dart';
import '../widgets/sivra_motif.dart';
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
  ];

  final Set<String> _selectedRoles = {};
  int _stepIndex = 0;
  bool _saving = false;
  bool _brandAssetsCached = false;

  static const _stepCount = 5;

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
        if (kDebugMode) {
          await DebugOnboardingOverride.clearFor(widget.uid);
        }
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

    if (kDebugMode) {
      await DebugOnboardingOverride.clearFor(widget.uid);
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
      3 => 'learning_memory',
      _ => 'ritual_ready',
    };
  }

  String get _continueLabel {
    if (_saving) {
      return 'Saving...';
    }
    return switch (_stepIndex) {
      0 => 'Begin',
      4 => 'Begin Today’s Ritual',
      _ => 'Continue',
    };
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Theme(
      data: theme.copyWith(
        textTheme: theme.textTheme.apply(fontFamily: 'Inter'),
        primaryTextTheme: theme.primaryTextTheme.apply(fontFamily: 'Inter'),
      ),
      child: Scaffold(
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
                          child: SlideTransition(
                            position: offset,
                            child: child,
                          ),
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
                        disabledForegroundColor: SivraColors.warmIvory
                            .withValues(alpha: 0.42),
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
      3 => const _LearningMemoryStep(),
      _ => _ReadyStep(selectedRoles: _selectedRoles.toList()),
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
        final active = dotIndex == index;
        final size = active ? 8.0 : 6.0;

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 5),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 240),
            curve: Curves.easeOutCubic,
            height: size,
            width: size,
            decoration: BoxDecoration(
              color: active
                  ? SivraColors.bronze
                  : colors.onSurface.withValues(alpha: 0.2),
              shape: BoxShape.circle,
              boxShadow: active
                  ? [
                      BoxShadow(
                        color: SivraColors.bronze.withValues(alpha: 0.3),
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
      verticalOffset: -48,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _SigilGlow(),
          SizedBox(height: 34),
          _SectionLabel(text: 'DAILY RITUAL'),
          SizedBox(height: 14),
          _HeroTitle(
            text: 'WALK INTO ANY ROOM PREPARED',
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 22),
          SivraMotif(),
          SizedBox(height: 22),
          Text(
            'Sharpen judgment, decision-making, and communication\n'
            'in 7 minutes a day.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: SivraColors.mutedText,
              fontSize: 16,
              height: 1.45,
            ),
          ),
          SizedBox(height: 28),
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
          _SectionLabel(text: 'THE PRACTICE'),
          SizedBox(height: 14),
          _HeroTitle(
            text: 'GREAT THINKING IS A DAILY PRACTICE',
            textAlign: TextAlign.center,
            fontSize: 35,
          ),
          SizedBox(height: 22),
          SivraMotif(),
          SizedBox(height: 28),
          _RitualSequence(),
          SizedBox(height: 30),
          Text(
            'Read.\nDecide.\nExplain.\nRepeat.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: SivraColors.warmIvory,
              fontSize: 18,
              height: 1.55,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.2,
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
    return CustomScrollView(
      clipBehavior: Clip.none,
      semanticChildCount: options.length,
      slivers: [
        const SliverPadding(
          padding: EdgeInsets.fromLTRB(0, 18, 0, 28),
          sliver: SliverToBoxAdapter(
            child: Column(
              children: [
                _SectionLabel(text: 'YOUR FOCUS'),
                SizedBox(height: 14),
                _HeroTitle(
                  text: 'WHERE DO YOU WANT TO BECOME SHARPER?',
                  textAlign: TextAlign.center,
                  fontSize: 31,
                ),
                SizedBox(height: 18),
                SivraMotif(width: 138),
                SizedBox(height: 18),
                Text(
                  'Choose up to three areas.\n'
                  'Your daily ritual adapts to how you think.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: SivraColors.mutedText,
                    fontSize: 16,
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
        ),
        SliverList.separated(
          itemBuilder: (context, index) {
            final option = options[index];
            final isSelected = selected.contains(option);
            final disabled = !isSelected && selected.length >= 3;
            final label = option == 'Product / Strategy'
                ? 'Product Strategy'
                : option;

            return _FocusCard(
              label: label,
              icon: _iconForRole(option),
              selected: isSelected,
              disabled: disabled,
              onTap: () => onChanged(option, !isSelected),
            );
          },
          separatorBuilder: (context, index) => const SizedBox(height: 12),
          itemCount: options.length,
        ),
        const SliverPadding(
          padding: EdgeInsets.fromLTRB(4, 20, 0, 8),
          sliver: SliverToBoxAdapter(
            child: Row(
              children: [
                Icon(
                  Icons.info_outline_rounded,
                  size: 18,
                  color: SivraColors.mutedText,
                ),
                SizedBox(width: 9),
                Expanded(
                  child: Text(
                    'Select up to three focus areas.',
                    style: TextStyle(
                      color: SivraColors.mutedText,
                      fontSize: 13,
                      letterSpacing: 0.2,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  IconData? _iconForRole(String role) {
    return switch (role) {
      'Founder' => null,
      'Product / Strategy' => Icons.gps_fixed_rounded,
      'Operator' => Icons.settings_rounded,
      'Investor' => Icons.bar_chart_rounded,
      'Builder' => Icons.construction_rounded,
      'Marketing' => Icons.campaign_rounded,
      _ => Icons.adjust_rounded,
    };
  }
}

class _FocusCard extends StatelessWidget {
  final String label;
  final IconData? icon;
  final bool selected;
  final bool disabled;
  final VoidCallback onTap;

  const _FocusCard({
    required this.label,
    required this.icon,
    required this.selected,
    required this.disabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final iconColor = selected
        ? SivraColors.bronze
        : SivraColors.mutedText.withValues(alpha: 0.72);

    return Semantics(
      label: '$label focus area',
      selected: selected,
      enabled: !disabled,
      button: true,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 180),
        opacity: disabled ? 0.48 : 1,
        child: AnimatedScale(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          scale: selected ? 1.008 : 1,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              key: ValueKey(
                selected ? 'role-chip-selected-$label' : 'role-chip-$label',
              ),
              onTap: disabled ? null : onTap,
              borderRadius: BorderRadius.circular(20),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeOutCubic,
                constraints: const BoxConstraints(minHeight: 76),
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 11,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  color: selected
                      ? SivraColors.surfaceSoft
                      : SivraColors.surface.withValues(alpha: 0.72),
                  border: Border.all(
                    color: selected
                        ? SivraColors.bronze
                        : SivraColors.bronze.withValues(alpha: 0.2),
                    width: selected ? 1.25 : 1,
                  ),
                  boxShadow: selected
                      ? [
                          BoxShadow(
                            color: SivraColors.bronze.withValues(alpha: 0.17),
                            blurRadius: 20,
                            spreadRadius: 1,
                          ),
                        ]
                      : null,
                ),
                child: Row(
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      width: 48,
                      height: 48,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: selected
                            ? SivraColors.bronze.withValues(alpha: 0.11)
                            : Colors.transparent,
                        border: Border.all(
                          color: selected
                              ? SivraColors.bronze.withValues(alpha: 0.48)
                              : SivraColors.mutedText.withValues(alpha: 0.3),
                        ),
                      ),
                      child: icon == null
                          ? Semantics(
                              label: 'Knight',
                              child: CustomPaint(
                                size: const Size.square(28),
                                painter: _KnightIconPainter(iconColor),
                              ),
                            )
                          : Icon(icon, size: 25, color: iconColor),
                    ),
                    const SizedBox(width: 18),
                    Expanded(
                      child: Text(
                        label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: selected
                              ? SivraColors.warmIvory
                              : SivraColors.warmIvory.withValues(alpha: 0.84),
                          fontSize: 16,
                          fontWeight: selected
                              ? FontWeight.w600
                              : FontWeight.w500,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      width: 27,
                      height: 27,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        shape: selected ? BoxShape.circle : BoxShape.rectangle,
                        borderRadius: selected
                            ? null
                            : BorderRadius.circular(7),
                        color: selected
                            ? SivraColors.bronze.withValues(alpha: 0.16)
                            : Colors.transparent,
                        border: Border.all(
                          color: selected
                              ? SivraColors.bronze
                              : SivraColors.bronze.withValues(alpha: 0.55),
                          width: 1.2,
                        ),
                      ),
                      child: selected
                          ? const Icon(
                              Icons.check_rounded,
                              size: 18,
                              color: SivraColors.bronze,
                            )
                          : null,
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

class _KnightIconPainter extends CustomPainter {
  final Color color;

  const _KnightIconPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final scaleX = size.width / 28;
    final scaleY = size.height / 28;
    final path = Path()
      ..moveTo(7 * scaleX, 24 * scaleY)
      ..lineTo(22 * scaleX, 24 * scaleY)
      ..lineTo(22 * scaleX, 21.5 * scaleY)
      ..lineTo(19.5 * scaleX, 20 * scaleY)
      ..cubicTo(
        20.8 * scaleX,
        17.2 * scaleY,
        21.2 * scaleX,
        14.2 * scaleY,
        20.2 * scaleX,
        11.3 * scaleY,
      )
      ..cubicTo(
        19.2 * scaleX,
        8.2 * scaleY,
        16.5 * scaleX,
        5.6 * scaleY,
        12.7 * scaleX,
        4.2 * scaleY,
      )
      ..lineTo(13.4 * scaleX, 8.2 * scaleY)
      ..lineTo(9.2 * scaleX, 6.2 * scaleY)
      ..lineTo(10.2 * scaleX, 10.2 * scaleY)
      ..cubicTo(
        7.8 * scaleX,
        12.2 * scaleY,
        6.7 * scaleX,
        14.4 * scaleY,
        7.2 * scaleX,
        17.1 * scaleY,
      )
      ..cubicTo(
        8.2 * scaleX,
        15.8 * scaleY,
        9.8 * scaleX,
        14.9 * scaleY,
        11.8 * scaleX,
        14.4 * scaleY,
      )
      ..cubicTo(
        13.8 * scaleX,
        13.9 * scaleY,
        15.4 * scaleX,
        14.6 * scaleY,
        15.8 * scaleX,
        16.5 * scaleY,
      )
      ..cubicTo(
        16.1 * scaleX,
        18.1 * scaleY,
        14.9 * scaleX,
        19.5 * scaleY,
        12.5 * scaleX,
        20.2 * scaleY,
      )
      ..lineTo(7 * scaleX, 21.5 * scaleY)
      ..close();

    canvas.drawPath(path, Paint()..color = color);
    canvas.drawCircle(
      Offset(16.3 * scaleX, 9.2 * scaleY),
      1.05 * scaleX,
      Paint()..color = SivraColors.deepInk,
    );
  }

  @override
  bool shouldRepaint(_KnightIconPainter oldDelegate) {
    return oldDelegate.color != color;
  }
}

class _LearningMemoryStep extends StatelessWidget {
  const _LearningMemoryStep();

  @override
  Widget build(BuildContext context) {
    return const _CenteredStep(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _SectionLabel(text: 'LEARNING MEMORY'),
          SizedBox(height: 14),
          _HeroTitle(
            text: 'YOUR THINKING COMPOUNDS',
            textAlign: TextAlign.center,
            fontSize: 37,
          ),
          SizedBox(height: 22),
          SivraMotif(),
          SizedBox(height: 22),
          Text(
            'Every briefing, decision, and answer becomes part of your '
            'learning memory.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: SivraColors.mutedText,
              fontSize: 16,
              height: 1.5,
            ),
          ),
          SizedBox(height: 34),
          _MemoryArchive(),
        ],
      ),
    );
  }
}

class _ReadyStep extends StatelessWidget {
  final List<String> selectedRoles;

  const _ReadyStep({required this.selectedRoles});

  @override
  Widget build(BuildContext context) {
    final roles = selectedRoles.isEmpty
        ? const <String>['Founder']
        : selectedRoles;

    return _CenteredStep(
      verticalOffset: -48,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const _ReadySeal(),
          const SizedBox(height: 28),
          const _SectionLabel(text: 'PREPARED FOR YOU'),
          const SizedBox(height: 14),
          const _HeroTitle(
            text: 'YOUR RITUAL IS READY',
            textAlign: TextAlign.center,
            fontSize: 38,
          ),
          const SizedBox(height: 22),
          const SivraMotif(),
          const SizedBox(height: 24),
          const Text(
            'Based on your selections:',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: SivraColors.mutedText,
              fontSize: 15,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16),
          ...roles.map(
            (role) => Padding(
              padding: const EdgeInsets.only(bottom: 7),
              child: Text(
                role == 'Product / Strategy' ? 'Product Strategy' : role,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: SivraColors.warmIvory,
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          const SizedBox(height: 18),
          const Text(
            'Your edge is prepared.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: SivraColors.bronze,
              fontSize: 16,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.2,
            ),
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
  final double verticalOffset;

  const _CenteredStep({required this.child, this.verticalOffset = 0});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final appliedOffset = constraints.maxHeight >= 650
            ? verticalOffset
            : verticalOffset / 4;

        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight - 40),
            child: Transform.translate(
              offset: Offset(0, appliedOffset),
              child: Center(child: child),
            ),
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
        fontFamily: 'Playfair Display',
        fontWeight: FontWeight.w600,
        letterSpacing: -0.7,
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
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            SivraColors.surfaceSoft.withValues(alpha: 0.9),
            SivraColors.surface.withValues(alpha: 0.72),
          ],
        ),
        border: Border.all(color: SivraColors.bronze.withValues(alpha: 0.32)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.28),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
          BoxShadow(
            color: SivraColors.bronze.withValues(alpha: 0.1),
            blurRadius: 32,
            spreadRadius: 2,
          ),
        ],
      ),
      child: const CustomPaint(painter: _SivraSigilPainter()),
    );
  }
}

class _SivraSigilPainter extends CustomPainter {
  const _SivraSigilPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.shortestSide * 0.34;
    final bronze = Paint()
      ..color = SivraColors.bronze
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.25;
    final softBronze = Paint()
      ..color = SivraColors.bronze.withValues(alpha: 0.52)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.9;

    canvas.drawCircle(center, radius, bronze);
    canvas.drawCircle(center, radius * 0.52, softBronze);
    canvas.drawLine(
      Offset(center.dx, center.dy - radius - 7),
      Offset(center.dx, center.dy + radius + 7),
      softBronze,
    );
    canvas.drawLine(
      Offset(center.dx - radius - 7, center.dy),
      Offset(center.dx + radius + 7, center.dy),
      softBronze,
    );

    final diamond = Path()
      ..moveTo(center.dx, center.dy - radius - 10)
      ..lineTo(center.dx + 3.5, center.dy - radius - 6.5)
      ..lineTo(center.dx, center.dy - radius - 3)
      ..lineTo(center.dx - 3.5, center.dy - radius - 6.5)
      ..close();
    canvas.drawPath(diamond, Paint()..color = SivraColors.bronze);

    final textPainter = TextPainter(
      text: const TextSpan(
        text: 'S',
        style: TextStyle(
          color: SivraColors.bronze,
          fontFamily: 'Playfair Display',
          fontSize: 42,
          fontWeight: FontWeight.w600,
          height: 1,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    textPainter.paint(
      canvas,
      center - Offset(textPainter.width / 2, textPainter.height / 2),
    );
  }

  @override
  bool shouldRepaint(_SivraSigilPainter oldDelegate) => false;
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

class _RitualSequence extends StatelessWidget {
  const _RitualSequence();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(maxWidth: 390),
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
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
      child: const Row(
        children: [
          Expanded(
            child: _CardMetric(value: '2', label: 'Briefings'),
          ),
          _SequenceDot(),
          Expanded(
            child: _CardMetric(value: '3', label: 'Decisions'),
          ),
          _SequenceDot(),
          Expanded(
            child: _CardMetric(value: '1', label: 'Articulation'),
          ),
        ],
      ),
    );
  }
}

class _SequenceDot extends StatelessWidget {
  const _SequenceDot();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 3,
      height: 3,
      decoration: BoxDecoration(
        color: SivraColors.bronze.withValues(alpha: 0.55),
        shape: BoxShape.circle,
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

class _MemoryArchive extends StatelessWidget {
  const _MemoryArchive();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(maxWidth: 390),
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            SivraColors.surfaceSoft.withValues(alpha: 0.96),
            SivraColors.surface.withValues(alpha: 0.78),
          ],
        ),
        border: Border.all(color: SivraColors.bronze.withValues(alpha: 0.22)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.28),
            blurRadius: 30,
            offset: const Offset(0, 16),
          ),
          BoxShadow(
            color: SivraColors.bronze.withValues(alpha: 0.07),
            blurRadius: 36,
            spreadRadius: 1,
          ),
        ],
      ),
      child: const Column(
        children: [
          _MemoryRow(
            icon: Icons.archive_outlined,
            title: 'Your archive',
            detail: 'The ideas worth returning to',
          ),
          _MemoryDivider(),
          _MemoryRow(
            icon: Icons.calendar_view_week_outlined,
            title: 'Weekly recap',
            detail: 'Patterns in how you decide',
          ),
          _MemoryDivider(),
          _MemoryRow(
            icon: Icons.auto_graph_rounded,
            title: 'Learning memory',
            detail: 'A sharper ritual over time',
          ),
        ],
      ),
    );
  }
}

class _MemoryRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String detail;

  const _MemoryRow({
    required this.icon,
    required this.title,
    required this.detail,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: SivraColors.bronze.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: SivraColors.bronze.withValues(alpha: 0.2),
            ),
          ),
          child: Icon(icon, size: 21, color: SivraColors.bronze),
        ),
        const SizedBox(width: 15),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: SivraColors.warmIvory,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                detail,
                style: const TextStyle(
                  color: SivraColors.mutedText,
                  fontSize: 13,
                  height: 1.25,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _MemoryDivider extends StatelessWidget {
  const _MemoryDivider();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 1,
      margin: const EdgeInsets.symmetric(vertical: 16),
      color: SivraColors.warmIvory.withValues(alpha: 0.08),
    );
  }
}

class _ReadySeal extends StatelessWidget {
  const _ReadySeal();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 82,
      height: 82,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            SivraColors.surfaceSoft.withValues(alpha: 0.9),
            SivraColors.surface.withValues(alpha: 0.72),
          ],
        ),
        border: Border.all(color: SivraColors.bronze.withValues(alpha: 0.34)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.28),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
          BoxShadow(
            color: SivraColors.bronze.withValues(alpha: 0.1),
            blurRadius: 28,
            spreadRadius: 2,
          ),
        ],
      ),
      child: const Icon(
        Icons.check_rounded,
        color: SivraColors.bronze,
        size: 34,
      ),
    );
  }
}
