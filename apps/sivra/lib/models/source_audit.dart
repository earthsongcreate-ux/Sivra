import '../services/source_trust_policy.dart';
import 'daily_pack.dart';

class SourceAudit {
  final int packCount;
  final int sourceCount;
  final int trustedSourceCount;
  final int issueCount;
  final int warningCount;
  final Map<String, int> hostCounts;
  final int fallbackPackCount;

  const SourceAudit({
    required this.packCount,
    required this.sourceCount,
    required this.trustedSourceCount,
    required this.issueCount,
    required this.warningCount,
    required this.hostCounts,
    required this.fallbackPackCount,
  });

  factory SourceAudit.fromPacks(
    List<DailyPack> packs, {
    SourceTrustPolicy policy = const SourceTrustPolicy(),
  }) {
    var sourceCount = 0;
    var trustedSourceCount = 0;
    var issueCount = 0;
    var warningCount = 0;
    var fallbackPackCount = 0;
    final hostCounts = <String, int>{};

    for (final pack in packs) {
      if (pack.generator.contains('fallback')) {
        fallbackPackCount += 1;
      }

      for (final item in pack.items) {
        final source = item.source;
        if (source == null) {
          continue;
        }

        sourceCount += 1;
        final host = Uri.tryParse(
          source.url,
        )?.host.toLowerCase().replaceFirst(RegExp(r'^www\.'), '');
        if (host != null && host.isNotEmpty) {
          hostCounts[host] = (hostCounts[host] ?? 0) + 1;
        }

        final trust = policy.evaluate(source);
        if (trust.isTrusted) {
          trustedSourceCount += 1;
        }
        issueCount += trust.issues.length;
        warningCount += trust.warnings.length;
      }
    }

    return SourceAudit(
      packCount: packs.length,
      sourceCount: sourceCount,
      trustedSourceCount: trustedSourceCount,
      issueCount: issueCount,
      warningCount: warningCount,
      hostCounts: hostCounts,
      fallbackPackCount: fallbackPackCount,
    );
  }
}
