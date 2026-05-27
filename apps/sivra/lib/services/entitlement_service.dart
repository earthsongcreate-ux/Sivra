import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

import '../config/app_environment.dart';
import '../models/entitlement_state.dart';

class EntitlementService {
  EntitlementService._();

  static final EntitlementService instance = EntitlementService._();

  bool _configured = false;
  String? _configuredUserId;

  bool get isConfigured => _configured;

  Future<void> configure({required String appUserId}) async {
    if (kIsWeb) {
      return;
    }

    final apiKey = _apiKeyForPlatform();
    if (apiKey.trim().isEmpty) {
      return;
    }

    if (_configured && _configuredUserId == appUserId) {
      return;
    }

    final configuration = PurchasesConfiguration(apiKey)
      ..appUserID = appUserId
      ..diagnosticsEnabled = AppEnvironment.diagnosticsEnabled;

    await Purchases.configure(configuration);
    _configured = true;
    _configuredUserId = appUserId;
  }

  Future<EntitlementState> currentState() async {
    if (!_configured) {
      return const EntitlementState.free(
        entitlementId: AppEnvironment.proEntitlementId,
        message: 'RevenueCat is not configured for this build.',
      );
    }

    try {
      final customerInfo = await Purchases.getCustomerInfo();
      return _stateFromCustomerInfo(customerInfo);
    } on PlatformException catch (error) {
      return EntitlementState.free(
        entitlementId: AppEnvironment.proEntitlementId,
        isConfigured: true,
        message: error.message ?? 'Unable to load purchase status.',
      );
    } catch (_) {
      return const EntitlementState.free(
        entitlementId: AppEnvironment.proEntitlementId,
        isConfigured: true,
        message: 'Unable to load purchase status.',
      );
    }
  }

  Future<List<Package>> availablePackages() async {
    if (!_configured) {
      return const <Package>[];
    }

    final offerings = await Purchases.getOfferings();
    final current = offerings.current;
    if (current == null) {
      return const <Package>[];
    }

    final packages = current.availablePackages.toList();
    packages.sort(_sortPackages);
    return packages;
  }

  Future<EntitlementState> purchase(Package package) async {
    final result = await Purchases.purchase(PurchaseParams.package(package));
    return _stateFromCustomerInfo(result.customerInfo);
  }

  Future<EntitlementState> restorePurchases() async {
    if (!_configured) {
      return const EntitlementState.free(
        entitlementId: AppEnvironment.proEntitlementId,
        message: 'RevenueCat is not configured for this build.',
      );
    }

    final customerInfo = await Purchases.restorePurchases();
    return _stateFromCustomerInfo(customerInfo);
  }

  EntitlementState _stateFromCustomerInfo(CustomerInfo customerInfo) {
    final entitlement =
        customerInfo.entitlements.active[AppEnvironment.proEntitlementId];

    return EntitlementState(
      isConfigured: true,
      isPro: entitlement != null,
      entitlementId: AppEnvironment.proEntitlementId,
      activeProductId: entitlement?.productIdentifier,
      managementUrl: customerInfo.managementURL,
    );
  }

  String _apiKeyForPlatform() {
    return switch (defaultTargetPlatform) {
      TargetPlatform.android => AppEnvironment.revenueCatAndroidApiKey,
      TargetPlatform.iOS ||
      TargetPlatform.macOS => AppEnvironment.revenueCatIosApiKey,
      _ => '',
    };
  }

  int _sortPackages(Package a, Package b) {
    return _rank(a).compareTo(_rank(b));
  }

  int _rank(Package package) {
    if (package.packageType == PackageType.annual ||
        package.storeProduct.identifier == AppEnvironment.annualProductId) {
      return 0;
    }
    if (package.packageType == PackageType.monthly ||
        package.storeProduct.identifier == AppEnvironment.monthlyProductId) {
      return 1;
    }
    return 2;
  }
}
