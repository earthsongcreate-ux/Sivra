import '../models/thought.dart';

class DailyThoughtEngine {
  final List<Thought> thoughts;

  const DailyThoughtEngine({this.thoughts = localDailyThoughts});

  Thought thoughtForDay({
    required String dayId,
    required List<String> focusAreas,
  }) {
    final themes = _activeThemes(focusAreas);
    final dayNumber = _dayNumber(dayId);
    final theme = themes[dayNumber % themes.length];
    final candidates = thoughts
        .where(
          (thought) =>
              thought.active &&
              normalizeDailyThoughtTheme(thought.theme) == theme,
        )
        .toList();
    final fallback = thoughts
        .where(
          (thought) =>
              thought.active &&
              normalizeDailyThoughtTheme(thought.theme) == 'founder',
        )
        .toList();
    final available = candidates.isEmpty ? fallback : candidates;

    if (available.isEmpty) {
      throw StateError('No active daily thoughts are available.');
    }

    final themeCycle = dayNumber ~/ themes.length;
    final quoteIndex = (themeCycle + _stableHash(theme)) % available.length;
    return available[quoteIndex];
  }

  List<String> _activeThemes(List<String> focusAreas) {
    final normalized = <String>[];
    for (final focusArea in focusAreas) {
      final theme = normalizeDailyThoughtTheme(focusArea);
      if (theme != 'general' && !normalized.contains(theme)) {
        normalized.add(theme);
      }
    }
    return normalized.isEmpty ? const <String>['founder'] : normalized;
  }

  static int _dayNumber(String dayId) {
    final date = DateTime.tryParse(dayId);
    if (date == null) {
      return _stableHash(dayId);
    }
    final utcDate = DateTime.utc(date.year, date.month, date.day);
    return utcDate.millisecondsSinceEpoch ~/ Duration.millisecondsPerDay;
  }

  static int _stableHash(String value) {
    return value.codeUnits.fold<int>(
      17,
      (hash, codeUnit) => (hash * 37 + codeUnit) & 0x7fffffff,
    );
  }
}

String normalizeDailyThoughtTheme(String value) {
  final normalized = value.trim().toLowerCase();
  return switch (normalized) {
    'product_strategy' ||
    'product strategy' ||
    'product / strategy' => 'product_strategy',
    'infrastructure_costs' ||
    'infra & costs' ||
    'infrastructure & costs' ||
    'infrastructure and costs' => 'infrastructure_costs',
    'hiring_team' ||
    'hiring & team' ||
    'hiring and team' ||
    'team' => 'hiring_team',
    'gtm_sales' || 'gtm & sales' || 'gtm and sales' || 'sales' => 'gtm_sales',
    'founder' => 'founder',
    'operator' => 'operator',
    'investor' => 'investor',
    'builder' => 'builder',
    'marketing' => 'marketing',
    _ => 'general',
  };
}

