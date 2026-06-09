class Thought {
  final String id;
  final String theme;
  final String quote;
  final List<String> tags;
  final bool active;

  const Thought({
    required this.id,
    required this.theme,
    required this.quote,
    this.tags = const <String>[],
    this.active = true,
  });

  String get text => quote;

  factory Thought.fromMap({
    required String id,
    required Map<String, dynamic> data,
  }) {
    final rawTags = data['tags'];
    return Thought(
      id: id,
      theme: data['theme'] is String ? data['theme'] as String : 'general',
      quote: data['quote'] is String ? data['quote'] as String : '',
      tags: rawTags is List ? rawTags.whereType<String>().toList() : const [],
      active: data['active'] is bool ? data['active'] as bool : true,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'theme': theme,
      'quote': quote,
      'tags': tags,
      'active': active,
    };
  }
}
