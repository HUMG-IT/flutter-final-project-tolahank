import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/item.dart';
import '../../data/repositories/items_repository_selected.dart';
// Conditional DB import: real DB on non-web, stub on web
import '../../data/db/app_database.dart'
  if (dart.library.html) '../../data/db/app_database_stub.dart';

final itemListProvider = StateNotifierProvider<ItemListNotifier, List<Item>>((ref) {
  final repo = ItemsRepository();
  return ItemListNotifier(repo, null);
});

class ItemListNotifier extends StateNotifier<List<Item>> {
  final ItemsRepository _repo;
  final Object? _webRepo; // unused, kept for minimal change

  ItemListNotifier(this._repo, this._webRepo) : super([]) {
    load();
  }

  Future<void> load() async {
    await AppDatabase.open();
    final items = _repo.getAll();
    state = items;
  }

  Future<void> add(Item item) async {
    try {
      _repo.insert(item);
      state = _sorted([...state, item]);
    } catch (e) {
      // Nếu insert fail, reload từ database
      await load();
    }
  }

  Future<void> update(Item item) async {
    try {
      _repo.update(item);
      final newState = [
        for (final i in state) if (i.id == item.id) item else i,
      ];
      state = _sorted(newState);
      print('✓ Updated item ${item.id}, state now has ${state.length} items');
    } catch (e) {
      print('✗ Update failed: $e');
      // Nếu update fail, reload từ database
      await load();
    }
  }

  Future<void> toggleStatus(String id) async {
    try {
      final idx = state.indexWhere((i) => i.id == id);
      if (idx == -1) {
        print('✗ Item not found: $id');
        return;
      }
      final current = state[idx];
      final updated = current.copyWith(status: current.status == 'pending' ? 'done' : 'pending');
      _repo.update(updated);
      final newState = [
        for (final i in state) if (i.id == id) updated else i,
      ];
      state = _sorted(newState);
      print('✓ Toggled status for ${id}, state now has ${state.length} items');
    } catch (e) {
      print('✗ Toggle failed: $e');
      // Nếu update fail, reload từ database
      await load();
    }
  }

  Future<void> remove(String id) async {
    try {
      _repo.delete(id);
      state = state.where((i) => i.id != id).toList();
    } catch (e) {
      // Nếu delete fail, reload từ database
      await load();
    }
  }

  List<Item> _sorted(List<Item> items) {
    final copy = [...items];
    copy.sort((a, b) {
      // Higher priority first, then earlier dueAt, then title
      final pr = b.priority.compareTo(a.priority);
      if (pr != 0) return pr;
      final aDue = a.dueAt?.millisecondsSinceEpoch ?? 1 << 31;
      final bDue = b.dueAt?.millisecondsSinceEpoch ?? 1 << 31;
      final dt = aDue.compareTo(bDue);
      if (dt != 0) return dt;
      return a.title.toLowerCase().compareTo(b.title.toLowerCase());
    });
    return copy;
  }
}
