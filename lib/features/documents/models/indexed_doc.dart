class IndexedDocument {
  final String id;
  final String name;
  final String extension;
  final int chunkCount;
  final DateTime dateAdded;
  final Map<String, dynamic> metadata;
  final String? previewText;

  const IndexedDocument({
    required this.id,
    required this.name,
    required this.extension,
    required this.chunkCount,
    required this.dateAdded,
    this.metadata = const {},
    this.previewText,
  });

  IndexedDocument copyWith({
    String? id,
    String? name,
    String? extension,
    int? chunkCount,
    DateTime? dateAdded,
    Map<String, dynamic>? metadata,
    String? previewText,
  }) {
    return IndexedDocument(
      id: id ?? this.id,
      name: name ?? this.name,
      extension: extension ?? this.extension,
      chunkCount: chunkCount ?? this.chunkCount,
      dateAdded: dateAdded ?? this.dateAdded,
      metadata: metadata ?? this.metadata,
      previewText: previewText ?? this.previewText,
    );
  }
}
