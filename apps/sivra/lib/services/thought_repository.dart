import '../models/thought.dart';
import 'daily_thought_engine.dart';

abstract interface class ThoughtRepository {
  Thought getThoughtForTheme(String theme, {String? seed});
}

class LocalThoughtRepository implements ThoughtRepository {
  final DailyThoughtEngine engine;

  const LocalThoughtRepository() : engine = const DailyThoughtEngine();

  LocalThoughtRepository.withThoughts(List<Thought> thoughts)
    : engine = DailyThoughtEngine(thoughts: thoughts);

  @override
  Thought getThoughtForTheme(String theme, {String? seed}) {
    return engine.thoughtForDay(
      dayId: seed ?? DateTime.now().toIso8601String().split('T').first,
      focusAreas: <String>[theme],
    );
  }
}

String normalizeThoughtTheme(String value) => normalizeDailyThoughtTheme(value);

const localThoughts = localDailyThoughts;
