import 'package:cloud_firestore/cloud_firestore.dart';

import 'content_qa_report.dart';
import 'drill_item.dart';
import 'learning_profile.dart';

class DailyPack {
  final String dayId;
  final List<String> focusAreas;
  final List<DrillItem> items;
  final String generator;
  final ContentQaReport? qaReport;
  final List<String> completedItemIds;
  final Map<String, String> answersByItemId;
  final LearningProfile? learningProfile;
  final DateTime? generatedAt;
  final DateTime? completedAt;

  const DailyPack({
    required this.dayId,
    required this.focusAreas,
    required this.items,
    this.generator = 'curated_v1',
    this.qaReport,
    this.completedItemIds = const <String>[],
    this.answersByItemId = const <String, String>{},
    this.learningProfile,
    this.generatedAt,
    this.completedAt,
  });

  bool get isCompleted => completedAt != null;

  int get completedItemCount => completedItemIds.length;

  int get writtenAnswerCount => answersByItemId.length;

  int get briefingCount => items.where((item) => item.hasSource).length;

  int get drillCount => items.length - briefingCount;

  factory DailyPack.fromMap({
    required String dayId,
    required Map<String, dynamic> data,
  }) {
    final rawItems = data['items'];
    final rawFocusAreas = data['focusAreas'];
    final generatedAt = data['generatedAt'];
    final completedAt = data['completedAt'];
    final qaReport = data['qaReport'];
    final completedItemIds = data['completedItemIds'];
    final answersByItemId = data['answersByItemId'];
    final learningProfile = data['learningProfile'];

    return DailyPack(
      dayId: dayId,
      focusAreas: rawFocusAreas is List
          ? rawFocusAreas.whereType<String>().toList()
          : const <String>[],
      items: rawItems is List
          ? rawItems
                .whereType<Map<String, dynamic>>()
                .map(DrillItem.fromMap)
                .toList()
          : const <DrillItem>[],
      generator: data['generator'] is String
          ? data['generator'] as String
          : 'unknown',
      qaReport: qaReport is Map<String, dynamic>
          ? ContentQaReport.fromMap(qaReport)
          : null,
      completedItemIds: completedItemIds is List
          ? completedItemIds.whereType<String>().toList()
          : const <String>[],
      answersByItemId: answersByItemId is Map
          ? answersByItemId.map(
              (key, value) => MapEntry(key.toString(), value.toString()),
            )
          : const <String, String>{},
      learningProfile: learningProfile is Map<String, dynamic>
          ? LearningProfile.fromMap(learningProfile)
          : null,
      generatedAt: generatedAt is Timestamp ? generatedAt.toDate() : null,
      completedAt: completedAt is Timestamp ? completedAt.toDate() : null,
    );
  }

  Map<String, dynamic> toCreateMap() {
    return <String, dynamic>{
      'dayId': dayId,
      'focusAreas': focusAreas,
      'items': items.map((item) => item.toMap()).toList(),
      'itemCount': items.length,
      'generator': generator,
      if (qaReport != null) 'qaReport': qaReport!.toMap(),
      'generatedAt': FieldValue.serverTimestamp(),
      'generatorVersion': 1,
      'completedItemIds': completedItemIds,
      'answersByItemId': answersByItemId,
      if (learningProfile != null) 'learningProfile': learningProfile!.toMap(),
    };
  }

  DailyPack copyWithCompleted(DateTime completedAt) {
    return DailyPack(
      dayId: dayId,
      focusAreas: focusAreas,
      items: items,
      generator: generator,
      qaReport: qaReport,
      completedItemIds: completedItemIds,
      answersByItemId: answersByItemId,
      learningProfile: learningProfile,
      generatedAt: generatedAt,
      completedAt: completedAt,
    );
  }

  DailyPack copyWithQaReport(ContentQaReport qaReport) {
    return DailyPack(
      dayId: dayId,
      focusAreas: focusAreas,
      items: items,
      generator: generator,
      qaReport: qaReport,
      completedItemIds: completedItemIds,
      answersByItemId: answersByItemId,
      learningProfile: learningProfile,
      generatedAt: generatedAt,
      completedAt: completedAt,
    );
  }

  DailyPack copyWithProgress({
    List<String>? completedItemIds,
    Map<String, String>? answersByItemId,
  }) {
    return DailyPack(
      dayId: dayId,
      focusAreas: focusAreas,
      items: items,
      generator: generator,
      qaReport: qaReport,
      completedItemIds: completedItemIds ?? this.completedItemIds,
      answersByItemId: answersByItemId ?? this.answersByItemId,
      learningProfile: learningProfile,
      generatedAt: generatedAt,
      completedAt: completedAt,
    );
  }

  DailyPack copyWithLearningProfile(LearningProfile learningProfile) {
    return DailyPack(
      dayId: dayId,
      focusAreas: focusAreas,
      items: items,
      generator: generator,
      qaReport: qaReport,
      completedItemIds: completedItemIds,
      answersByItemId: answersByItemId,
      learningProfile: learningProfile,
      generatedAt: generatedAt,
      completedAt: completedAt,
    );
  }
}
