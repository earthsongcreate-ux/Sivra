import '../data/mock_daily_pack.dart';
import '../models/content_qa_report.dart';
import '../models/daily_pack.dart';
import '../models/learning_profile.dart';
import '../services/ai_pack_generator.dart';
import '../services/daily_pack_validator.dart';
import '../services/firestore_service.dart';
import '../services/personalization_engine.dart';
import '../utils/day_id.dart';

class DailyPackService {
  final FirestoreService _firestore;
  final AiPackGenerator _aiGenerator;
  final DailyPackValidator _validator;
  final PersonalizationEngine _personalizationEngine;

  const DailyPackService(
    this._firestore, {
    AiPackGenerator? aiGenerator,
    DailyPackValidator validator = const DailyPackValidator(),
    PersonalizationEngine personalizationEngine = const PersonalizationEngine(),
  }) : _aiGenerator = aiGenerator ?? const AiPackGenerator(endpoint: null),
       _validator = validator,
       _personalizationEngine = personalizationEngine;

  static DailyPackService get instance => DailyPackService(
    FirestoreService.instance,
    aiGenerator: AiPackGenerator.fromEnvironment(),
  );

  Future<DailyPack> getOrCreateTodayPack({
    required String uid,
    required List<String> focusAreas,
    bool allowAiGeneration = true,
  }) async {
    final todayId = dayIdFromDate(DateTime.now());
    final existing = await _firestore.getDailyPack(uid: uid, dayId: todayId);

    if (existing != null && existing.items.isNotEmpty) {
      return existing;
    }

    final pack = await _generatePack(
      uid: uid,
      dayId: todayId,
      focusAreas: focusAreas,
      allowAiGeneration: allowAiGeneration,
    );

    await _firestore.createDailyPack(uid: uid, pack: pack);
    return pack;
  }

  Future<DailyPack> _generatePack({
    required String uid,
    required String dayId,
    required List<String> focusAreas,
    required bool allowAiGeneration,
  }) async {
    final recentPacks = await _firestore.getRecentDailyPacks(
      uid: uid,
      limit: 7,
    );
    final learningProfile = _personalizationEngine.buildProfile(
      recentPacks: recentPacks,
      focusAreas: focusAreas,
    );

    if (!allowAiGeneration) {
      await _logEventSafely(
        uid: uid,
        name: 'daily_pack_free_curated_used',
        properties: <String, dynamic>{'dayId': dayId},
      );

      return _fallbackPack(
        dayId: dayId,
        focusAreas: focusAreas,
        learningProfile: learningProfile,
        generator: 'curated_free_v1',
        qaReport: ContentQaReport.accepted(
          warnings: const <String>['AI generation requires Sivra Pro.'],
        ),
      );
    }

    final aiPack = await _aiGenerator.generate(
      uid: uid,
      dayId: dayId,
      focusAreas: focusAreas,
      learningProfile: learningProfile,
    );

    if (aiPack != null) {
      final aiValidation = _validator.validate(aiPack);
      if (aiValidation.isValid) {
        return aiPack
            .copyWithLearningProfile(learningProfile)
            .copyWithQaReport(
              ContentQaReport.accepted(warnings: aiValidation.warnings),
            );
      }

      await _logEventSafely(
        uid: uid,
        name: 'daily_pack_ai_rejected',
        properties: <String, dynamic>{
          'dayId': dayId,
          'errors': aiValidation.errors,
          'warnings': aiValidation.warnings,
        },
      );

      return _fallbackPack(
        dayId: dayId,
        focusAreas: focusAreas,
        learningProfile: learningProfile,
        generator: 'curated_fallback_v1',
        qaReport: ContentQaReport.fallback(
          issues: aiValidation.errors,
          warnings: aiValidation.warnings,
        ),
      );
    }

    final fallback = _fallbackPack(
      dayId: dayId,
      focusAreas: focusAreas,
      learningProfile: learningProfile,
      generator: 'curated_fallback_v1',
      qaReport: ContentQaReport.fallback(
        issues: const <String>['AI endpoint unavailable or not configured'],
      ),
    );

    await _logEventSafely(
      uid: uid,
      name: 'daily_pack_fallback_used',
      properties: <String, dynamic>{'dayId': dayId, 'reason': 'ai_unavailable'},
    );

    return fallback;
  }

  DailyPack _fallbackPack({
    required String dayId,
    required List<String> focusAreas,
    required LearningProfile learningProfile,
    required String generator,
    required ContentQaReport qaReport,
  }) {
    return DailyPack(
      dayId: dayId,
      focusAreas: focusAreas,
      items: MockDailyPack.forFocus(
        learningProfile.focusPriority.isEmpty
            ? focusAreas
            : learningProfile.focusPriority,
        weakDrillTypes: learningProfile.weakDrillTypes,
      ),
      generator: generator,
      qaReport: qaReport,
      learningProfile: learningProfile,
    );
  }

  Future<void> _logEventSafely({
    required String uid,
    required String name,
    required Map<String, dynamic> properties,
  }) async {
    try {
      await _firestore.logEvent(uid: uid, name: name, properties: properties);
    } catch (_) {
      // Analytics should never block daily pack creation.
    }
  }
}
