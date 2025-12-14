import '../../common/result.dart';
import '../models/note.dart';
import 'notes_repository.dart';

// Localstore removed. Keep a stub that implements NotesRepository.
class NotesRepositoryLocal implements NotesRepository {
  NotesRepositoryLocal();

  @override
  Future<Result<Note>> createNote(Note note) async {
    return Result.failure('Localstore đã bị loại bỏ');
  }

  @override
  Future<Result<void>> deleteNote(String id) async {
    return Result.failure('Localstore đã bị loại bỏ');
  }

  @override
  Future<Result<List<Note>>> getNotes() async {
    return Result.success(<Note>[]);
  }

  @override
  Future<Result<Note>> updateNote(Note note) async {
    return Result.failure('Localstore đã bị loại bỏ');
  }
}
