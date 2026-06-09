import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../config/app_environment.dart';
import '../design/sivra_colors.dart';
import '../models/entitlement_state.dart';
import '../services/entitlement_service.dart';

class PaywallScreen extends StatefulWidget {
  static final privacyPolicyUri = Uri.parse('https://sivra.pro/privacy');
  static final termsOfUseUri = Uri.parse('https://sivra.pro/terms');

  final List<PaywallPlan>? previewPlans;
  final Future<EntitlementState> Function(String planId)? previewPurchase;
  final Future<EntitlementState> Function()? previewRestore;
  final Future<bool> Function(Uri uri)? launchExternalUrl;

  const PaywallScreen({
    super.key,
    this.previewPlans,
    this.previewPurchase,
    this.previewRestore,
    this.launchExternalUrl,
  });

  @override
  State<PaywallScreen> createState() => _PaywallScreenState();
}

class PaywallPlan {
  final String id;
  final String price;
  final bool recommended;
  final bool hasTrial;
  final Package? package;

  const PaywallPlan({
    required this.id,
    required this.price,
    required this.recommended,
    required this.hasTrial,
    this.package,
  });

  bool get isAnnual => id == 'annual';
}

class _PaywallScreenState extends State<PaywallScreen> {
  late Future<List<PaywallPlan>> _plans;
  String? _processingPlanId;
  bool _restoring = false;

  @override
  void initState() {
    super.initState();
    _plans = _loadPlans();
  }

  Future<List<PaywallPlan>> _loadPlans() async {
    final previewPlans = widget.previewPlans;
    if (previewPlans != null) {
      return previewPlans;
    }

    try {
      final packages = await EntitlementService.instance.availablePackages();
      final annual = _findPackage(packages, annual: true);
      final monthly = _findPackage(packages, annual: false);
      return <PaywallPlan>[
        PaywallPlan(
          id: 'annual',
          price: _priceWithPeriod(
            annual?.storeProduct.priceString,
            fallback: r'$99.99/year',
            period: 'year',
          ),
          recommended: true,
          hasTrial: true,
          package: annual,
        ),
        PaywallPlan(
          id: 'monthly',
          price: _priceWithPeriod(
            monthly?.storeProduct.priceString,
            fallback: r'$12.99/month',
            period: 'month',
          ),
          recommended: false,
          hasTrial: false,
          package: monthly,
        ),
      ];
    } catch (_) {
      return const <PaywallPlan>[
        PaywallPlan(
          id: 'annual',
          price: r'$99.99/year',
          recommended: true,
          hasTrial: true,
        ),
        PaywallPlan(
          id: 'monthly',
          price: r'$12.99/month',
          recommended: false,
          hasTrial: false,
        ),
      ];
    }
  }

  Package? _findPackage(List<Package> packages, {required bool annual}) {
    for (final package in packages) {
      final matchesType = annual
          ? package.packageType == PackageType.annual
          : package.packageType == PackageType.monthly;
      final matchesId =
          package.storeProduct.identifier ==
          (annual
              ? AppEnvironment.annualProductId
              : AppEnvironment.monthlyProductId);
      if (matchesType || matchesId) {
        return package;
      }
    }
    return null;
  }

  String _priceWithPeriod(
    String? price, {
    required String fallback,
    required String period,
  }) {
    final value = price?.trim();
    if (value == null || value.isEmpty) {
      return fallback;
    }
    return value.contains('/') ? value : '$value/$period';
  }

  Future<void> _purchase(PaywallPlan plan) async {
    if (_processingPlanId != null || _restoring) {
      return;
    }
    setState(() {
      _processingPlanId = plan.id;
    });

    try {
      final previewPurchase = widget.previewPurchase;
      final package = plan.package;
      final state = previewPurchase != null
          ? await previewPurchase(plan.id)
          : package == null
          ? const EntitlementState.free(
              entitlementId: AppEnvironment.proEntitlementId,
              message:
                  'Subscriptions are unavailable because RevenueCat is not configured for this build.',
            )
          : await EntitlementService.instance.purchase(package);
      if (!mounted) {
        return;
      }
      if (state.isPro) {
        Navigator.of(context).pop(state);
      } else {
        _showMessage(
          state.message ?? 'The subscription could not be activated.',
        );
      }
    } on PlatformException catch (error) {
      if (mounted) {
        _showMessage(error.message ?? 'The purchase could not be completed.');
      }
    } finally {
      if (mounted) {
        setState(() {
          _processingPlanId = null;
        });
      }
    }
  }

