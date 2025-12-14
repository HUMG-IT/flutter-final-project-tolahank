import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../state/notes_notifier.dart';
import '../repository/notes_repository.dart';
import '../repository/notes_repository_selected.dart';

final notesProvider = StateNotifierProvider<NotesNotifier, NotesState>((ref) {
  final repo = NotesRepositorySqlite();
  final notifier = NotesNotifier(repo);
  notifier.loadNotes();
  return notifier;
});
