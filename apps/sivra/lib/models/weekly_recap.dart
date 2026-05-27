import 'daily_pack.dart';

class WeeklyRecap {
  final int packCount;
  final int completedPackCount;
  final int completedScreenCount;
  final int writtenAnswerCount;
  final List<String> focusAreas;
  final String guidance;

  const WeeklyRecap({
    required this.packCount,
    required this.completedPackCount,
    required this.completedScreenCount,
    required this.writtenAnswerCount,
    required this.focusAreas,
    required this.guidance,
  });

  factory WeeklyRecap.fromPacks(List<DailyPack> packs) {
    final focusAreas = <String>{};

    for (final pack in packs) {
      focusAreas.addAll(pack.focusAreas);
    }

    return WeeklyRecap(
      packCount: packs.length,
      completedPackCount: packs.where((pack) => pack.isCompleted).length,
      completedScreenCount: packs.fold<int>(
        0,
        (total, pack) => total + pack.completedItemCount,
      ),
      writtenAnswerCount: packs.fold<int>(
        0,
        (total, pack) => total + pack.writtenAnswerCount,
      ),
      focusAreas: focusAreas.toList(),
      guidance:
          (packs.isEmpty ? null : packs.first.learningProfile?.guidance) ??
          'Complete more packs to unlock stronger personalization.',
    );
  }
}
