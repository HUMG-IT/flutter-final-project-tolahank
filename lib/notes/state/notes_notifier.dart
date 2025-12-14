import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/note.dart';
import '../repository/notes_repository.dart';

class NotesState {
  final List<Note> notes;
  final bool isLoading;
  final String? error;
  final String searchKeyword;
  final String? selectedTag;
  final String sortMode; // created_desc | created_asc | status_created_desc
  final bool onlyUndone;

  const NotesState({
    this.notes = const [],
    this.isLoading = false,
    this.error,
    this.searchKeyword = '',
    this.selectedTag,
    this.sortMode = 'status_created_desc',
    this.onlyUndone = false,
  });

  NotesState copyWith({
    List<Note>? notes,
    bool? isLoading,
    String? error,
    String? searchKeyword,
    String? selectedTag,
    String? sortMode,
    bool? onlyUndone,
  }) {
    return NotesState(
      notes: notes ?? this.notes,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      searchKeyword: searchKeyword ?? this.searchKeyword,
      selectedTag: selectedTag ?? this.selectedTag,
      sortMode: sortMode ?? this.sortMode,
      onlyUndone: onlyUndone ?? this.onlyUndone,
    );
  }
}

class NotesNotifier extends StateNotifier<NotesState> {
  final NotesRepository _repo;
  NotesNotifier(this._repo) : super(const NotesState());

  Future<void> loadNotes() async {
    state = state.copyWith(isLoading: true, error: null);
    final res = await _repo.getNotes();
    state = state.copyWith(isLoading: false, notes: res.data ?? [], error: res.error);
  }

  Future<void> addNote(Note note) async {
    final res = await _repo.createNote(note);
    if (res.isSuccess) {
      state = state.copyWith(notes: [...state.notes, res.data!]);
    } else {
      state = state.copyWith(error: res.error);
    }
  }

  Future<void> updateNote(Note note) async {
    final res = await _repo.updateNote(note);
    if (res.isSuccess) {
      state = state.copyWith(notes: [
        for (final n in state.notes) if (n.id == note.id) res.data! else n,
      ]);
    } else {
      state = state.copyWith(error: res.error);
    }
  }

  Future<void> deleteNote(String id) async {
    final res = await _repo.deleteNote(id);
    if (res.isSuccess) {
      state = state.copyWith(notes: state.notes.where((n) => n.id != id).toList());
    } else {
      state = state.copyWith(error: res.error);
    }
  }

  void changeSearch(String keyword) {
    state = state.copyWith(searchKeyword: keyword);
  }

  void changeTag(String? tag) {
    // copyWith cannot set a field to null (null means "keep current"),
    // so use empty string to represent "All" (no tag filter).
    state = state.copyWith(selectedTag: tag ?? '');
  }

  void changeSortMode(String mode) {
    state = state.copyWith(sortMode: mode);
  }

  void changeOnlyUndone(bool value) {
    state = state.copyWith(onlyUndone: value);
  }

  List<Note> get filteredNotes {
    final keyword = state.searchKeyword.toLowerCase();
    final tag = state.selectedTag;
    final list = state.notes.where((n) {
      final matchesKeyword = keyword.isEmpty || n.title.toLowerCase().contains(keyword);
      final matchesTag = tag == null || tag.isEmpty || n.tags.contains(tag);
      final matchesDone = !state.onlyUndone || !n.isDone;
      return matchesKeyword && matchesTag && matchesDone;
    }).toList();

    switch (state.sortMode) {
      case 'created_desc':
        list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;
      case 'created_asc':
        list.sort((a, b) => a.createdAt.compareTo(b.createdAt));
        break;
      case 'status_created_desc':
      default:
        list.sort((a, b) {
          final done = (a.isDone == b.isDone) ? 0 : (a.isDone ? 1 : -1);
          if (done != 0) return done;
          return b.createdAt.compareTo(a.createdAt);
        });
        break;
    }
    return list;
  }
}
