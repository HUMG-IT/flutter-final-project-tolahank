import 'package:sqlite3/sqlite3.dart' as sqlite;
import '../../common/result.dart';
import '../models/note.dart';
import '../../data/db/app_database.dart';
import 'notes_repository.dart';

class NotesRepositorySqlite implements NotesRepository {
  sqlite.Database get _db => AppDatabase.instance;

  @override
  Future<Result<List<Note>>> getNotes() async {
    try {
      final rows = _db.select('SELECT id, title, content, tag, created_at, updated_at, is_done FROM notes ORDER BY updated_at DESC');
      final notes = rows.map(_fromRow).toList();
      return Result.success(notes);
    } catch (e) {
      return Result.failure('Không thể đọc ghi chú');
    }
  }

  @override
  Future<Result<Note>> createNote(Note note) async {
      try {
        final stmt = _db.prepare('INSERT INTO notes (title, content, tag, created_at, updated_at, is_done) VALUES (?, ?, ?, ?, ?, ?)');
        stmt.execute([
          note.title,
          note.content,
          note.tags.isNotEmpty ? note.tags.first : '',
          note.createdAt.millisecondsSinceEpoch,
          DateTime.now().millisecondsSinceEpoch,
          note.isDone ? 1 : 0,
        ]);
        stmt.dispose();
        final idRow = _db.select('SELECT last_insert_rowid() AS id').first;
        final created = note.copyWith(id: idRow['id'].toString());
        return Result.success(created);
      } catch (e) {
        return Result.failure('Không thể tạo ghi chú');
      }
  }

  @override
  Future<Result<Note>> updateNote(Note note) async {
    try {
      final stmt = _db.prepare('UPDATE notes SET title = ?, content = ?, tag = ?, updated_at = ?, is_done = ? WHERE id = ?');
      stmt.execute([
        note.title,
        note.content,
        note.tags.isNotEmpty ? note.tags.first : '',
        DateTime.now().millisecondsSinceEpoch,
        note.isDone ? 1 : 0,
        int.tryParse(note.id) ?? note.id,
      ]);
      stmt.dispose();
      return Result.success(note);
    } catch (e) {
      return Result.failure('Không thể cập nhật ghi chú');
    }
  }

  @override
  Future<Result<void>> deleteNote(String id) async {
    try {
      final stmt = _db.prepare('DELETE FROM notes WHERE id = ?');
      stmt.execute([int.tryParse(id) ?? id]);
      stmt.dispose();
      return Result.success(null);
    } catch (e) {
      return Result.failure('Không thể xóa ghi chú');
    }
  }

  Note _fromRow(sqlite.Row row) {
    final tag = (row['tag'] as String?) ?? '';
    return Note(
      id: (row['id']).toString(),
      title: row['title'] as String,
      content: row['content'] as String,
      tags: tag.isEmpty ? <String>[] : [tag],
      createdAt: DateTime.fromMillisecondsSinceEpoch(row['created_at'] as int),
      isDone: (row['is_done'] as int? ?? 0) == 1,
    );
  }
}