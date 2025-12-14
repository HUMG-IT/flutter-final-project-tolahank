import 'package:uuid/uuid.dart';

class Item {
  final String id;
  final String title;
  final String status; // 'pending' | 'done'
  final DateTime? dueAt; // optional scheduled time
  final String? category; // optional category/tag
  final int priority; // 0 (low) .. 2 (high)
  final String? description; // optional description/details

  Item({String? id, required this.title, this.status = 'pending', this.dueAt, this.category, this.priority = 1, this.description})
      : id = id ?? const Uuid().v4();

  Item copyWith({String? id, String? title, String? status, DateTime? dueAt, String? category, int? priority, String? description}) {
    return Item(
      id: id ?? this.id,
      title: title ?? this.title,
      status: status ?? this.status,
      dueAt: dueAt ?? this.dueAt,
      category: category ?? this.category,
      priority: priority ?? this.priority,
      description: description ?? this.description,
    );
  }

  factory Item.fromJson(Map<String, dynamic> json) {
    return Item(
      id: json['id'] as String?,
      title: json['title'] as String? ?? '',
      status: json['status'] as String? ?? 'pending',
      dueAt: (json['dueAt'] as String?) != null ? DateTime.tryParse(json['dueAt'] as String) : null,
      category: json['category'] as String?,
      priority: (json['priority'] as int?) ?? 1,
      description: json['description'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'status': status,
      'dueAt': dueAt?.toIso8601String(),
      'category': category,
      'priority': priority,
      'description': description,
    };
  }
}
