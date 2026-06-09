import 'dart:async';

import 'package:flutter/material.dart';

import '../data/mock_daily_pack.dart';
import '../design/sivra_colors.dart';
import '../models/daily_pack.dart';
import '../models/drill_item.dart';
import '../models/entitlement_state.dart';
import '../config/app_environment.dart';
import '../services/auth_service.dart';
import '../services/daily_pack_service.dart';
import '../services/daily_thought_engine.dart';
import '../services/entitlement_service.dart';
import '../services/firestore_service.dart';
import '../utils/day_id.dart';
import 'drill_flow_screen.dart';
import 'paywall_screen.dart';
import 'profile_screen.dart';

class TodayDestinationData {
  final String? uid;
  final String firstName;
  final DailyPack pack;

  const TodayDestinationData({
    required this.uid,
    required this.firstName,
    required this.pack,
  });

  @override
  bool operator ==(Object other) =>
      other is TodayDestinationData &&
      other.uid == uid &&
      other.firstName == firstName &&
      other.pack == pack;

  @override
  int get hashCode => Object.hash(uid, firstName, pack);
}

class TodayScreen extends StatefulWidget {
  static const routeName = '/today';

  final String? uid;
  final List<String>? initialFocusAreas;
  final bool? initialCompleted;
  final bool loadRemote;
  final ValueChanged<TodayDestinationData>? onDestinationDataChanged;
  final VoidCallback? onOpenProfile;

  const TodayScreen({
    super.key,
    this.uid,
    this.initialFocusAreas,
    this.initialCompleted,
    this.loadRemote = true,
    this.onDestinationDataChanged,
    this.onOpenProfile,
  });

  const TodayScreen.preview({
    super.key,
    this.initialFocusAreas = const <String>['Product strategy'],
    this.initialCompleted = false,
  }) : uid = null,
       loadRemote = false,
       onDestinationDataChanged = null,
       onOpenProfile = null;

  @override
  State<TodayScreen> createState() => _TodayScreenState();
}

class _TodayScreenState extends State<TodayScreen> {
  late Future<_TodayState> _future;
  bool _openingPaywall = false;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<_TodayState> _load() async {
    final focusAreas = widget.initialFocusAreas;
    final completed = widget.initialCompleted;

    if (!widget.loadRemote) {
      return _TodayState(
        uid: widget.uid,
        firstName: 'Alex',
        focusAreas: focusAreas ?? const <String>[],
        entitlement: const EntitlementState.free(
          entitlementId: AppEnvironment.proEntitlementId,
          message: 'Preview mode',
        ),
        pack: _previewPack(
          focusAreas ?? const <String>[],
          completed: completed == true,
        ),
      );
    }

    final user = widget.uid == null
        ? await AuthService.instance.ensureSignedIn()
        : AuthService.instance.currentUser;
    final uid = widget.uid ?? user?.uid;

    if (uid == null) {
      return _TodayState(
        uid: null,
        firstName: 'there',
        focusAreas: focusAreas ?? const <String>[],
        entitlement: const EntitlementState.free(
          entitlementId: AppEnvironment.proEntitlementId,
          message: 'Signed out',
        ),
        pack: _previewPack(focusAreas ?? const <String>[]),
      );
    }

    try {
      await EntitlementService.instance.configure(appUserId: uid);
    } catch (_) {
      // Entitlements should not block a free curated daily pack.
    }

    final profile = await FirestoreService.instance.getProfile(uid);
    final profileFocusAreas =
        profile?.focusAreas ?? focusAreas ?? const <String>[];
    final entitlement = await EntitlementService.instance.currentState();
    final pack = await DailyPackService.instance.getOrCreateTodayPack(
      uid: uid,
      focusAreas: profileFocusAreas,
      allowAiGeneration: entitlement.isPro,
    );

    return _TodayState(
      uid: uid,
      firstName: _firstName(profile?.firstName, user?.displayName),
      focusAreas: pack.focusAreas.isEmpty ? profileFocusAreas : pack.focusAreas,
      entitlement: entitlement,
      pack: pack,
    );
  }

  DailyPack _previewPack(List<String> focusAreas, {bool completed = false}) {
    final now = DateTime.now();
    final items = DailyPackServicePreview.itemsFor(focusAreas);

    return DailyPack(
      dayId: dayIdFromDate(now),
      focusAreas: focusAreas,
      items: items,
      generatedAt: now,
      completedAt: completed ? now : null,
    );
  }

