enum DrillItemType {
  briefing,
  concept,
  decision,
  scenario,
  articulation,
  review,
}

extension DrillItemTypeCodec on DrillItemType {
  String get value => name;

  static DrillItemType fromValue(String? value) {
    return DrillItemType.values.firstWhere(
      (type) => type.name == value,
      orElse: () => DrillItemType.concept,
    );
  }
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

  factory DrillItemSource.fromMap(Map<String, dynamic> data) {
    return DrillItemSource(
      title: data['title'] is String ? data['title'] as String : '',
      publisher: data['publisher'] is String ? data['publisher'] as String : '',
      dateLabel: data['dateLabel'] is String ? data['dateLabel'] as String : '',
      url: data['url'] is String ? data['url'] as String : '',
      snippet: data['snippet'] is String ? data['snippet'] as String : null,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'title': title,
      'publisher': publisher,
      'dateLabel': dateLabel,
      'url': url,
      if (snippet != null) 'snippet': snippet,
    };
  }
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

  factory DrillItem.fromMap(Map<String, dynamic> data) {
    final source = data['source'];

    return DrillItem(
      id: data['id'] is String ? data['id'] as String : '',
      type: DrillItemTypeCodec.fromValue(
        data['type'] is String ? data['type'] as String : null,
      ),
      prompt: data['prompt'] is String ? data['prompt'] as String : '',
      answer: data['answer'] is String ? data['answer'] as String : null,
      explanation: data['explanation'] is String
          ? data['explanation'] as String
          : null,
      source: source is Map<String, dynamic>
          ? DrillItemSource.fromMap(source)
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'type': type.value,
      'prompt': prompt,
      if (answer != null) 'answer': answer,
      if (explanation != null) 'explanation': explanation,
      if (source != null) 'source': source!.toMap(),
    };
  }
}
