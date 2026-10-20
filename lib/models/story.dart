class Story {
  final String id;
  final String headline;
  final DateTime updatedAt;
  final int publisherCount;
  final List<String> publishers;
  final String? overview;
  final List<SourceArticle> sources;
  final List<BackgroundResource> background;
  final AiAnalysis? ai;

  const Story({
    required this.id,
    required this.headline,
    required this.updatedAt,
    required this.publisherCount,
    this.publishers = const [],
    this.overview,
    this.sources = const [],
    this.background = const [],
    this.ai,
  });

  factory Story.fromJson(Map<String, dynamic> json) {
    return Story(
      id: json['id'].toString(),
      headline: json['headline'] ?? 'Untitled story',
      updatedAt: DateTime.tryParse(json['updatedAt'] ?? '') ?? DateTime.now(),
      publisherCount: json['publisherCount'] ?? 0,
      publishers: (json['publishers'] as List? ?? [])
          .map((e) => e.toString())
          .toList(),
      overview: json['overview'],
      sources: (json['sources'] as List? ?? [])
          .map((e) => SourceArticle.fromJson(e))
          .toList(),
      background: (json['background'] as List? ?? [])
          .map((e) => BackgroundResource.fromJson(e))
          .toList(),
      ai: json['ai'] == null ? null : AiAnalysis.fromJson(json['ai']),
    );
  }
}

class SourceArticle {
  final String publisher;
  final String title;
  final String url;
  final DateTime? publishedAt;

  const SourceArticle({
    required this.publisher,
    required this.title,
    required this.url,
    this.publishedAt,
  });

  factory SourceArticle.fromJson(Map<String, dynamic> json) {
    return SourceArticle(
      publisher: json['publisher'] ?? 'Unknown publisher',
      title: json['title'] ?? 'Article',
      url: json['url'] ?? '',
      publishedAt: DateTime.tryParse(json['publishedAt'] ?? ''),
    );
  }
}

class BackgroundResource {
  final String label;
  final String url;

  const BackgroundResource({required this.label, required this.url});

  factory BackgroundResource.fromJson(Map<String, dynamic> json) {
    return BackgroundResource(
      label: json['label'] ?? 'Background resource',
      url: json['url'] ?? '',
    );
  }
}

class AiPerspective {
  final String name;
  final String text;
  final List<int> supportingArticleIndexes;

  const AiPerspective({
    required this.name,
    required this.text,
    this.supportingArticleIndexes = const [],
  });

  factory AiPerspective.fromJson(Map<String, dynamic> json) {
    return AiPerspective(
      name: json['name'] ?? 'Perspective',
      text: json['text'] ?? '',
      supportingArticleIndexes:
          (json['supportingArticleIndexes'] as List? ?? [])
              .map((e) => int.tryParse(e.toString()) ?? 0)
              .toList(),
    );
  }
}

class AiAnalysis {
  final String overview;
  final String? agreement;
  final String? uncertainty;
  final DateTime? generatedAt;
  final String? inputScope;
  final List<AiPerspective> perspectives;
  final String status;

  const AiAnalysis({
    required this.overview,
    this.agreement,
    this.uncertainty,
    this.generatedAt,
    this.inputScope,
    this.perspectives = const [],
    this.status = 'available',
  });

  factory AiAnalysis.fromJson(Map<String, dynamic> json) {
    return AiAnalysis(
      overview: json['overview'] ?? '',
      agreement: json['agreement'],
      uncertainty: json['uncertainty'],
      generatedAt: DateTime.tryParse(json['generatedAt'] ?? ''),
      inputScope: json['inputScope'],
      perspectives: (json['perspectives'] as List? ?? [])
          .map((e) => AiPerspective.fromJson(e))
          .toList(),
      status: json['status'] ?? 'available',
    );
  }
}
