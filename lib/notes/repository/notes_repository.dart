import '../../common/result.dart';
import '../models/note.dart';

abstract class NotesRepository {
  Future<Result<List<Note>>> getNotes();
  Future<Result<Note>> createNote(Note note);
  Future<Result<Note>> updateNote(Note note);
  Future<Result<void>> deleteNote(String id);
}
