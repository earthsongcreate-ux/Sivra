import 'package:cloud_firestore/cloud_firestore.dart';

class DailyCompletion {
  final String dayId;
  final int itemCount;
  final DateTime? completedAt;

  const DailyCompletion({
    required this.dayId,
    required this.itemCount,
    this.completedAt,
  });

  factory DailyCompletion.fromMap({
    required String dayId,
    required Map<String, dynamic> data,
  }) {
    final completedAt = data['completedAt'];

    return DailyCompletion(
      dayId: dayId,
      itemCount: data['itemCount'] is int ? data['itemCount'] as int : 0,
      completedAt: completedAt is Timestamp ? completedAt.toDate() : null,
    );
  }
}
