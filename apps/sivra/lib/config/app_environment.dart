import 'package:flutter/foundation.dart';

class AppEnvironment {
  static const aiPackEndpoint = String.fromEnvironment(
    'SIVRA_AI_PACK_ENDPOINT',
  );
  static const buildChannel = String.fromEnvironment(
    'SIVRA_BUILD_CHANNEL',
    defaultValue: 'dev',
  );
  static const diagnosticsEnabled = bool.fromEnvironment(
    'SIVRA_DIAGNOSTICS',
    defaultValue: true,
  );
  static const _developerToolsOverride = bool.fromEnvironment(
    'SIVRA_DEVELOPER_TOOLS',
    defaultValue: false,
  );
  static const revenueCatIosApiKey = String.fromEnvironment(
    'SIVRA_REVENUECAT_IOS_KEY',
    defaultValue: 'appl_uYZySRtnMxPqmQKjGTmOaUFlYEE',
  );
  static const revenueCatAndroidApiKey = String.fromEnvironment(
    'SIVRA_REVENUECAT_ANDROID_KEY',
  );
  static const proEntitlementId = String.fromEnvironment(
    'SIVRA_PRO_ENTITLEMENT',
    defaultValue: 'sivra_pro',
  );
  static const monthlyProductId = String.fromEnvironment(
    'SIVRA_MONTHLY_PRODUCT_ID',
    defaultValue: 'sivra_monthly_1299',
  );
  static const annualProductId = String.fromEnvironment(
    'SIVRA_ANNUAL_PRODUCT_ID',
    defaultValue: 'sivra_annual_9999',
  );

  static bool get aiGenerationConfigured => aiPackEndpoint.trim().isNotEmpty;
  static bool get developerToolsEnabled =>
      kDebugMode || _developerToolsOverride;
  static bool get revenueCatConfigured =>
      revenueCatIosApiKey.trim().isNotEmpty ||
      revenueCatAndroidApiKey.trim().isNotEmpty;
}
