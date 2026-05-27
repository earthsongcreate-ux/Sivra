import 'dart:async';

import 'package:flutter/material.dart';

import '../data/mock_daily_pack.dart';
import '../models/daily_pack.dart';
import '../models/drill_item.dart';
import '../models/entitlement_state.dart';
import '../config/app_environment.dart';
import '../services/auth_service.dart';
import '../services/daily_pack_service.dart';
import '../services/entitlement_service.dart';
import '../services/firestore_service.dart';
import '../utils/day_id.dart';
import 'content_qa_screen.dart';
import 'diagnostics_screen.dart';
import 'drill_flow_screen.dart';
import 'history_screen.dart';
import 'learning_memory_screen.dart';
import 'paywall_screen.dart';
import 'source_trust_admin_screen.dart';
import 'weekly_recap_screen.dart';

class TodayScreen extends StatefulWidget {
  static const routeName = '/today';

  final String? uid;
  final List<String>? initialFocusAreas;
  final bool? initialCompleted;
  final bool loadRemote;

  const TodayScreen({
    super.key,
    this.uid,
    this.initialFocusAreas,
    this.initialCompleted,
    this.loadRemote = true,
  });

  const TodayScreen.preview({
    super.key,
    this.initialFocusAreas = const <String>['Product strategy'],
    this.initialCompleted = false,
  }) : uid = null,
       loadRemote = false;

  @override
  State<TodayScreen> createState() => _TodayScreenState();
}

class _TodayScreenState extends State<TodayScreen> {
  late Future<_TodayState> _future;

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
    final entitlement = await Navigator.of(context).push<EntitlementState>(
      MaterialPageRoute(builder: (context) => const PaywallScreen()),
    );

    if (!mounted || entitlement?.isPro != true) {
      return;
    }

