class EntitlementState {
  final bool isConfigured;
  final bool isPro;
  final String entitlementId;
  final String? activeProductId;
  final String? managementUrl;
  final String? message;

  const EntitlementState({
    required this.isConfigured,
    required this.isPro,
    required this.entitlementId,
    this.activeProductId,
    this.managementUrl,
    this.message,
  });

  const EntitlementState.free({
    required this.entitlementId,
    this.isConfigured = false,
    this.message,
  }) : isPro = false,
       activeProductId = null,
       managementUrl = null;

  EntitlementState copyWithMessage(String? message) {
    return EntitlementState(
      isConfigured: isConfigured,
      isPro: isPro,
      entitlementId: entitlementId,
      activeProductId: activeProductId,
      managementUrl: managementUrl,
      message: message,
    );
  }
}
