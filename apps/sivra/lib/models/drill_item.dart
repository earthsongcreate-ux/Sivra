enum DrillItemType {
  briefing,
  concept,
  decision,
  scenario,
  articulation,
  review,
}

class DrillItemSource {
  final String title;
  final String publisher;
  final String dateLabel;
  final String url;
  final String? snippet;

  const DrillItemSource({
    required this.title,
    required this.publisher,
    required this.dateLabel,
    required this.url,
    this.snippet,
  });
}

class DrillItem {
  final String id;
  final DrillItemType type;
  final String prompt;
  final String? answer;
  final String? explanation;
  final DrillItemSource? source;

  const DrillItem({
    required this.id,
    required this.type,
    required this.prompt,
    this.answer,
    this.explanation,
    this.source,
  });

  bool get hasSource => source != null;
}

