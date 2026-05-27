import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

import '../config/app_environment.dart';
import '../models/entitlement_state.dart';
import '../services/entitlement_service.dart';

class PaywallScreen extends StatefulWidget {
  const PaywallScreen({super.key});

  @override
  State<PaywallScreen> createState() => _PaywallScreenState();
}

class _PaywallScreenState extends State<PaywallScreen> {
  late Future<List<Package>> _future;
  Package? _busyPackage;
  bool _restoring = false;
  String? _message;

  @override
  void initState() {
    super.initState();
    _future = EntitlementService.instance.availablePackages();
  }

  Future<void> _purchase(Package package) async {
    setState(() {
      _busyPackage = package;
      _message = null;
    });

    try {
      final state = await EntitlementService.instance.purchase(package);
      if (!mounted) {
        return;
      }

      if (state.isPro) {
        Navigator.of(context).pop<EntitlementState>(state);
        return;
      }

      setState(() {
        _message = 'Purchase completed, but Pro is not active yet.';
      });
    } on PlatformException catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _message = error.message ?? 'Purchase could not be completed.';
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _message = 'Purchase could not be completed.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _busyPackage = null;
        });
      }
    }
  }

  Future<void> _restore() async {
    setState(() {
      _restoring = true;
      _message = null;
    });

    try {
      final state = await EntitlementService.instance.restorePurchases();
      if (!mounted) {
        return;
      }

      if (state.isPro) {
        Navigator.of(context).pop<EntitlementState>(state);
        return;
      }

      setState(() {
        _message = 'No active Sivra Pro purchase was found.';
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _message = 'Purchases could not be restored.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _restoring = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Sivra Pro')),
      body: SafeArea(
        child: FutureBuilder<List<Package>>(
          future: _future,
          builder: (context, snapshot) {
            final loading = snapshot.connectionState != ConnectionState.done;
            final packages = snapshot.data ?? const <Package>[];

            return ListView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
              children: [
                Text(
                  'Unlock AI Pack Generation',
                  style: textTheme.headlineSmall,
                ),
                const SizedBox(height: 10),
                Text(
                  'Start with a 7-day free trial. Sivra Pro creates fresh daily packs from your focus areas, learning memory, and trusted source rules.',
                  style: textTheme.bodyMedium?.copyWith(
                    color: colors.onSurface.withValues(alpha: 0.74),
                  ),
                ),
                const SizedBox(height: 22),
                const _BenefitRow(
                  icon: Icons.auto_awesome_outlined,
                  label: 'Personalized AI-generated daily packs',
                ),
                const _BenefitRow(
                  icon: Icons.verified_outlined,
                  label: 'Source trust and content QA checks',
                ),
                const _BenefitRow(
                  icon: Icons.insights_outlined,
                  label: 'Learning memory that adapts over time',
                ),
                const SizedBox(height: 22),
                if (loading)
                  const Center(child: CircularProgressIndicator())
                else if (packages.isEmpty)
                  const _PaywallSetupNotice()
                else
                  ...packages.map(
                    (package) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _PlanTile(
                        package: package,
                        isBusy: _busyPackage == package,
                        onPressed: _busyPackage == null && !_restoring
                            ? () => _purchase(package)
                            : null,
                      ),
                    ),
                  ),
                if (_message != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    _message!,
                    style: textTheme.bodySmall?.copyWith(color: colors.error),
                  ),
                ],
                const SizedBox(height: 16),
                TextButton(
                  onPressed: _restoring || _busyPackage != null
                      ? null
                      : _restore,
                  child: Text(
                    _restoring ? 'Restoring...' : 'Restore purchases',
                  ),
                ),
                TextButton(
                  onPressed: () =>
                      Navigator.of(context).pop<EntitlementState>(),
                  child: const Text('Continue free'),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _BenefitRow extends StatelessWidget {
  final IconData icon;
  final String label;

  const _BenefitRow({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: colors.primary),
          const SizedBox(width: 10),
          Expanded(child: Text(label)),
        ],
      ),
    );
  }
}

class _PlanTile extends StatelessWidget {
  final Package package;
  final bool isBusy;
  final VoidCallback? onPressed;

  const _PlanTile({
    required this.package,
    required this.isBusy,
    required this.onPressed,
  });

  bool get _isAnnual =>
      package.packageType == PackageType.annual ||
      package.storeProduct.identifier == AppEnvironment.annualProductId;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final price = package.storeProduct.priceString;
    final period = _isAnnual ? 'per year' : 'per month';

    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border.all(
          color: _isAnnual
              ? colors.primary.withValues(alpha: 0.72)
              : colors.onSurface.withValues(alpha: 0.16),
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    _isAnnual ? 'Annual' : 'Monthly',
                    style: textTheme.titleMedium,
                  ),
                ),
                if (_isAnnual)
                  Text(
                    'Best value',
                    style: textTheme.labelMedium?.copyWith(
                      color: colors.primary,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              '7-day free trial, then $price $period.',
              style: textTheme.bodyMedium?.copyWith(
                color: colors.onSurface.withValues(alpha: 0.72),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: onPressed,
                child: Text(isBusy ? 'Starting...' : 'Start free trial'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PaywallSetupNotice extends StatelessWidget {
  const _PaywallSetupNotice();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border.all(color: colors.onSurface.withValues(alpha: 0.16)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Padding(
        padding: EdgeInsets.all(14),
        child: Text(
          'RevenueCat offerings are not available in this build. Free curated packs remain available.',
        ),
      ),
    );
  }
}
