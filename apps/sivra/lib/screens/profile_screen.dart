import 'package:flutter/material.dart';

import '../config/app_environment.dart';
import '../models/daily_pack.dart';
import '../navigation/app_destination.dart';
import 'content_qa_screen.dart';
import 'diagnostics_screen.dart';
import 'history_screen.dart';
import 'learning_memory_screen.dart';
import 'paywall_screen.dart';
import 'source_trust_admin_screen.dart';
import 'weekly_recap_screen.dart';

class ProfileScreen extends StatelessWidget {
  final String? uid;
  final String firstName;
  final DailyPack pack;
  final bool? showDeveloperTools;
  final ValueChanged<AppDestination>? onSelectDestination;

  const ProfileScreen({
    super.key,
    required this.uid,
    required this.firstName,
    required this.pack,
    this.showDeveloperTools,
    this.onSelectDestination,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final developerToolsVisible =
        showDeveloperTools ?? AppEnvironment.developerToolsEnabled;

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
          children: [
            Row(
              children: [
                CircleAvatar(radius: 28, child: Text(_initialFor(firstName))),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    firstName == 'there' ? 'Your profile' : firstName,
                    style: textTheme.headlineSmall,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 28),
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
                  uid: uid,
                  previewPacks: uid == null ? <DailyPack>[pack] : null,
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
                  uid: uid,
                  previewPacks: uid == null ? <DailyPack>[pack] : null,
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
                  uid: uid,
                  previewPacks: uid == null ? <DailyPack>[pack] : null,
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
              icon: Icons.center_focus_strong_outlined,
              title: 'Focus Areas',
              subtitle: 'Review the themes shaping your daily ritual.',
              onTap: () => _showComingSoon(context, 'Focus Areas'),
            ),
            _ProfileAction(
              icon: Icons.settings_outlined,
              title: 'Settings',
              subtitle: 'Manage your Sivra experience.',
              onTap: () => _showComingSoon(context, 'Settings'),
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
                onTap: () => _push(context, ContentQaScreen(pack: pack)),
              ),
              _ProfileAction(
                icon: Icons.admin_panel_settings_outlined,
                title: 'Source Admin',
                subtitle: 'Audit source trust and fallback usage.',
                onTap: () => _push(
                  context,
                  SourceTrustAdminScreen(
                    uid: uid,
                    previewPacks: uid == null ? <DailyPack>[pack] : null,
                  ),
                ),
              ),
              _ProfileAction(
                icon: Icons.bug_report_outlined,
                title: 'Diagnostics',
                subtitle: 'Review build and service configuration.',
                onTap: () => _push(context, const DiagnosticsScreen()),
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
    final selectDestination = onSelectDestination;
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
        leading: Icon(icon),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
