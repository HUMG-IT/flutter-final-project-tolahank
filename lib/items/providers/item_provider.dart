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
    _repo.insert(item);
    state = _sorted([...state, item]);
  }

  Future<void> update(Item item) async {
    _repo.update(item);
    state = _sorted([
      for (final i in state) if (i.id == item.id) item else i,
    ]);
  }

  Future<void> toggleStatus(String id) async {
    final idx = state.indexWhere((i) => i.id == id);
    if (idx == -1) return;
    final current = state[idx];
    final updated = current.copyWith(status: current.status == 'pending' ? 'done' : 'pending');
    _repo.update(updated);
    state = _sorted([
      for (final i in state) if (i.id == id) updated else i,
    ]);
  }

  Future<void> remove(String id) async {
    _repo.delete(id);
    state = state.where((i) => i.id != id).toList();
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
