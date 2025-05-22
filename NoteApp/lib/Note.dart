class Note {
  final int id;
  final String title;
  final String content;
  final int? categoryId;
  final DateTime createdAt;
  final bool isFavorite; // New field

  Note({
    required this.id,
    required this.title,
    required this.content,
    this.categoryId,
    required this.createdAt,
    this.isFavorite = false, // Default to false
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'categoryId': categoryId,
      'createdAt': createdAt.toIso8601String(),
      'isFavorite': isFavorite, // Include in map
    };
  }

  static Note fromMap(Map<String, dynamic> map) {
    return Note(
      id: map['id'],
      title: map['title'],
      content: map['content'],
      categoryId: map['categoryId'],
      createdAt: DateTime.parse(map['createdAt']),
      isFavorite: map['isFavorite'] ?? false, // Handle null for older notes
    );
  }
}