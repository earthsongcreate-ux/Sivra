import 'daily_pack.dart';

class ArchiveEntry {
  final String id;
  final String text;
  final String theme;
  final DateTime createdAt;
  final String ritualId;

  const ArchiveEntry({
    required this.id,
    required this.text,
    required this.theme,
    required this.createdAt,
    required this.ritualId,
  });
}

class ThinkingArchive {
  final List<ArchiveEntry> entries;
  final int completedRitualCount;
  final List<String> themes;
  final String? strongestTheme;
  final ArchiveEntry? revisitEntry;

  const ThinkingArchive({
    required this.entries,
    required this.completedRitualCount,
    required this.themes,
    required this.strongestTheme,
    required this.revisitEntry,
  });

  const ThinkingArchive.empty()
    : entries = const <ArchiveEntry>[],
      completedRitualCount = 0,
      themes = const <String>[],
      strongestTheme = null,
      revisitEntry = null;

  factory ThinkingArchive.fromPacks(List<DailyPack> packs) {
    final completedPacks = packs.where((pack) => pack.isCompleted).toList();
    final entries = <ArchiveEntry>[];

    for (final pack in completedPacks) {
      final createdAt =
          pack.completedAt ?? DateTime.tryParse(pack.dayId) ?? DateTime(1970);
      final theme = pack.focusAreas.isEmpty
          ? 'General'
          : _themeLabel(pack.focusAreas.first);

      for (final answer in pack.answersByItemId.entries) {
        final text = answer.value.trim();
        if (text.isEmpty) {
          continue;
        }
        entries.add(
          ArchiveEntry(
            id: '${pack.dayId}-${answer.key}',
            text: text,
            theme: theme,
            createdAt: createdAt,
            ritualId: pack.dayId,
          ),
        );
      }
    }

    entries.sort((a, b) {
      final dateOrder = b.createdAt.compareTo(a.createdAt);
      return dateOrder != 0 ? dateOrder : b.id.compareTo(a.id);
    });

    final themeCounts = <String, int>{};
    for (final entry in entries) {
      themeCounts[entry.theme] = (themeCounts[entry.theme] ?? 0) + 1;
    }
    final rankedThemes = themeCounts.entries.toList()
      ..sort((a, b) {
        final frequency = b.value.compareTo(a.value);
        return frequency != 0 ? frequency : a.key.compareTo(b.key);
      });

    return ThinkingArchive(
      entries: entries,
      completedRitualCount: completedPacks.length,
      themes: rankedThemes.map((entry) => entry.key).toList(),
      strongestTheme: rankedThemes.isEmpty ? null : rankedThemes.first.key,
      revisitEntry: entries.length > 1 ? entries.last : entries.firstOrNull,
    );
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
}

extension<T> on List<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