  String _firstName(String? profileName, String? displayName) {
    final profileFirstName = profileName?.trim();
    if (profileFirstName != null && profileFirstName.isNotEmpty) {
      return profileFirstName;
    }

    final trimmedDisplayName = displayName?.trim();
    if (trimmedDisplayName != null && trimmedDisplayName.isNotEmpty) {
      return trimmedDisplayName.split(RegExp(r'\s+')).first;
    }

    return 'there';
  }

  void _markCompleted(
    _TodayState state,
    List<String> completedItemIds,
    Map<String, String> answersByItemId,
  ) {
    final completedAt = DateTime.now();
    final allCompletedItemIds = <String>{
      ...completedItemIds,
      ...state.pack.items.map((item) => item.id),
    }.toList();

    setState(() {
      _future = Future.value(
        state.copyWith(
          pack: state.pack
              .copyWithProgress(
                completedItemIds: allCompletedItemIds,
                answersByItemId: answersByItemId,
              )
              .copyWithCompleted(completedAt),
        ),
      );
    });
  }

  Future<void> _openDailyPack(_TodayState state) async {
    if (state.uid != null) {
      unawaited(
        FirestoreService.instance
            .logEvent(
              uid: state.uid!,
              name: 'daily_pack_started',
              properties: <String, dynamic>{'dayId': state.pack.dayId},
            )
            .catchError((_) {}),
      );
    }

    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (context) => DrillFlowScreen(
          items: state.pack.items,
          dayId: state.pack.dayId,
          uid: state.uid,
          onCompleted: (completedItemIds, answersByItemId) =>
              _markCompleted(state, completedItemIds, answersByItemId),
        ),
      ),
    );
  }

  Future<void> _openPaywall() async {
    if (_openingPaywall) {
      return;
    }

    setState(() {
      _openingPaywall = true;
    });

    try {
      final entitlement = await Navigator.of(context).push<EntitlementState>(
        MaterialPageRoute(builder: (context) => const PaywallScreen()),
      );

      if (!mounted || entitlement == null) {
        return;
      }
      if (entitlement.isPro) {
        setState(() {
          _future = _load();
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _openingPaywall = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_TodayState>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(
            body: Center(child: Text('Preparing today’s ritual...')),
          );
        }

        if (snapshot.hasError) {
          return _TodayError(
            onRetry: () {
              setState(() {
                _future = _load();
              });
            },
          );
        }

        final state = snapshot.data;
        if (state == null) {
          return _TodayError(
            onRetry: () {
              setState(() {
                _future = _load();
              });
            },
          );
        }

        _notifyDestinationData(state);
        return _TodayContent(
          state: state,
          onStart: () => _openDailyPack(state),
          onOpenPaywall: _openPaywall,
          openingPaywall: _openingPaywall,
          onOpenProfile: widget.onOpenProfile ?? () => _pushProfile(state),
        );
      },
    );
  }

  void _notifyDestinationData(_TodayState state) {
    final callback = widget.onDestinationDataChanged;
    if (callback == null) {
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        callback(
          TodayDestinationData(
            uid: state.uid,
            firstName: state.firstName,
            pack: state.pack,
          ),
        );
      }
    });
  }

  void _pushProfile(_TodayState state) {
    Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (context) => ProfileScreen(
          uid: state.uid,
          firstName: state.firstName,
          pack: state.pack,
        ),
      ),
    );
  }
}

class _TodayError extends StatelessWidget {
  final VoidCallback onRetry;

