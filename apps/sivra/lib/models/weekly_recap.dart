import 'daily_pack.dart';

class WeeklyTheme {
  final String name;
  final int ritualCount;

  const WeeklyTheme({required this.name, required this.ritualCount});
}

class WeeklyRecap {
  final int packCount;
  final int completedPackCount;
  final int completedScreenCount;
  final int writtenAnswerCount;
  final List<WeeklyTheme> primaryThemes;
  final List<String> thinkingPatterns;
  final String? mostValuableInsight;
  final String? insightTheme;
  final String lookingAhead;

  const WeeklyRecap({
    required this.packCount,
    required this.completedPackCount,
    required this.completedScreenCount,
    required this.writtenAnswerCount,
    required this.primaryThemes,
    required this.thinkingPatterns,
    required this.mostValuableInsight,
    required this.insightTheme,
    required this.lookingAhead,
  });

  const WeeklyRecap.empty()
    : packCount = 0,
      completedPackCount = 0,
      completedScreenCount = 0,
      writtenAnswerCount = 0,
      primaryThemes = const <WeeklyTheme>[],
      thinkingPatterns = const <String>[],
      mostValuableInsight = null,
      insightTheme = null,
      lookingAhead = '';

  bool get hasCompletedRituals => completedPackCount > 0;

  List<String> get focusAreas =>
      primaryThemes.map((theme) => theme.name).toList();

  factory WeeklyRecap.fromPacks(
    List<DailyPack> packs, {
    DateTime? referenceDate,
  }) {
    final end = _calendarDay(referenceDate ?? DateTime.now());
    final start = end.subtract(const Duration(days: 6));
    final weeklyPacks = packs.where((pack) {
      final date = DateTime.tryParse(pack.dayId);
      if (date == null) {
        return false;
      }
      final day = _calendarDay(date);
      return !day.isBefore(start) && !day.isAfter(end);
    }).toList();
    final completed = weeklyPacks.where((pack) => pack.isCompleted).toList()
      ..sort((a, b) => b.dayId.compareTo(a.dayId));

    if (completed.isEmpty) {
      return WeeklyRecap(
        packCount: weeklyPacks.length,
        completedPackCount: 0,
        completedScreenCount: 0,
        writtenAnswerCount: 0,
        primaryThemes: const <WeeklyTheme>[],
        thinkingPatterns: const <String>[],
        mostValuableInsight: null,
        insightTheme: null,
        lookingAhead: '',
      );
    }

    final themeCounts = <String, int>{};
    for (final pack in completed) {
      for (final theme in pack.focusAreas.toSet()) {
        final label = _themeLabel(theme);
        themeCounts[label] = (themeCounts[label] ?? 0) + 1;
      }
    }
    final rankedThemes =
        themeCounts.entries
            .map(
              (entry) => WeeklyTheme(name: entry.key, ritualCount: entry.value),
            )
            .toList()
          ..sort((a, b) {
            final frequency = b.ritualCount.compareTo(a.ritualCount);
            return frequency != 0 ? frequency : a.name.compareTo(b.name);
          });
    final primaryThemes = rankedThemes.take(3).toList();
    final insight = _latestInsight(completed);

    return WeeklyRecap(
      packCount: weeklyPacks.length,
      completedPackCount: completed.length,
      completedScreenCount: completed.fold<int>(
        0,
        (total, pack) => total + pack.completedItemCount,
      ),
      writtenAnswerCount: completed.fold<int>(
        0,
        (total, pack) => total + pack.writtenAnswerCount,
      ),
      primaryThemes: primaryThemes,
      thinkingPatterns: _thinkingPatterns(completed, primaryThemes),
      mostValuableInsight: insight?.answer,
      insightTheme: insight?.theme,
      lookingAhead: _lookingAhead(primaryThemes, insight),
    );
  }

  static List<String> _thinkingPatterns(
    List<DailyPack> completed,
    List<WeeklyTheme> themes,
  ) {
    final patterns = <String>[];
    for (final theme in themes.take(2)) {
      final count = theme.ritualCount;
      patterns.add(
        count == 1
            ? '${theme.name} appeared in one completed ritual.'
            : 'You returned to ${theme.name} $count times this week.',
      );
    }

    if (_shiftedTowardExecution(completed)) {
      patterns.add(
        'Your focus shifted toward execution during the second half of the week.',
      );
    } else {
      final writtenCount = completed.fold<int>(
        0,
        (total, pack) => total + pack.writtenAnswerCount,
      );
      if (writtenCount > 0) {
        patterns.add(
          writtenCount == 1
              ? 'You captured one idea worth revisiting.'
              : 'You captured $writtenCount ideas worth revisiting.',
        );
      }
    }

    return patterns.take(3).toList();
  }

  static bool _shiftedTowardExecution(List<DailyPack> completed) {
    if (completed.length < 4) {
      return false;
    }
    final chronological = completed.toList()
      ..sort((a, b) => a.dayId.compareTo(b.dayId));
    final split = chronological.length ~/ 2;
    final firstHalf = chronological.take(split).toList();
    final secondHalf = chronological.skip(split).toList();

    int executionMentions(List<DailyPack> packs) {
      return packs.fold<int>(
        0,
        (total, pack) =>
            total +
            pack.focusAreas.where((theme) => _isExecutionTheme(theme)).length,
      );
    }

    return executionMentions(secondHalf) > executionMentions(firstHalf);
  }

  static bool _isExecutionTheme(String theme) {
    final normalized = theme.trim().toLowerCase();
    return normalized == 'infra & costs' ||
        normalized == 'infrastructure & costs' ||
        normalized == 'hiring & team' ||
        normalized == 'operator' ||
        normalized == 'builder';
  }

  static _WeeklyInsight? _latestInsight(List<DailyPack> completed) {
    for (final pack in completed) {
      for (final answer in pack.answersByItemId.values.toList().reversed) {
        final trimmed = answer.trim();
        if (trimmed.isNotEmpty) {
          return _WeeklyInsight(
            answer: trimmed,
            theme: pack.focusAreas.isEmpty
                ? null
                : _themeLabel(pack.focusAreas.first),
          );
        }
      }
    }
    return null;
  }

  static String _lookingAhead(
    List<WeeklyTheme> themes,
    _WeeklyInsight? insight,
  ) {
    if (themes.isEmpty) {
      return '';
    }
    final strongest = themes.first;
    if (insight?.theme == strongest.name) {
      return 'Revisit your recent thinking on ${strongest.name}.';
    }
    if (strongest.ritualCount >= 3) {
      return 'Go deeper on ${strongest.name}; it repeatedly held your attention.';
    }
    return 'Continue exploring ${strongest.name}.';
  }

  static String _themeLabel(String value) {
    final normalized = value.trim().toLowerCase();
    return switch (normalized) {
      'infra & costs' ||
      'infrastructure & costs' ||
      'infrastructure and costs' => 'Infrastructure & Costs',
      'gtm & sales' || 'gtm and sales' => 'GTM & Sales',
      'hiring & team' || 'hiring and team' => 'Hiring & Team',
      'product / strategy' || 'product strategy' => 'Product Strategy',
      _ =>
        value
            .trim()
            .split(RegExp(r'\s+'))
            .map(
              (word) => word.isEmpty
                  ? word
                  : '${word[0].toUpperCase()}${word.substring(1)}',
            )
            .join(' '),
    };
  }

  static DateTime _calendarDay(DateTime value) {
    return DateTime(value.year, value.month, value.day);
  }
}

class _WeeklyInsight {
  final String answer;
  final String? theme;

  const _WeeklyInsight({required this.answer, required this.theme});
}
