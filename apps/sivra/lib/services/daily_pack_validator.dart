import '../models/daily_pack.dart';
import '../models/drill_item.dart';
import 'source_trust_policy.dart';

class DailyPackValidator {
  final SourceTrustPolicy sourceTrustPolicy;

  const DailyPackValidator({
    this.sourceTrustPolicy = const SourceTrustPolicy(),
  });

  DailyPackValidationResult validate(DailyPack pack) {
    final errors = <String>[];
    final warnings = <String>[];

    if (pack.dayId.trim().isEmpty) {
      errors.add('Missing dayId');
    }

    if (pack.items.length != 8) {
      errors.add('Daily packs must contain exactly 8 items');
    }

    final briefingCount = pack.items
        .where((item) => item.type == DrillItemType.briefing && item.hasSource)
        .length;
    if (briefingCount != 2) {
      errors.add('Daily packs must contain exactly 2 sourced briefings');
    }

    for (final item in pack.items) {
      if (item.id.trim().isEmpty) {
        errors.add('An item is missing an id');
      }
      if (item.prompt.trim().isEmpty) {
        errors.add('Item ${item.id} is missing a prompt');
      }
      if (item.type != DrillItemType.articulation &&
          (item.answer == null || item.answer!.trim().isEmpty)) {
        errors.add('Item ${item.id} is missing an answer');
      }
      if (item.type != DrillItemType.articulation &&
          (item.explanation == null || item.explanation!.trim().isEmpty)) {
        errors.add('Item ${item.id} is missing an explanation');
      }

      final source = item.source;
      if (source != null) {
        if (item.type != DrillItemType.briefing) {
          errors.add('Only briefing items should include a source');
        }

        if (source.title.trim().isEmpty ||
            source.publisher.trim().isEmpty ||
            source.dateLabel.trim().isEmpty ||
            source.url.trim().isEmpty) {
          errors.add('Source for ${item.id} is incomplete');
        }

        final uri = Uri.tryParse(source.url);
        if (uri == null || !uri.hasScheme || uri.host.isEmpty) {
          errors.add('Source for ${item.id} must have a valid URL');
        }

        final trust = sourceTrustPolicy.evaluate(source);
        errors.addAll(
          trust.issues.map((issue) => 'Source for ${item.id}: $issue'),
        );
        warnings.addAll(
          trust.warnings.map((warning) => 'Source for ${item.id}: $warning'),
        );
      }
    }

    if (pack.items.length >= 8) {
      if (pack.items[6].type != DrillItemType.articulation) {
        errors.add('Screen 7 must be an articulation exercise');
      }
      if (pack.items[7].type != DrillItemType.review) {
        errors.add('Screen 8 must be a review item');
      }
    }

    return DailyPackValidationResult(errors: errors, warnings: warnings);
  }
}

class DailyPackValidationResult {
  final List<String> errors;
  final List<String> warnings;

  const DailyPackValidationResult({
    this.errors = const <String>[],
    this.warnings = const <String>[],
  });

  bool get isValid => errors.isEmpty;
}
