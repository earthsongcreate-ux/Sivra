import '../models/drill_item.dart';

class SourceTrustPolicy {
  static const blockedHosts = <String>{
    'bit.ly',
    'example.com',
    'localhost',
    't.co',
    'tinyurl.com',
  };

  static const preferredHosts = <String>{
    'anthropic.com',
    'aws.amazon.com',
    'deepmind.google',
    'developers.googleblog.com',
    'microsoft.com',
    'nvidia.com',
    'openai.com',
    'platform.openai.com',
    'research.google',
  };

  const SourceTrustPolicy();

  SourceTrustResult evaluate(DrillItemSource source) {
    final issues = <String>[];
    final warnings = <String>[];
    final uri = Uri.tryParse(source.url);
    final host = uri?.host.toLowerCase().replaceFirst(RegExp(r'^www\.'), '');

    if (uri == null || !uri.hasScheme || uri.host.isEmpty) {
      issues.add('Source URL is invalid');
      return SourceTrustResult(issues: issues, warnings: warnings);
    }

    if (uri.scheme != 'https') {
      issues.add('${source.title} must use an HTTPS source URL');
    }

    if (host == null || blockedHosts.contains(host)) {
      issues.add('${source.title} uses a blocked or placeholder host');
    }

    if (uri.path.trim().isEmpty || uri.path == '/') {
      warnings.add(
        '${source.title} points to a homepage rather than a specific source',
      );
    }

    if (_looksGeneric(source.title) || _looksGeneric(source.publisher)) {
      issues.add('${source.title} has generic source metadata');
    }

    if (host != null && !preferredHosts.contains(host)) {
      warnings.add('${source.title} uses an unreviewed host: $host');
    }

    return SourceTrustResult(issues: issues, warnings: warnings);
  }

  bool _looksGeneric(String value) {
    final normalized = value.trim().toLowerCase();
    return normalized.isEmpty ||
        normalized == 'trusted publication' ||
        normalized == 'industry source' ||
        normalized == 'source title' ||
        normalized == 'publisher';
  }
}

class SourceTrustResult {
  final List<String> issues;
  final List<String> warnings;

  const SourceTrustResult({
    this.issues = const <String>[],
    this.warnings = const <String>[],
  });

  bool get isTrusted => issues.isEmpty;
}