const localDailyThoughts = <Thought>[
  Thought(
    id: 'product_strategy_1',
    theme: 'product_strategy',
    quote: 'Features solve requests. Products solve problems.',
    tags: <String>['product', 'judgment'],
  ),
  Thought(
    id: 'product_strategy_2',
    theme: 'product_strategy',
    quote: 'Most product failures begin as assumptions.',
    tags: <String>['product', 'assumptions'],
  ),
  Thought(
    id: 'product_strategy_3',
    theme: 'product_strategy',
    quote: 'Distribution is a feature.',
    tags: <String>['product', 'distribution'],
  ),
  Thought(
    id: 'infrastructure_costs_1',
    theme: 'infrastructure_costs',
    quote: 'Every system eventually reveals its true cost.',
    tags: <String>['systems', 'cost'],
  ),
  Thought(
    id: 'infrastructure_costs_2',
    theme: 'infrastructure_costs',
    quote: 'Complexity compounds faster than cost savings.',
    tags: <String>['complexity', 'cost'],
  ),
  Thought(
    id: 'infrastructure_costs_3',
    theme: 'infrastructure_costs',
    quote: 'Reliability is cheaper than recovery.',
    tags: <String>['reliability', 'operations'],
  ),
  Thought(
    id: 'hiring_team_1',
    theme: 'hiring_team',
    quote: 'Hire for judgment. Train for skill.',
    tags: <String>['hiring', 'judgment'],
  ),
  Thought(
    id: 'hiring_team_2',
    theme: 'hiring_team',
    quote: 'Culture is what survives pressure.',
    tags: <String>['culture', 'team'],
  ),
  Thought(
    id: 'hiring_team_3',
    theme: 'hiring_team',
    quote: 'A weak hire taxes every strong one.',
    tags: <String>['hiring', 'team'],
  ),
  Thought(
    id: 'gtm_sales_1',
    theme: 'gtm_sales',
    quote: 'Attention is earned before it is converted.',
    tags: <String>['attention', 'sales'],
  ),
  Thought(
    id: 'gtm_sales_2',
    theme: 'gtm_sales',
    quote: 'Distribution beats invention more often than founders admit.',
    tags: <String>['distribution', 'gtm'],
  ),
  Thought(
    id: 'gtm_sales_3',
    theme: 'gtm_sales',
    quote: 'Clarity closes more deals than enthusiasm.',
    tags: <String>['clarity', 'sales'],
  ),
  Thought(
    id: 'founder_1',
    theme: 'founder',
    quote: 'The bottleneck usually sits in the calendar.',
    tags: <String>['founder', 'focus'],
  ),
  Thought(
    id: 'founder_2',
    theme: 'founder',
    quote: 'Decisions create momentum.',
    tags: <String>['founder', 'decisions'],
  ),
  Thought(
    id: 'founder_3',
    theme: 'founder',
    quote: 'Ambiguity is a founder’s recurring tax.',
    tags: <String>['founder', 'clarity'],
  ),
  Thought(
    id: 'operator_1',
    theme: 'operator',
    quote: 'Good systems remove recurring decisions.',
    tags: <String>['operator', 'systems'],
  ),
  Thought(
    id: 'operator_2',
    theme: 'operator',
    quote: 'Friction is usually hidden until scale.',
    tags: <String>['operator', 'scale'],
  ),
  Thought(
    id: 'operator_3',
    theme: 'operator',
    quote: 'Consistency beats intensity.',
    tags: <String>['operator', 'consistency'],
  ),
  Thought(
    id: 'investor_1',
    theme: 'investor',
    quote: 'Most outcomes are driven by a few decisions.',
    tags: <String>['investor', 'decisions'],
  ),
  Thought(
    id: 'investor_2',
    theme: 'investor',
    quote: 'Risk ignored becomes risk realized.',
    tags: <String>['investor', 'risk'],
  ),
  Thought(
    id: 'investor_3',
    theme: 'investor',
    quote: 'Optionality is often undervalued.',
    tags: <String>['investor', 'optionality'],
  ),
  Thought(
    id: 'builder_1',
    theme: 'builder',
    quote: 'Build less. Learn faster.',
    tags: <String>['builder', 'learning'],
  ),
  Thought(
    id: 'builder_2',
    theme: 'builder',
    quote: 'Speed matters when learning is the goal.',
    tags: <String>['builder', 'speed'],
  ),
  Thought(
    id: 'builder_3',
    theme: 'builder',
    quote: 'Every feature creates maintenance.',
    tags: <String>['builder', 'maintenance'],
  ),
  Thought(
    id: 'marketing_1',
    theme: 'marketing',
    quote: 'Positioning determines perception.',
    tags: <String>['marketing', 'positioning'],
  ),
  Thought(
    id: 'marketing_2',
    theme: 'marketing',
    quote: 'Attention without trust is temporary.',
    tags: <String>['marketing', 'trust'],
  ),
  Thought(
    id: 'marketing_3',
    theme: 'marketing',
    quote: 'Repetition creates recognition.',
    tags: <String>['marketing', 'recognition'],
  ),
];
