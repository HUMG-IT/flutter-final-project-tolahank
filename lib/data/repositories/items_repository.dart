import 'package:sqlite3/sqlite3.dart' as sqlite;
import '../db/app_database.dart';
import '../../items/models/item.dart';

class ItemsRepository {
  sqlite.Database get _db => AppDatabase.instance;

  List<Item> getAll() {
    final rows = _db.select('SELECT id, title, description, status, priority, category, due_at FROM items');
    return rows.map((r) => Item(
      id: r['id'] as String,
      title: r['title'] as String,
      status: r['status'] as String,
      description: r['description'] as String?,
      priority: (r['priority'] as int?) ?? 1,
      category: r['category'] as String?,
      dueAt: (r['due_at'] as int?) != null ? DateTime.fromMillisecondsSinceEpoch(r['due_at'] as int) : null,
    )).toList();
  }

  void insert(Item item) {
    final stmt = _db.prepare('INSERT INTO items (id, title, description, status, priority, category, due_at) VALUES (?, ?, ?, ?, ?, ?, ?)');
    stmt.execute([
      item.id,
      item.title,
      item.description,
      item.status,
      item.priority,
      item.category,
      item.dueAt?.millisecondsSinceEpoch,
    ]);
    stmt.dispose();
  }

  void update(Item item) {
    final stmt = _db.prepare('UPDATE items SET title = ?, description = ?, status = ?, priority = ?, category = ?, due_at = ? WHERE id = ?');
    stmt.execute([
      item.title,
      item.description,
      item.status,
      item.priority,
      item.category,
      item.dueAt?.millisecondsSinceEpoch,
      item.id,
    ]);
    stmt.dispose();
  }

  void delete(String id) {
    final stmt = _db.prepare('DELETE FROM items WHERE id = ?');
    stmt.execute([id]);
    stmt.dispose();
  }
}