  Future<void> _restore() async {
    if (_processingPlanId != null || _restoring) {
      return;
    }
    setState(() {
      _restoring = true;
    });

    try {
      final state = widget.previewRestore != null
          ? await widget.previewRestore!()
          : await EntitlementService.instance.restorePurchases();
      if (!mounted) {
        return;
      }
      if (state.isPro) {
        Navigator.of(context).pop(state);
      } else {
        _showMessage(
          state.message ?? 'No active Sivra Pro purchase was found.',
        );
      }
    } on PlatformException catch (error) {
      if (mounted) {
        _showMessage(error.message ?? 'Purchases could not be restored.');
      }
    } finally {
      if (mounted) {
        setState(() {
          _restoring = false;
        });
      }
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _openExternalUrl(Uri uri) async {
    final launched = widget.launchExternalUrl != null
        ? await widget.launchExternalUrl!(uri)
        : await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!launched && mounted) {
      _showMessage('Unable to open this link.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sivra Pro')),
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              SivraColors.ritualGradientTop,
              SivraColors.deepInk,
              SivraColors.ritualGradientBottom,
            ],
            stops: [0, 0.52, 1],
          ),
        ),
        child: SafeArea(
          child: FutureBuilder<List<PaywallPlan>>(
            future: _plans,
            builder: (context, snapshot) {
              final plans = snapshot.data;
              if (plans == null) {
                return const Center(child: CircularProgressIndicator());
              }
              return _PaywallContent(
                plans: plans,
                processingPlanId: _processingPlanId,
                restoring: _restoring,
                onPurchase: _purchase,
                onRestore: _restore,
                onContinueFree: () => Navigator.of(context).pop(),
                onOpenPrivacy: () =>
                    _openExternalUrl(PaywallScreen.privacyPolicyUri),
                onOpenTerms: () =>
                    _openExternalUrl(PaywallScreen.termsOfUseUri),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _PaywallContent extends StatelessWidget {
  final List<PaywallPlan> plans;
  final String? processingPlanId;
  final bool restoring;
  final ValueChanged<PaywallPlan> onPurchase;
  final VoidCallback onRestore;
  final VoidCallback onContinueFree;
  final VoidCallback onOpenPrivacy;
  final VoidCallback onOpenTerms;

  const _PaywallContent({
    required this.plans,
    required this.processingPlanId,
    required this.restoring,
    required this.onPurchase,
    required this.onRestore,
    required this.onContinueFree,
    required this.onOpenPrivacy,
    required this.onOpenTerms,
  });

  @override
  Widget build(BuildContext context) {
    final annual = plans.firstWhere((plan) => plan.isAnnual);
    final monthly = plans.firstWhere((plan) => !plan.isAnnual);
    final compactHeight = MediaQuery.sizeOf(context).height <= 600;

    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
            children: [
              _PaywallHero(compact: compactHeight),
              SizedBox(height: compactHeight ? 18 : 24),
              Text(
                'WHAT CONTINUES WITH SIVRA PRO',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: SivraColors.bronze,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.2,
                ),
              ),
              SizedBox(height: compactHeight ? 10 : 12),
              _BenefitsGrid(
                compact: compactHeight,
                benefits: <_BenefitData>[
                  _BenefitData(
                    icon: Icons.tune_rounded,
                    title: 'Personalized Daily Rituals',
                    detail: 'Shaped by your focus areas.',
                  ),
                  _BenefitData(
                    icon: Icons.auto_stories_outlined,
                    title: 'Thinking Archive',
                    detail: 'Keep your best ideas and insights.',
                  ),
                  _BenefitData(
                    icon: Icons.calendar_view_week_outlined,
                    title: 'Weekly Recaps',
                    detail: 'Reflect on patterns over time.',
                  ),
                  _BenefitData(
                    icon: Icons.radar_outlined,
                    title: 'Fresh Source Context',
                    detail: 'Stay current with selected signals.',
                  ),
                ],
              ),
              SizedBox(height: compactHeight ? 10 : 14),
              Text(
                'CHOOSE YOUR PLAN',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: SivraColors.bronze,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.2,
                ),
              ),
              SizedBox(height: compactHeight ? 4 : 6),
              _PricingSection(
                annual: annual,
                monthly: monthly,
                processingPlanId: processingPlanId,
                disabled: processingPlanId != null || restoring,
                onPurchase: onPurchase,
                compactHeight: compactHeight,
              ),
              const SizedBox(height: 2),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 4),
          child: Column(
            children: [
              SizedBox(height: compactHeight ? 1 : 2),
              Wrap(
                alignment: WrapAlignment.center,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  _FooterAction(
                    label: restoring ? 'Restoring...' : 'Restore Purchases',
                    onTap: processingPlanId == null && !restoring
                        ? onRestore
                        : null,
                  ),
                  Text(
                    '  |  ',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: SivraColors.mutedText.withValues(alpha: 0.42),
                    ),
                  ),
                  _FooterAction(
                    label: 'Continue Free',
                    onTap: processingPlanId == null && !restoring
                        ? onContinueFree
                        : null,
                  ),
                ],
              ),
              SizedBox(height: compactHeight ? 0 : 1),
              Wrap(
                alignment: WrapAlignment.center,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  _LegalLink(label: 'Privacy Policy', onTap: onOpenPrivacy),
                  Text(
                    '  •  ',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: SivraColors.mutedText.withValues(alpha: 0.6),
                    ),
                  ),
                  _LegalLink(label: 'Terms of Use', onTap: onOpenTerms),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _PaywallHero extends StatelessWidget {
  final bool compact;

  const _PaywallHero({required this.compact});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        compact ? 20 : 22,
        compact ? 20 : 24,
        compact ? 20 : 22,
        compact ? 19 : 23,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            SivraColors.surfaceSoft.withValues(alpha: 0.96),
            SivraColors.surface.withValues(alpha: 0.88),
            SivraColors.ritualGradientBottom,
          ],
        ),
        border: Border.all(color: SivraColors.bronze.withValues(alpha: 0.22)),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 34,
            spreadRadius: -12,
            offset: const Offset(0, 20),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'SIVRA PRO',
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: SivraColors.bronze,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.4,
            ),
          ),
          SizedBox(height: compact ? 10 : 12),
          Text(
            'Continue Building Your Thinking System',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              color: SivraColors.warmIvory,
              fontWeight: FontWeight.w600,
              letterSpacing: -0.5,
              height: 1.16,
            ),
          ),
          SizedBox(height: compact ? 10 : 13),
          Text(
            'Develop sharper judgment, stronger articulation, and a growing archive of insights.',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: SivraColors.mutedText,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _BenefitData {
  final IconData icon;
  final String title;
  final String detail;

  const _BenefitData({
    required this.icon,
    required this.title,
    required this.detail,
  });
}

class _BenefitsGrid extends StatelessWidget {
  final List<_BenefitData> benefits;
  final bool compact;

  const _BenefitsGrid({required this.benefits, required this.compact});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final itemWidth = (constraints.maxWidth - 10) / 2;
        return Wrap(
          spacing: compact ? 8 : 10,
          runSpacing: compact ? 8 : 10,
          children: benefits
              .map(
                (benefit) => SizedBox(
                  width: itemWidth,
                  child: _Benefit(benefit: benefit, compact: compact),
                ),
              )
              .toList(),
        );
      },
    );
  }
}

