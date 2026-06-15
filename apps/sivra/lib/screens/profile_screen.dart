import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../config/app_environment.dart';
import '../design/sivra_colors.dart';
import '../models/daily_pack.dart';
import '../navigation/app_destination.dart';
import '../services/debug_onboarding_override.dart';
import '../services/firestore_service.dart';
import 'bootstrap_screen.dart';
import 'content_qa_screen.dart';
import 'diagnostics_screen.dart';
import 'history_screen.dart';
import 'learning_memory_screen.dart';
import 'onboarding_screen.dart';
import 'paywall_screen.dart';
import 'source_trust_admin_screen.dart';
import 'weekly_recap_screen.dart';

class ProfileScreen extends StatefulWidget {
  final String? uid;
  final String firstName;
  final DailyPack pack;
  final List<String>? initialThinkingRoles;
  final bool? showDeveloperTools;
  final ValueChanged<AppDestination>? onSelectDestination;
  final Future<List<String>> Function()? loadThinkingRoles;
  final Future<void> Function(
    List<String> thinkingRoles,
    List<String> focusAreas,
  )?
  onSaveFocusAreas;
  final Future<void> Function()? onResetOnboarding;
  final Future<void> Function(BuildContext context)? onResetOnboardingComplete;

  const ProfileScreen({
    super.key,
    required this.uid,
    required this.firstName,
    required this.pack,
    this.initialThinkingRoles,
    this.showDeveloperTools,
    this.onSelectDestination,
    this.loadThinkingRoles,
    this.onSaveFocusAreas,
    this.onResetOnboarding,
    this.onResetOnboardingComplete,
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late List<String> _thinkingRoles;
  late List<String> _focusAreas;

  @override
  void initState() {
    super.initState();
    _focusAreas = List<String>.of(widget.pack.focusAreas);
    _thinkingRoles =
        widget.initialThinkingRoles ??
        ThinkingFocus.rolesForFocusAreas(widget.pack.focusAreas);
    _refreshThinkingRoles();
  }

  Future<void> _refreshThinkingRoles() async {
    final loader = widget.loadThinkingRoles;
    if (loader == null && widget.uid == null) {
      return;
    }

    try {
      final profile = loader == null
          ? await FirestoreService.instance.getProfile(widget.uid!)
          : null;
      final roles =
          profile?.thinkingRoles ?? await loader?.call() ?? const <String>[];
      if (!mounted) {
        return;
      }
      setState(() {
        if (roles.isNotEmpty) {
          _thinkingRoles = roles.take(3).toList();
        }
        if (profile != null) {
          _focusAreas = List<String>.of(profile.focusAreas);
        }
      });
    } catch (_) {
      // The profile remains useful with the focus areas from today's pack.
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final developerToolsVisible =
        widget.showDeveloperTools ?? AppEnvironment.developerToolsEnabled;

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 28,
                  child: Text(_initialFor(widget.firstName)),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.firstName == 'there'
                            ? 'Your profile'
                            : widget.firstName,
                        style: textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _focusAreaCountLabel(_focusAreas.length),
                        style: textTheme.bodySmall?.copyWith(
                          color: SivraColors.mutedText,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 28),
            Text('Thinking Profile', style: textTheme.titleMedium),
            const SizedBox(height: 8),
            _ThinkingProfileCard(
              roles: _thinkingRoles,
              onEdit: () => _editFocusAreas(context),
            ),
            const SizedBox(height: 18),
            Text('Your thinking system', style: textTheme.titleMedium),
            const SizedBox(height: 8),
            _ProfileAction(
              icon: Icons.history_edu_outlined,
              title: 'Thinking Archive',
              subtitle: 'Revisit the ideas and decisions you chose to keep.',
              onTap: () => _openDestination(
                context,
                AppDestination.archive,
                LearningMemoryScreen(
                  uid: widget.uid,
                  previewPacks: widget.uid == null
                      ? <DailyPack>[widget.pack]
                      : null,
                ),
              ),
            ),
            _ProfileAction(
              icon: Icons.calendar_month_outlined,
              title: 'History',
              subtitle: 'Revisit previous packs and practice again.',
              onTap: () => _push(
                context,
                HistoryScreen(
                  uid: widget.uid,
                  previewPacks: widget.uid == null
                      ? <DailyPack>[widget.pack]
                      : null,
                ),
              ),
            ),
            _ProfileAction(
              icon: Icons.insights_outlined,
              title: 'Weekly Recap',
              subtitle:
                  'Reflect on the themes and ideas that shaped your week.',
              onTap: () => _openDestination(
                context,
                AppDestination.recap,
                WeeklyRecapScreen(
                  uid: widget.uid,
                  previewPacks: widget.uid == null
                      ? <DailyPack>[widget.pack]
                      : null,
                ),
              ),
            ),
            const SizedBox(height: 28),
            Text('Manage', style: textTheme.titleMedium),
            const SizedBox(height: 8),
            _ProfileAction(
              icon: Icons.workspace_premium_outlined,
              title: 'Subscription',
              subtitle: 'Review Sivra Pro and manage your plan.',
              onTap: () => _push(context, const PaywallScreen()),
            ),
            _ProfileAction(
              icon: Icons.support_agent_outlined,
              title: 'Support',
              subtitle: 'Get help with Sivra.',
              onTap: () => _showComingSoon(context, 'Support'),
            ),
            if (developerToolsVisible) ...[
              const SizedBox(height: 28),
              Text('Developer tools', style: textTheme.titleMedium),
              const SizedBox(height: 8),
              _ProfileAction(
                icon: Icons.fact_check_outlined,
                title: 'Content QA',
                subtitle: 'Inspect pack quality, warnings, and sources.',
                onTap: () => _push(context, ContentQaScreen(pack: widget.pack)),
              ),
              _ProfileAction(
                icon: Icons.admin_panel_settings_outlined,
                title: 'Source Admin',
                subtitle: 'Audit source trust and fallback usage.',
                onTap: () => _push(
                  context,
                  SourceTrustAdminScreen(
                    uid: widget.uid,
                    previewPacks: widget.uid == null
                        ? <DailyPack>[widget.pack]
                        : null,
                  ),
                ),
              ),
              _ProfileAction(
                icon: Icons.bug_report_outlined,
                title: 'Diagnostics',
                subtitle: 'Review build and service configuration.',
                onTap: () => _push(context, DiagnosticsScreen(uid: widget.uid)),
              ),
              if (kDebugMode)
                _ProfileAction(
                  icon: Icons.restart_alt_rounded,
                  title: 'Reset Onboarding',
                  subtitle:
                      'Debug only. Shows onboarding again without changing '
                      'your profile.',
                  onTap: () => _resetOnboarding(context),
                ),
            ],
          ],
        ),
      ),
    );
  }

  void _openDestination(
    BuildContext context,
    AppDestination destination,
    Widget fallbackScreen,
  ) {
    final selectDestination = widget.onSelectDestination;
    if (selectDestination != null) {
      selectDestination(destination);
      return;
    }
    _push(context, fallbackScreen);
  }

  static String _initialFor(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty || trimmed == 'there') {
      return 'S';
    }
    return trimmed.characters.first.toUpperCase();
  }

  static String _focusAreaCountLabel(int count) {
    final noun = count == 1 ? 'Focus Area' : 'Focus Areas';
    return '$count $noun Selected';
  }

  static void _push(BuildContext context, Widget screen) {
    Navigator.of(
      context,
    ).push<void>(MaterialPageRoute(builder: (context) => screen));
  }

  static void _showComingSoon(BuildContext context, String destination) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$destination will be available here soon.')),
    );
  }

  Future<void> _editFocusAreas(BuildContext context) async {
    final updatedRoles = await Navigator.of(context).push<List<String>>(
      MaterialPageRoute(
        builder: (context) => _FocusAreaEditorScreen(
          initialRoles: _thinkingRoles,
          onSave: _saveFocusAreas,
        ),
      ),
    );

    if (!mounted || updatedRoles == null) {
      return;
    }
    setState(() {
      _thinkingRoles = updatedRoles;
      _focusAreas = ThinkingFocus.focusAreasForRoles(updatedRoles);
    });
  }

  Future<void> _saveFocusAreas(List<String> thinkingRoles) async {
    final focusAreas = ThinkingFocus.focusAreasForRoles(thinkingRoles);
    final save = widget.onSaveFocusAreas;
    if (save != null) {
      await save(thinkingRoles, focusAreas);
      return;
    }

    final uid = widget.uid;
    if (uid == null) {
      return;
    }
    await FirestoreService.instance.updateFocusAreas(
      uid: uid,
      focusAreas: focusAreas,
      thinkingRoles: thinkingRoles,
    );
  }

  Future<void> _resetOnboarding(BuildContext context) async {
    if (widget.uid == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Onboarding reset requires a signed-in user.'),
        ),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset onboarding?'),
        content: const Text(
          'This stores a local debug override for the current user and '
          'restarts the app flow. Your profile, authentication, and RevenueCat '
          'entitlements are not changed.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Reset'),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) {
      return;
    }

    final messenger = ScaffoldMessenger.of(context);
    try {
      final reset = widget.onResetOnboarding;
      if (reset != null) {
        await reset();
      } else {
        await DebugOnboardingOverride.enableFor(widget.uid!);
      }
    } catch (_) {
      if (!context.mounted) {
        return;
      }
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Unable to reset onboarding for this user.'),
        ),
      );
      return;
    }

    if (!context.mounted) {
      return;
    }

    final completeReset = widget.onResetOnboardingComplete;
    if (completeReset != null) {
      await completeReset(context);
      return;
    }

    await Navigator.of(context).pushAndRemoveUntil<void>(
      MaterialPageRoute(builder: (context) => const BootstrapScreen()),
      (route) => false,
    );
  }
}

