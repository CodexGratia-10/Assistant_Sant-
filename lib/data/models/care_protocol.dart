class CareProtocol {
  final String id;
  final String disease;
  final String category; // 'diagnosis', 'treatment', 'prevention'
  final String title;
  final String content;
  final List<String> keywords;
  final String locale;

  CareProtocol({
    required this.id,
    required this.disease,
    required this.category,
    required this.title,
    required this.content,
    this.keywords = const [],
    this.locale = 'fr',
  });

  Map<String, Object?> toMap() => {
        'id': id,
        'disease': disease,
        'category': category,
        'title': title,
        'content': content,
        'keywords': keywords.join(','),
        'locale': locale,
      };

  static CareProtocol fromMap(Map<String, Object?> map) => CareProtocol(
        id: map['id'] as String,
        disease: map['disease'] as String,
        category: map['category'] as String,
        title: map['title'] as String,
        content: map['content'] as String,
        keywords: (map['keywords'] as String?)?.split(',') ?? [],
        locale: map['locale'] as String? ?? 'fr',
      );
}