    setState(() {
      _future = _load();
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_TodayState>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(
            body: Center(child: Text('Preparing today’s pack...')),
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

        return _TodayContent(
          state: state,
          onStart: () => _openDailyPack(state),
          onOpenPaywall: _openPaywall,
          onReviewQa: () {
            Navigator.of(context).push<void>(
              MaterialPageRoute(
                builder: (context) => ContentQaScreen(pack: state.pack),
              ),
            );
          },
          onOpenMemory: () {
            Navigator.of(context).push<void>(
              MaterialPageRoute(
                builder: (context) => LearningMemoryScreen(pack: state.pack),
              ),
            );
          },
          onOpenHistory: () {
            Navigator.of(context).push<void>(
              MaterialPageRoute(
                builder: (context) => HistoryScreen(uid: state.uid),
              ),
            );
          },
          onOpenRecap: () {
            Navigator.of(context).push<void>(
              MaterialPageRoute(
                builder: (context) => WeeklyRecapScreen(uid: state.uid),
              ),
            );
          },
          onOpenSourceAdmin: () {
            Navigator.of(context).push<void>(
              MaterialPageRoute(
                builder: (context) => SourceTrustAdminScreen(uid: state.uid),
              ),
            );
          },
          onOpenDiagnostics: () {
            Navigator.of(context).push<void>(
              MaterialPageRoute(
                builder: (context) => const DiagnosticsScreen(),
              ),
            );
          },
        );
      },
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
                'Couldn’t load today’s pack',
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
  final VoidCallback onReviewQa;
  final VoidCallback onOpenMemory;
  final VoidCallback onOpenHistory;
  final VoidCallback onOpenRecap;
  final VoidCallback onOpenSourceAdmin;
  final VoidCallback onOpenDiagnostics;

  const _TodayContent({
    required this.state,
    required this.onStart,
    required this.onOpenPaywall,
    required this.onReviewQa,
    required this.onOpenMemory,
    required this.onOpenHistory,
    required this.onOpenRecap,
    required this.onOpenSourceAdmin,
    required this.onOpenDiagnostics,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final completed = state.pack.isCompleted;
    final focusLabel = state.focusAreas.isEmpty
        ? 'General AI fluency'
        : state.focusAreas.join(' / ');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sivra'),
        actions: [
          IconButton(
            tooltip: 'Content QA',
            icon: const Icon(Icons.fact_check_outlined),
            onPressed: onReviewQa,
          ),
          IconButton(
            tooltip: 'Learning Memory',
            icon: const Icon(Icons.history_edu_outlined),
            onPressed: onOpenMemory,
          ),
          IconButton(
            tooltip: 'History',
            icon: const Icon(Icons.calendar_month_outlined),
            onPressed: onOpenHistory,
          ),
          IconButton(
            tooltip: 'Weekly Recap',
            icon: const Icon(Icons.insights_outlined),
            onPressed: onOpenRecap,
          ),
          IconButton(
            tooltip: 'Source Admin',
            icon: const Icon(Icons.admin_panel_settings_outlined),
            onPressed: onOpenSourceAdmin,
          ),
          if (AppEnvironment.diagnosticsEnabled)
            IconButton(
              tooltip: 'Diagnostics',
              icon: const Icon(Icons.bug_report_outlined),
              onPressed: onOpenDiagnostics,
            ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
          child: Column(
            children: [
              Expanded(
                child: ListView(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Today’s Pack',
                            style: textTheme.headlineMedium,
                          ),
                        ),
                        _StatusPill(completed: completed),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      focusLabel,
                      style: textTheme.bodyMedium?.copyWith(
                        color: colors.onSurface.withValues(alpha: 0.72),
                      ),
                    ),
                    const SizedBox(height: 24),
                    DecoratedBox(
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: colors.onSurface.withValues(alpha: 0.18),
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              completed ? 'Completed today' : 'Ready for today',
                              style: textTheme.titleLarge,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '${state.pack.items.length} screens • ${state.pack.briefingCount} briefings • ${state.pack.drillCount} drills',
                              style: textTheme.bodyMedium?.copyWith(
                                color: colors.onSurface.withValues(alpha: 0.72),
                              ),
                            ),
                            const SizedBox(height: 16),
                            LinearProgressIndicator(
                              value: state.pack.items.isEmpty
                                  ? 0
                                  : state.pack.completedItemCount /
                                        state.pack.items.length,
                              minHeight: 6,
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _MetricTile(
                            label: 'Progress',
                            value:
                                '${state.pack.completedItemCount}/${state.pack.items.length}',
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _MetricTile(
                            label: 'Answers',
                            value: '${state.pack.writtenAnswerCount}',
                          ),
                        ),
                      ],
                    ),
                    if (!state.entitlement.isPro) ...[
                      const SizedBox(height: 16),
                      _ProPrompt(onOpenPaywall: onOpenPaywall),
                    ],
                    const SizedBox(height: 20),
                    if (state.pack.learningProfile != null) ...[
                      Text('Personalization', style: textTheme.titleMedium),
                      const SizedBox(height: 8),
                      DecoratedBox(
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: colors.onSurface.withValues(alpha: 0.14),
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Text(
                            state.pack.learningProfile!.guidance,
                            style: textTheme.bodyMedium?.copyWith(
                              color: colors.onSurface.withValues(alpha: 0.78),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                    Text('Focus areas', style: textTheme.titleMedium),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children:
                          (state.focusAreas.isEmpty
                                  ? const <String>['General AI fluency']
                                  : state.focusAreas)
                              .map((focus) => Chip(label: Text(focus)))
                              .toList(),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: onStart,
                  child: Text(completed ? 'Review pack' : 'Start pack'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MetricTile extends StatelessWidget {
  final String label;
  final String value;

  const _MetricTile({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border.all(color: colors.onSurface.withValues(alpha: 0.14)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(value, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 4),
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: colors.onSurface.withValues(alpha: 0.72),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProPrompt extends StatelessWidget {
  final VoidCallback onOpenPaywall;

  const _ProPrompt({required this.onOpenPaywall});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border.all(color: colors.primary.withValues(alpha: 0.42)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Icon(Icons.auto_awesome_outlined, color: colors.primary),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Sivra Pro', style: textTheme.titleMedium),
                  const SizedBox(height: 4),
                  Text(
                    'Start a 7-day trial for AI-generated packs.',
                    style: textTheme.bodySmall?.copyWith(
                      color: colors.onSurface.withValues(alpha: 0.72),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            FilledButton(onPressed: onOpenPaywall, child: const Text('Go Pro')),
          ],
        ),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  final bool completed;

  const _StatusPill({required this.completed});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: completed
            ? colors.primary.withValues(alpha: 0.18)
            : colors.onSurface.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: Text(
          completed ? 'Done' : 'Open',
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
            color: completed ? colors.primary : colors.onSurface,
          ),
        ),
      ),
    );
  }
}

class _TodayState {
  final String? uid;
  final List<String> focusAreas;
  final EntitlementState entitlement;
  final DailyPack pack;

  const _TodayState({
    required this.uid,
    required this.focusAreas,
    required this.entitlement,
    required this.pack,
  });

  _TodayState copyWith({DailyPack? pack, EntitlementState? entitlement}) {
    return _TodayState(
      uid: uid,
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
