import 'daily_pack.dart';
import 'drill_item.dart';

class LearningProfile {
  final List<String> focusPriority;
  final List<DrillItemType> weakDrillTypes;
  final int recentPackCount;
  final int completedPackCount;
  final int writtenAnswerCount;
  final String guidance;

  const LearningProfile({
    required this.focusPriority,
    required this.weakDrillTypes,
    required this.recentPackCount,
    required this.completedPackCount,
    required this.writtenAnswerCount,
    required this.guidance,
  });

  factory LearningProfile.empty(List<String> focusAreas) {
    return LearningProfile(
      focusPriority: focusAreas,
      weakDrillTypes: const <DrillItemType>[],
      recentPackCount: 0,
      completedPackCount: 0,
      writtenAnswerCount: 0,
      guidance: 'Use the selected focus areas and keep the pack balanced.',
    );
  }

  factory LearningProfile.fromPacks({
    required List<DailyPack> packs,
    required List<String> focusAreas,
  }) {
    if (packs.isEmpty) {
      return LearningProfile.empty(focusAreas);
    }

    final focusCounts = <String, int>{};
    final weakCounts = <DrillItemType, int>{};
    var writtenAnswerCount = 0;
    var completedPackCount = 0;

    for (final pack in packs) {
      if (pack.isCompleted) {
        completedPackCount += 1;
      }
      writtenAnswerCount += pack.writtenAnswerCount;

      for (final focus in pack.focusAreas) {
        focusCounts[focus] = (focusCounts[focus] ?? 0) + 1;
      }

      for (final item in pack.items) {
        if (!pack.completedItemIds.contains(item.id)) {
          weakCounts[item.type] = (weakCounts[item.type] ?? 0) + 1;
        }
      }

      for (final item in pack.items.where(
        (item) => item.type == DrillItemType.articulation,
      )) {
        if (!pack.answersByItemId.containsKey(item.id)) {
          weakCounts[item.type] = (weakCounts[item.type] ?? 0) + 2;
        }
      }
    }

    final focusPriority = <String>{...focusAreas, ...focusCounts.keys}.toList()
      ..sort((a, b) => (focusCounts[b] ?? 0).compareTo(focusCounts[a] ?? 0));

    final weakDrillTypes = weakCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final weakTypeNames = weakDrillTypes
        .take(2)
        .map((entry) => entry.key.name)
        .join(', ');

    final guidance = weakTypeNames.isEmpty
        ? 'Keep the pack balanced and include one stretch exercise.'
        : 'Emphasize $weakTypeNames practice while preserving the 8-screen structure.';

    return LearningProfile(
      focusPriority: focusPriority,
      weakDrillTypes: weakDrillTypes.take(2).map((entry) => entry.key).toList(),
      recentPackCount: packs.length,
      completedPackCount: completedPackCount,
      writtenAnswerCount: writtenAnswerCount,
      guidance: guidance,
    );
  }

  factory LearningProfile.fromMap(Map<String, dynamic> data) {
    final weakDrillTypes = data['weakDrillTypes'];

    return LearningProfile(
      focusPriority: data['focusPriority'] is List
          ? (data['focusPriority'] as List).whereType<String>().toList()
          : const <String>[],
      weakDrillTypes: weakDrillTypes is List
          ? weakDrillTypes
                .whereType<String>()
                .map(DrillItemTypeCodec.fromValue)
                .toList()
          : const <DrillItemType>[],
      recentPackCount: data['recentPackCount'] is int
          ? data['recentPackCount'] as int
          : 0,
      completedPackCount: data['completedPackCount'] is int
          ? data['completedPackCount'] as int
          : 0,
      writtenAnswerCount: data['writtenAnswerCount'] is int
          ? data['writtenAnswerCount'] as int
          : 0,
      guidance: data['guidance'] is String ? data['guidance'] as String : '',
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'focusPriority': focusPriority,
      'weakDrillTypes': weakDrillTypes.map((type) => type.name).toList(),
      'recentPackCount': recentPackCount,
      'completedPackCount': completedPackCount,
      'writtenAnswerCount': writtenAnswerCount,
      'guidance': guidance,
    };
  }
}