class _Benefit extends StatelessWidget {
  final _BenefitData benefit;
  final bool compact;

  const _Benefit({required this.benefit, required this.compact});

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(minHeight: compact ? 100 : 112),
      padding: EdgeInsets.fromLTRB(
        compact ? 12 : 14,
        compact ? 12 : 14,
        compact ? 11 : 12,
        compact ? 11 : 13,
      ),
      decoration: BoxDecoration(
        color: SivraColors.surface.withValues(alpha: 0.5),
        border: Border.all(color: SivraColors.bronze.withValues(alpha: 0.12)),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(benefit.icon, size: 20, color: SivraColors.bronze),
          SizedBox(height: compact ? 8 : 10),
          Text(
            benefit.title,
            maxLines: 2,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: SivraColors.warmIvory,
              fontWeight: FontWeight.w600,
              height: 1.2,
            ),
          ),
          SizedBox(height: compact ? 4 : 5),
          Text(
            benefit.detail,
            maxLines: 2,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: SivraColors.mutedText,
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }
}

class _PricingSection extends StatelessWidget {
  final PaywallPlan annual;
  final PaywallPlan monthly;
  final String? processingPlanId;
  final bool disabled;
  final ValueChanged<PaywallPlan> onPurchase;
  final bool compactHeight;

