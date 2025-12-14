import '../../common/result.dart';
import '../models/note.dart';
import 'notes_repository.dart';

class NotesRepositorySqlite implements NotesRepository {
  static final NotesRepositorySqlite _instance = NotesRepositorySqlite._();
  factory NotesRepositorySqlite() => _instance;
  NotesRepositorySqlite._();

  final List<Note> _notes = [];

  @override
  Future<Result<List<Note>>> getNotes() async {
    return Result.success(List.unmodifiable(_notes));
  }

  @override
  Future<Result<Note>> createNote(Note note) async {
    _notes.add(note);
    return Result.success(note);
  }

  @override
  Future<Result<Note>> updateNote(Note note) async {
    final i = _notes.indexWhere((e) => e.id == note.id);
    if (i != -1) {
      _notes[i] = note;
      return Result.success(note);
    }
    return Result.failure('Không tìm thấy ghi chú để cập nhật');
  }

  @override
  Future<Result<void>> deleteNote(String id) async {
    _notes.removeWhere((e) => e.id == id);
    return Result.success(null);
  }
}