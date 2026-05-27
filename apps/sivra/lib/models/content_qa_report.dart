import 'package:cloud_firestore/cloud_firestore.dart';

class ContentQaReport {
  final String status;
  final int score;
  final List<String> issues;
  final List<String> warnings;
  final DateTime? checkedAt;

  const ContentQaReport({
    required this.status,
    required this.score,
    this.issues = const <String>[],
    this.warnings = const <String>[],
    this.checkedAt,
  });

  factory ContentQaReport.accepted({List<String> warnings = const <String>[]}) {
    return ContentQaReport(
      status: warnings.isEmpty ? 'accepted' : 'accepted_with_warnings',
      score: warnings.isEmpty ? 100 : 82,
      warnings: warnings,
      checkedAt: DateTime.now(),
    );
  }

  factory ContentQaReport.fallback({
    required List<String> issues,
    List<String> warnings = const <String>[],
  }) {
    return ContentQaReport(
      status: 'fallback_used',
      score: 60,
      issues: issues,
      warnings: warnings,
      checkedAt: DateTime.now(),
    );
  }

  factory ContentQaReport.fromMap(Map<String, dynamic> data) {
    final checkedAt = data['checkedAt'];

    return ContentQaReport(
      status: data['status'] is String ? data['status'] as String : 'unknown',
      score: data['score'] is int ? data['score'] as int : 0,
      issues: data['issues'] is List
          ? (data['issues'] as List).whereType<String>().toList()
          : const <String>[],
      warnings: data['warnings'] is List
          ? (data['warnings'] as List).whereType<String>().toList()
          : const <String>[],
      checkedAt: checkedAt is Timestamp ? checkedAt.toDate() : null,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'status': status,
      'score': score,
      'issues': issues,
      'warnings': warnings,
      'checkedAt': checkedAt != null
          ? Timestamp.fromDate(checkedAt!)
          : FieldValue.serverTimestamp(),
    };
  }
}
