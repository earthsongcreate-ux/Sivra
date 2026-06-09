import 'package:flutter/material.dart';

import '../design/sivra_colors.dart';
import '../models/daily_pack.dart';
import '../navigation/app_destination.dart';
import 'learning_memory_screen.dart';
import 'profile_screen.dart';
import 'today_screen.dart';
import 'weekly_recap_screen.dart';

class AppShell extends StatefulWidget {
  static const routeName = '/app';

  final String? uid;
  final List<String>? initialFocusAreas;
  final bool loadRemote;
  final AppDestination initialDestination;

  const AppShell({
    super.key,
    this.uid,
    this.initialFocusAreas,
    this.loadRemote = true,
    this.initialDestination = AppDestination.today,
  });

  const AppShell.preview({
    super.key,
    this.initialFocusAreas = const <String>['Product strategy'],
    this.initialDestination = AppDestination.today,
  }) : uid = null,
       loadRemote = false;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> with RestorationMixin {
  late final RestorableInt _selectedIndex;
  TodayDestinationData? _todayData;

  @override
  String? get restorationId => 'sivra_app_shell';

  @override
  void restoreState(RestorationBucket? oldBucket, bool initialRestore) {
    registerForRestoration(_selectedIndex, 'selected_destination');
  }

  @override
  void initState() {
    super.initState();
    _selectedIndex = RestorableInt(widget.initialDestination.index);
  }

  @override
  void dispose() {
    _selectedIndex.dispose();
    super.dispose();
  }

  void _select(AppDestination destination) {
    if (_selectedIndex.value == destination.index) {
      return;
    }
    setState(() {
      _selectedIndex.value = destination.index;
    });
  }

  void _updateTodayData(TodayDestinationData data) {
    if (_todayData == data || !mounted) {
      return;
    }
    setState(() {
      _todayData = data;
    });
  }

  @override
  Widget build(BuildContext context) {
    final data = _todayData;
    final previewPacks = !widget.loadRemote && data != null
        ? <DailyPack>[data.pack]
        : null;

    final destinations = <Widget>[
      TodayScreen(
        uid: widget.uid,
        initialFocusAreas: widget.initialFocusAreas,
        loadRemote: widget.loadRemote,
        onDestinationDataChanged: _updateTodayData,
        onOpenProfile: () => _select(AppDestination.profile),
      ),
      LearningMemoryScreen(
        key: ValueKey('archive-${data?.pack.dayId ?? 'loading'}'),
        uid: data?.uid ?? widget.uid,
        previewPacks: previewPacks,
        onReturnToRitual: () => _select(AppDestination.today),
      ),
      WeeklyRecapScreen(
        key: ValueKey('recap-${data?.pack.dayId ?? 'loading'}'),
        uid: data?.uid ?? widget.uid,
        previewPacks: previewPacks,
      ),
      data == null
          ? const _ProfileLoading()
          : ProfileScreen(
              uid: data.uid,
              firstName: data.firstName,
              pack: data.pack,
              onSelectDestination: _select,
            ),
    ];

    return Scaffold(
      extendBody: false,
      body: IndexedStack(index: _selectedIndex.value, children: destinations),
      bottomNavigationBar: _SivraBottomNavigation(
        selected: AppDestination.values[_selectedIndex.value],
        onSelected: _select,
      ),
    );
  }
}

class _ProfileLoading extends StatelessWidget {
  const _ProfileLoading();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: const Center(child: Text('Preparing your profile...')),
    );
  }
}

class _SivraBottomNavigation extends StatelessWidget {
  final AppDestination selected;
  final ValueChanged<AppDestination> onSelected;

  const _SivraBottomNavigation({
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [SivraColors.surfaceSoft, SivraColors.deepInk],
        ),
        border: Border(
          top: BorderSide(color: SivraColors.bronze.withValues(alpha: 0.16)),
        ),
      ),
      child: SafeArea(
        top: false,
        minimum: const EdgeInsets.fromLTRB(10, 7, 10, 7),
        child: SizedBox(
          height: 58,
          child: Row(
            children: AppDestination.values
                .map(
                  (destination) => Expanded(
                    child: _NavigationItem(
                      destination: destination,
                      selected: destination == selected,
                      onTap: () => onSelected(destination),
                    ),
                  ),
                )
                .toList(),
          ),
        ),
      ),
    );
  }
}

class _NavigationItem extends StatelessWidget {
  final AppDestination destination;
  final bool selected;
  final VoidCallback onTap;

  const _NavigationItem({
    required this.destination,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = selected
        ? SivraColors.bronze
        : SivraColors.warmIvory.withValues(alpha: 0.46);

    return Semantics(
      selected: selected,
      button: true,
      label: destination.label,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          key: ValueKey('nav-${destination.name}'),
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOut,
            margin: EdgeInsets.only(
              top: selected ? 0 : 4,
              bottom: selected ? 4 : 0,
            ),
            decoration: BoxDecoration(
              color: selected
                  ? SivraColors.bronze.withValues(alpha: 0.09)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(18),
              border: selected
                  ? Border.all(
                      color: SivraColors.bronze.withValues(alpha: 0.18),
                    )
                  : null,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(destination.icon, size: 20, color: color),
                const SizedBox(height: 3),
                Text(
                  destination.label,
                  maxLines: 1,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: color,
                    fontSize: 10.5,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                    letterSpacing: 0.2,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
