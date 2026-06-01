import 'package:flutter/material.dart';

import '../config/app_environment.dart';

class DiagnosticsScreen extends StatelessWidget {
  const DiagnosticsScreen({super.key});

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
          ],
        ),
      ),
    );
  }
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
