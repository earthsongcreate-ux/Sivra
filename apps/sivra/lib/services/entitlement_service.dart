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
      debugPrint('[RevenueCat] Skipping configuration on web.');
      return;
    }

    final apiKey = _apiKeyForPlatform();
    if (apiKey.trim().isEmpty) {
      debugPrint(
        '[RevenueCat] Configuration skipped: '
        '${_apiKeyNameForPlatform()} is empty.',
      );
      return;
    }

    if (_configured && _configuredUserId == appUserId) {
      debugPrint('[RevenueCat] Already configured for app user $appUserId.');
      return;
    }

    await Purchases.setLogLevel(LogLevel.debug);
    debugPrint(
      '[RevenueCat] Configuring ${defaultTargetPlatform.name} '
      'with ${_apiKeyNameForPlatform()} '
      '(prefix ${apiKey.substring(0, apiKey.length.clamp(0, 5))}, '
      'length ${apiKey.length}).',
    );

    try {
      final configuration = PurchasesConfiguration(apiKey)
        ..appUserID = appUserId
        ..diagnosticsEnabled = AppEnvironment.diagnosticsEnabled;

      await Purchases.configure(configuration);
      _configured = true;
      _configuredUserId = appUserId;
      debugPrint('[RevenueCat] Configuration completed.');
    } on PlatformException catch (error, stackTrace) {
      debugPrint(
        '[RevenueCat] Configuration failed: '
        '${_platformErrorDescription(error)}\n$stackTrace',
      );
      rethrow;
    } catch (error, stackTrace) {
      debugPrint('[RevenueCat] Configuration failed: $error\n$stackTrace');
      rethrow;
    }
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
      debugPrint(
        '[RevenueCat] Customer info failed: '
        '${_platformErrorDescription(error)}',
      );
      return EntitlementState.free(
        entitlementId: AppEnvironment.proEntitlementId,
        isConfigured: true,
        message: _platformErrorDescription(error),
      );
    } catch (error, stackTrace) {
      debugPrint('[RevenueCat] Customer info failed: $error\n$stackTrace');
      return EntitlementState.free(
        entitlementId: AppEnvironment.proEntitlementId,
        isConfigured: true,
        message: 'Unable to load purchase status: $error',
      );
    }
  }

  Future<List<Package>> availablePackages() async {
    if (!_configured) {
      return const <Package>[];
    }

    final offerings = await Purchases.getOfferings();
    _logOfferings(offerings);
    final current = offerings.current;
    if (current == null) {
      return const <Package>[];
    }

    final packages = current.availablePackages.toList();
    packages.sort(_sortPackages);
    return packages;
  }

  Future<EntitlementState> purchase(Package package) async {
    try {
      debugPrint(
        '[RevenueCat] Purchasing package ${package.identifier} '
        '(${package.storeProduct.identifier}).',
      );
      final result = await Purchases.purchase(PurchaseParams.package(package));
      return _stateFromCustomerInfo(result.customerInfo);
    } on PlatformException catch (error, stackTrace) {
      debugPrint(
        '[RevenueCat] Purchase failed: '
        '${_platformErrorDescription(error)}\n$stackTrace',
      );
      rethrow;
    }
  }

  Future<EntitlementState> restorePurchases() async {
    if (!_configured) {
      return const EntitlementState.free(
        entitlementId: AppEnvironment.proEntitlementId,
        message: 'RevenueCat is not configured for this build.',
      );
    }

    try {
      final customerInfo = await Purchases.restorePurchases();
      return _stateFromCustomerInfo(customerInfo);
    } on PlatformException catch (error, stackTrace) {
      debugPrint(
        '[RevenueCat] Restore failed: '
        '${_platformErrorDescription(error)}\n$stackTrace',
      );
      rethrow;
    }
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

  String _apiKeyNameForPlatform() {
    return switch (defaultTargetPlatform) {
      TargetPlatform.android => 'SIVRA_REVENUECAT_ANDROID_KEY',
      TargetPlatform.iOS || TargetPlatform.macOS => 'SIVRA_REVENUECAT_IOS_KEY',
      _ => 'RevenueCat API key',
    };
  }

  void _logOfferings(Offerings offerings) {
    debugPrint(
      '[RevenueCat] Offerings: current=${offerings.current?.identifier ?? "nil"}, '
      'all=${offerings.all.keys.join(", ")}.',
    );
    for (final package
        in offerings.current?.availablePackages ?? const <Package>[]) {
      debugPrint(
        '[RevenueCat] Package ${package.identifier}: '
        'type=${package.packageType.name}, '
        'product=${package.storeProduct.identifier}, '
        'price=${package.storeProduct.priceString}.',
      );
    }
  }

  String _platformErrorDescription(PlatformException error) {
    PurchasesErrorCode? purchasesCode;
    try {
      purchasesCode = PurchasesErrorHelper.getErrorCode(error);
    } catch (_) {
      purchasesCode = null;
    }
    return 'code=${purchasesCode?.name ?? error.code}, '
        'message=${error.message ?? "No message"}, '
        'details=${error.details ?? "none"}';
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
