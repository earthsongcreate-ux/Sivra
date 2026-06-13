import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../config/app_environment.dart';
import '../services/auth_service.dart';
import '../services/debug_onboarding_override.dart';
import '../services/firestore_service.dart';
import 'bootstrap_screen.dart';

class DiagnosticsScreen extends StatefulWidget {
  final String? uid;

  const DiagnosticsScreen({super.key, this.uid});

  @override
  State<DiagnosticsScreen> createState() => _DiagnosticsScreenState();
}

class _DiagnosticsScreenState extends State<DiagnosticsScreen> {
  late Future<_StartupDiagnosticsState> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<_StartupDiagnosticsState> _load() async {
    final authUid = widget.uid ?? AuthService.instance.currentUser?.uid;
    if (authUid == null) {
      return const _StartupDiagnosticsState();
    }

    final forceOnboarding = await DebugOnboardingOverride.isEnabledFor(authUid);
    final profile = await FirestoreService.instance.getProfile(authUid);

    return _StartupDiagnosticsState(
      uid: authUid,
      hasProfile: profile != null,
      focusAreas: profile?.focusAreas ?? const <String>[],
      onboardingVersion: profile?.onboardingVersion,
      forceOnboarding: forceOnboarding,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Diagnostics')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
          children: [
            const _DiagnosticRow(
              label: 'Build channel',
              value: AppEnvironment.buildChannel,
            ),
            const _DiagnosticRow(
              label: 'AI endpoint',
              value: AppEnvironment.aiPackEndpoint,
              emptyValue: 'Not configured',
            ),
            const _DiagnosticRow(
              label: 'AI authentication',
              value: 'Firebase ID token',
            ),
            const _DiagnosticRow(
              label: 'Diagnostics',
              value: AppEnvironment.diagnosticsEnabled ? 'Enabled' : 'Disabled',
            ),
            _DiagnosticRow(
              label: 'RevenueCat',
              value: AppEnvironment.revenueCatConfigured
                  ? 'Configured'
                  : 'Not configured',
            ),
            const _DiagnosticRow(
              label: 'Pro entitlement',
              value: AppEnvironment.proEntitlementId,
            ),
            const _DiagnosticRow(
              label: 'Monthly product',
              value: AppEnvironment.monthlyProductId,
            ),
            const _DiagnosticRow(
              label: 'Annual product',
              value: AppEnvironment.annualProductId,
            ),
            if (kDebugMode) ...[
              const SizedBox(height: 16),
              FutureBuilder<_StartupDiagnosticsState>(
                future: _future,
                builder: (context, snapshot) {
                  final state =
                      snapshot.data ?? const _StartupDiagnosticsState();
                  return Column(
                    children: [
                      _DiagnosticRow(
                        label: 'Startup auth uid',
                        value: state.uid ?? 'Signed out',
                      ),
                      _DiagnosticRow(
                        label: 'Startup profile',
                        value: state.hasProfile ? 'Present' : 'Missing',
                      ),
                      _DiagnosticRow(
                        label: 'Startup focus areas',
                        value: state.focusAreas.isEmpty
                            ? 'None'
                            : state.focusAreas.join(', '),
                      ),
                      _DiagnosticRow(
                        label: 'Startup onboarding version',
                        value: state.onboardingVersion?.toString() ?? 'None',
                      ),
                      _DiagnosticRow(
                        label: 'Force onboarding override',
                        value: state.forceOnboarding ? 'Enabled' : 'Disabled',
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          onPressed: state.uid == null
                              ? null
                              : () => _resetOnboarding(context, state.uid!),
                          child: const Text('Reset onboarding for this user'),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _resetOnboarding(BuildContext context, String uid) async {
    await DebugOnboardingOverride.enableFor(uid);
    if (!context.mounted) {
      return;
    }

    await Navigator.of(context).pushAndRemoveUntil<void>(
      MaterialPageRoute(builder: (context) => const BootstrapScreen()),
      (route) => false,
    );
  }
}

class _StartupDiagnosticsState {
  final String? uid;
  final bool hasProfile;
  final List<String> focusAreas;
  final int? onboardingVersion;
  final bool forceOnboarding;

  const _StartupDiagnosticsState({
    this.uid,
    this.hasProfile = false,
    this.focusAreas = const <String>[],
    this.onboardingVersion,
    this.forceOnboarding = false,
  });
}

class _DiagnosticRow extends StatelessWidget {
  final String label;
  final String value;
  final String emptyValue;

  const _DiagnosticRow({
    required this.label,
    required this.value,
    this.emptyValue = '',
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final displayValue = value.trim().isEmpty ? emptyValue : value;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border.all(color: colors.onSurface.withValues(alpha: 0.14)),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 4),
              Text(
                displayValue,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: colors.onSurface.withValues(alpha: 0.72),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