  const _TodayError({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sivra')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Couldn’t load today’s ritual',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(
                'Check your connection and try again.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: onRetry,
                  child: const Text('Try again'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TodayContent extends StatelessWidget {
  final _TodayState state;
  final VoidCallback onStart;
  final VoidCallback onOpenPaywall;
  final bool openingPaywall;
  final VoidCallback onOpenProfile;

  const _TodayContent({
    required this.state,
    required this.onStart,
    required this.onOpenPaywall,
    required this.openingPaywall,
    required this.onOpenProfile,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final completed = state.pack.isCompleted;
    final themes = state.focusAreas.isEmpty
        ? const <String>['General AI fluency']
        : state.focusAreas;

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 84,
        titleSpacing: 20,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Good Morning',
              style: textTheme.bodyMedium?.copyWith(
                color: colors.onSurface.withValues(alpha: 0.64),
                letterSpacing: 0.2,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              state.firstName == 'there' ? 'Welcome' : state.firstName,
              style: textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w600,
                letterSpacing: -0.4,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Profile',
            onPressed: onOpenProfile,
            icon: CircleAvatar(
              radius: 16,
              child: Text(
                state.firstName == 'there'
                    ? 'S'
                    : state.firstName.characters.first.toUpperCase(),
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 44),
          children: [
            _DailyThought(
              dayId: state.pack.dayId,
              themes: themes,
              engine: const DailyThoughtEngine(),
            ),
            const SizedBox(height: 30),
            _RitualHeroCard(
              pack: state.pack,
              themes: themes,
              completed: completed,
              onStart: onStart,
            ),
            const SizedBox(height: 32),
            const _RitualStreakCard(),
            const SizedBox(height: 34),
            Text(
              'Today’s Themes',
              style: textTheme.titleSmall?.copyWith(
                color: colors.onSurface.withValues(alpha: 0.76),
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: themes
                  .map(
                    (theme) => Chip(
                      label: Text(_themeLabel(theme)),
                      backgroundColor: SivraColors.surface.withValues(
                        alpha: 0.4,
                      ),
                      side: BorderSide(
                        color: SivraColors.bronze.withValues(alpha: 0.13),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  )
                  .toList(),
            ),
            if (state.pack.learningProfile != null) ...[
              const SizedBox(height: 28),
              Text(
                'Personalization',
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                state.pack.learningProfile!.guidance,
                style: textTheme.bodyMedium?.copyWith(
                  height: 1.5,
                  color: colors.onSurface.withValues(alpha: 0.68),
                ),
              ),
            ],
            if (!state.entitlement.isPro) ...[
              const SizedBox(height: 38),
              _ProPrompt(onOpenPaywall: onOpenPaywall, opening: openingPaywall),
            ],
          ],
        ),
      ),
    );
  }

  static String _themeLabel(String value) {
    final normalized = value.trim().toLowerCase();
    if (normalized == 'infra & costs') {
      return 'Infrastructure & Costs';
    }
    return value
        .split(' ')
        .map(
          (word) => word.isEmpty
              ? word
              : '${word[0].toUpperCase()}${word.substring(1)}',
        )
        .join(' ');
  }
}

class _DailyThought extends StatelessWidget {
  final String dayId;
  final List<String> themes;
  final DailyThoughtEngine engine;

  const _DailyThought({
    required this.dayId,
    required this.themes,
    required this.engine,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final thought = engine.thoughtForDay(dayId: dayId, focusAreas: themes);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Today’s Thought',
            style: textTheme.labelSmall?.copyWith(
              color: SivraColors.bronze.withValues(alpha: 0.76),
              fontWeight: FontWeight.w500,
              letterSpacing: 0.6,
            ),
          ),
          const SizedBox(height: 9),
          Text(
            '“${thought.quote}”',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            softWrap: false,
            strutStyle: const StrutStyle(
              fontSize: 16,
              height: 1.5,
              forceStrutHeight: true,
            ),
            style: textTheme.titleMedium?.copyWith(
              color: SivraColors.bronze.withValues(alpha: 0.94),
              fontStyle: FontStyle.italic,
              fontWeight: FontWeight.w400,
              height: 1.5,
              letterSpacing: -0.1,
            ),
          ),
        ],
      ),
    );
  }
}

class _RitualHeroCard extends StatelessWidget {
  final DailyPack pack;
  final List<String> themes;
  final bool completed;
  final VoidCallback onStart;

  const _RitualHeroCard({
    required this.pack,
    required this.themes,
    required this.completed,
    required this.onStart,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final themeLabels = themes.take(2).map(_TodayContent._themeLabel).toList();

    return Container(
      constraints: const BoxConstraints(minHeight: 392),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            SivraColors.ritualGradientTop,
            SivraColors.surfaceSoft.withValues(alpha: 0.9),
            SivraColors.ritualGradientBottom,
          ],
          stops: const [0, 0.52, 1],
        ),
        border: Border.all(color: SivraColors.bronze.withValues(alpha: 0.16)),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.32),
            blurRadius: 40,
            spreadRadius: -7,
            offset: const Offset(0, 22),
          ),
          BoxShadow(
            color: SivraColors.ritualGradientBottom.withValues(alpha: 0.38),
            blurRadius: 12,
            spreadRadius: -6,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 30, 24, 22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'TODAY’S RITUAL',
              style: textTheme.labelLarge?.copyWith(
                color: SivraColors.bronze,
                fontWeight: FontWeight.w600,
                letterSpacing: 1.6,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              'Your thinking session is ready.',
              style: textTheme.titleMedium?.copyWith(
                color: SivraColors.warmIvory.withValues(alpha: 0.78),
                fontWeight: FontWeight.w400,
                height: 1.3,
              ),
            ),
            const SizedBox(height: 24),
            ...themeLabels.map(
              (theme) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  theme,
                  style: textTheme.headlineSmall?.copyWith(
                    color: SivraColors.warmIvory,
                    fontWeight: FontWeight.w500,
                    height: 1.15,
                    letterSpacing: -0.4,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 56),
            Text(
              'Today’s Investment',
              style: textTheme.labelSmall?.copyWith(
                color: SivraColors.mutedText.withValues(alpha: 0.78),
                fontWeight: FontWeight.w500,
                letterSpacing: 0.8,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              '7 Minutes',
              style: textTheme.titleLarge?.copyWith(
                color: SivraColors.warmIvory,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 7),
            Text(
              '${pack.briefingCount} Briefings  •  ${pack.drillCount} Drills',
              style: textTheme.bodyMedium?.copyWith(
                color: SivraColors.mutedText,
                letterSpacing: 0.1,
              ),
            ),
            const SizedBox(height: 24),
            Container(
              height: 1,
              color: SivraColors.bronze.withValues(alpha: 0.46),
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                key: const ValueKey('begin-ritual'),
                onPressed: onStart,
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(54),
                  backgroundColor: SivraColors.bronze,
                  foregroundColor: SivraColors.deepInk,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: Text(completed ? 'Review Ritual' : 'Begin Ritual'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RitualStreakCard extends StatelessWidget {
  const _RitualStreakCard();

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 15),
      decoration: BoxDecoration(
        color: SivraColors.surface.withValues(alpha: 0.62),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: SivraColors.bronze.withValues(alpha: 0.12)),
      ),
      child: Text(
        'Ritual Streak  •  Day 1',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: textTheme.titleSmall?.copyWith(
          color: SivraColors.warmIvory.withValues(alpha: 0.88),
          fontWeight: FontWeight.w500,
          letterSpacing: 0.1,
        ),
      ),
    );
  }
}

class _ProPrompt extends StatelessWidget {
  final VoidCallback onOpenPaywall;
  final bool opening;

  const _ProPrompt({required this.onOpenPaywall, required this.opening});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: opening ? null : onOpenPaywall,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          decoration: BoxDecoration(
            color: SivraColors.surface.withValues(alpha: 0.34),
            border: Border.all(
              color: SivraColors.bronze.withValues(alpha: 0.11),
            ),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(15, 12, 15, 11),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Sivra Pro',
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Personalized Daily Rituals\n'
                  'Thinking Archive\n'
                  'Weekly Recaps',
                  style: textTheme.bodyMedium?.copyWith(
                    height: 1.34,
                    color: colors.onSurface.withValues(alpha: 0.82),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      opening ? 'Opening…' : 'Learn More',
                      style: textTheme.labelLarge?.copyWith(
                        color: SivraColors.bronze,
                      ),
                    ),
                    if (!opening) ...[
                      const SizedBox(width: 6),
                      const Icon(
                        Icons.arrow_forward,
                        size: 16,
                        color: SivraColors.bronze,
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TodayState {
  final String? uid;
  final String firstName;
  final List<String> focusAreas;
  final EntitlementState entitlement;
  final DailyPack pack;

  const _TodayState({
    required this.uid,
    required this.firstName,
    required this.focusAreas,
    required this.entitlement,
    required this.pack,
  });

  _TodayState copyWith({DailyPack? pack, EntitlementState? entitlement}) {
    return _TodayState(
      uid: uid,
      firstName: firstName,
      focusAreas: focusAreas,
      entitlement: entitlement ?? this.entitlement,
      pack: pack ?? this.pack,
    );
  }
}

class DailyPackServicePreview {
  static List<DrillItem> itemsFor(List<String> focusAreas) {
    return MockDailyPack.forFocus(focusAreas);
  }
}