class _ThinkingProfileCard extends StatelessWidget {
  final List<String> roles;
  final VoidCallback onEdit;

  const _ThinkingProfileCard({required this.roles, required this.onEdit});

  @override
  Widget build(BuildContext context) {
    final visibleRoles = roles.isEmpty
        ? const <String>['Founder']
        : roles.take(3).toList();

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ...visibleRoles.map(
              (role) => Padding(
                padding: const EdgeInsets.only(bottom: 9),
                child: Row(
                  children: [
                    const Icon(
                      Icons.check_rounded,
                      size: 18,
                      color: SivraColors.bronze,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      ThinkingFocus.displayName(role),
                      style: const TextStyle(
                        color: SivraColors.warmIvory,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const Divider(height: 20),
            TextButton.icon(
              key: const ValueKey('edit-focus-areas'),
              onPressed: onEdit,
              style: TextButton.styleFrom(
                foregroundColor: SivraColors.bronze,
                padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 8),
              ),
              icon: const Icon(Icons.tune_rounded, size: 20),
              label: const Text(
                'Edit Focus Areas',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FocusAreaEditorScreen extends StatefulWidget {
  final List<String> initialRoles;
  final Future<void> Function(List<String> thinkingRoles) onSave;

  const _FocusAreaEditorScreen({
    required this.initialRoles,
    required this.onSave,
  });

  @override
  State<_FocusAreaEditorScreen> createState() => _FocusAreaEditorScreenState();
}

class _FocusAreaEditorScreenState extends State<_FocusAreaEditorScreen> {
  final Set<String> _selectedRoles = <String>{};
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _selectedRoles.addAll(widget.initialRoles.take(3));
  }

  void _setSelected(String role, bool selected) {
    setState(() {
      if (selected) {
        if (_selectedRoles.length < 3) {
          _selectedRoles.add(role);
        }
      } else {
        _selectedRoles.remove(role);
      }
    });
  }

  Future<void> _save() async {
    if (_saving || _selectedRoles.isEmpty) {
      return;
    }

    setState(() {
      _saving = true;
    });

    final roles = _selectedRoles.toList();
    try {
      await widget.onSave(roles);
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _saving = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unable to update your focus areas. Please try again.'),
        ),
      );
      return;
    }

    if (mounted) {
      Navigator.of(context).pop(roles);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SivraColors.deepInk,
      appBar: AppBar(
        title: const Text('Edit Focus Areas'),
        backgroundColor: SivraColors.deepInk,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          child: Column(
            children: [
              Expanded(
                child: FocusAreaSelector(
                  selected: _selectedRoles,
                  onChanged: _setSelected,
                ),
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  key: const ValueKey('save-focus-areas'),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(58),
                    backgroundColor: SivraColors.bronze,
                    foregroundColor: SivraColors.deepInk,
                    disabledBackgroundColor: SivraColors.bronze.withValues(
                      alpha: 0.28,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(22),
                    ),
                    textStyle: Theme.of(context).textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  onPressed: !_saving && _selectedRoles.isNotEmpty
                      ? _save
                      : null,
                  child: Text(_saving ? 'Saving...' : 'Save Focus Areas'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProfileAction extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ProfileAction({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        key: ValueKey('profile-action-$title'),
        leading: Icon(icon),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