  const _PricingSection({
    required this.annual,
    required this.monthly,
    required this.processingPlanId,
    required this.disabled,
    required this.onPurchase,
    required this.compactHeight,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(compactHeight ? 8 : 10),
      decoration: BoxDecoration(
        color: SivraColors.surface.withValues(alpha: 0.32),
        border: Border.all(color: SivraColors.bronze.withValues(alpha: 0.12)),
        borderRadius: BorderRadius.circular(26),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final useCompactCards = constraints.maxWidth >= 300;
          final annualCard = _PlanCard(
            plan: annual,
            processing: processingPlanId == annual.id,
            disabled: disabled,
            compact: useCompactCards,
            onPurchase: () => onPurchase(annual),
          );
          final monthlyCard = _PlanCard(
            plan: monthly,
            processing: processingPlanId == monthly.id,
            disabled: disabled,
            compact: useCompactCards,
            onPurchase: () => onPurchase(monthly),
          );

          if (constraints.maxWidth < 300) {
            return Column(
              children: [
                annualCard,
                SizedBox(height: compactHeight ? 8 : 10),
                monthlyCard,
              ],
            );
          }

          return IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(child: annualCard),
                SizedBox(width: compactHeight ? 8 : 10),
                Expanded(child: monthlyCard),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _PlanCard extends StatelessWidget {
  final PaywallPlan plan;
  final bool processing;
  final bool disabled;
  final bool compact;
  final VoidCallback onPurchase;

  const _PlanCard({
    required this.plan,
    required this.processing,
    required this.disabled,
    required this.compact,
    required this.onPurchase,
  });

  @override
  Widget build(BuildContext context) {
    final annual = plan.isAnnual;
    return Container(
      key: ValueKey('plan-${plan.id}'),
      padding: EdgeInsets.fromLTRB(
        compact ? 12 : 16,
        compact ? 11 : 14,
        compact ? 12 : 16,
        compact ? 11 : 14,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: annual
              ? [
                  SivraColors.surfaceSoft,
                  SivraColors.surface.withValues(alpha: 0.92),
                ]
              : [
                  SivraColors.surface.withValues(alpha: 0.7),
                  SivraColors.surfaceSoft.withValues(alpha: 0.62),
                ],
        ),
        border: Border.all(
          color: SivraColors.bronze.withValues(alpha: annual ? 0.44 : 0.28),
        ),
        borderRadius: BorderRadius.circular(19),
        boxShadow: [
          BoxShadow(
            color: annual
                ? Colors.black.withValues(alpha: 0.26)
                : SivraColors.bronze.withValues(alpha: 0.12),
            blurRadius: annual ? 28 : 22,
            spreadRadius: -14,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (annual)
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 7,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: SivraColors.bronze.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    'Recommended',
                    maxLines: 1,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: SivraColors.bronze,
                      fontWeight: FontWeight.w600,
                      fontSize: compact ? 9.5 : null,
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  'Save 36%',
                  maxLines: 1,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: SivraColors.bronze,
                    fontWeight: FontWeight.w700,
                    fontSize: compact ? 9.5 : null,
                  ),
                ),
              ],
            )
          else
            Text(
              'Monthly',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: SivraColors.warmIvory,
                fontWeight: FontWeight.w700,
              ),
            ),
          const SizedBox(height: 6),
          Text(
            plan.hasTrial ? '7-Day Free Trial' : 'Cancel anytime',
            maxLines: 1,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: plan.hasTrial ? SivraColors.bronze : SivraColors.mutedText,
              fontWeight: plan.hasTrial ? FontWeight.w600 : FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            plan.price,
            maxLines: 1,
            style:
                (compact
                        ? Theme.of(context).textTheme.titleMedium
                        : Theme.of(context).textTheme.titleLarge)
                    ?.copyWith(
                      color: SivraColors.warmIvory,
                      fontWeight: FontWeight.w700,
                    ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              key: ValueKey('purchase-${plan.id}'),
              onPressed: disabled ? null : onPurchase,
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(42),
                maximumSize: const Size.fromHeight(42),
                backgroundColor: annual
                    ? SivraColors.bronze
                    : SivraColors.bronze.withValues(alpha: 0.17),
                foregroundColor: annual
                    ? SivraColors.deepInk
                    : SivraColors.bronze,
                side: annual
                    ? BorderSide.none
                    : BorderSide(
                        color: SivraColors.bronze.withValues(alpha: 0.5),
                      ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              child: Text(
                processing
                    ? 'Processing...'
                    : annual
                    ? 'Start 7-Day Free Trial'
                    : 'Subscribe Monthly',
                maxLines: 1,
                textAlign: TextAlign.center,
                overflow: TextOverflow.fade,
                softWrap: false,
                style: TextStyle(
                  fontSize: compact ? 9.5 : 12,
                  fontWeight: FontWeight.w700,
                  height: 1,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LegalLink extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _LegalLink({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onTap,
      style: TextButton.styleFrom(
        minimumSize: const Size(0, 40),
        padding: const EdgeInsets.symmetric(horizontal: 4),
        foregroundColor: SivraColors.mutedText.withValues(alpha: 0.76),
        textStyle: Theme.of(context).textTheme.labelSmall?.copyWith(
          decoration: TextDecoration.underline,
          decorationColor: SivraColors.mutedText.withValues(alpha: 0.76),
        ),
      ),
      child: Text(label),
    );
  }
}

class _FooterAction extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;

  const _FooterAction({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onTap,
      style: TextButton.styleFrom(
        minimumSize: const Size(0, 40),
        padding: const EdgeInsets.symmetric(horizontal: 4),
        foregroundColor: SivraColors.mutedText.withValues(alpha: 0.86),
        textStyle: Theme.of(
          context,
        ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w500),
      ),
      child: Text(label),
    );
  }
}
