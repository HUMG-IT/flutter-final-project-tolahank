class Note {
  final String id;
  final String title;
  final String content;
  final bool isDone;
  final DateTime createdAt;
  final List<String> tags;

  const Note({
    required this.id,
    required this.title,
    required this.content,
    required this.isDone,
    required this.createdAt,
    required this.tags,
  });

  Note copyWith({
    String? id,
    String? title,
    String? content,
    bool? isDone,
    DateTime? createdAt,
    List<String>? tags,
  }) {
    return Note(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      isDone: isDone ?? this.isDone,
      createdAt: createdAt ?? this.createdAt,
      tags: tags ?? this.tags,
    );
  }

  factory Note.fromJson(Map<String, dynamic> json) {
    return Note(
      id: json['id'] as String,
      title: json['title'] as String,
      content: (json['content'] ?? '') as String,
      isDone: (json['isDone'] ?? false) as bool,
      createdAt: DateTime.parse(json['createdAt'] as String),
      tags: (json['tags'] as List?)?.map((e) => e.toString()).toList() ?? const [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'isDone': isDone,
      'createdAt': createdAt.toIso8601String(),
      'tags': tags,
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Note &&
        other.id == id &&
        other.title == title &&
        other.content == content &&
        other.isDone == isDone &&
        other.createdAt == createdAt &&
        _listEquals(other.tags, tags);
  }

  @override
  int get hashCode => Object.hash(id, title, content, isDone, createdAt, Object.hashAll(tags));
}

bool _listEquals<T>(List<T> a, List<T> b) {
  if (identical(a, b)) return true;
  if (a.length != b.length) return false;
  for (int i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}
