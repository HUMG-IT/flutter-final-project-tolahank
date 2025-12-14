import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/repositories/settings_repository_selected.dart';
import '../data/db/app_database.dart'
  if (dart.library.html) '../data/db/app_database_stub.dart';
import '../items/ui/item_list_screen.dart';
import '../items/providers/item_provider.dart';
import '../notes/ui/notes_list_page.dart';
import '../notes/state/notes_provider.dart';

class HomeScaffold extends ConsumerStatefulWidget {
  final List<Widget>? itemsActions;
  final List<Widget>? notesActions;
  final bool quietMode;
  const HomeScaffold({super.key, this.itemsActions, this.notesActions, this.quietMode = false});

  @override
  ConsumerState<HomeScaffold> createState() => _HomeScaffoldState();
}

class _HomeScaffoldState extends ConsumerState<HomeScaffold> {
  int _index = 0;
  bool _itemsFilterPending = false;
  bool _notesOnlyUndone = false;
  // Removed legacy Localstore settings doc reference.

  @override
  void initState() {
    super.initState();
    _loadHomePrefs();
  }

  Future<void> _loadHomePrefs() async {
    await AppDatabase.open();
    final s = SettingsRepository();
    final idxStr = s.getValue('home_tabIndex');
    final itemsPendingStr = s.getValue('home_itemsFilterPending');
    final notesUndoneStr = s.getValue('home_notesOnlyUndone');
    setState(() {
      if (idxStr != null) _index = int.tryParse(idxStr) ?? _index;
      if (itemsPendingStr != null) _itemsFilterPending = itemsPendingStr == 'true';
      if (notesUndoneStr != null) _notesOnlyUndone = notesUndoneStr == 'true';
    });
  }

  Future<void> _persistHomePrefs() async {
    final s = SettingsRepository();
    await s.setValue('home_tabIndex', _index.toString());
    await s.setValue('home_itemsFilterPending', _itemsFilterPending.toString());
    await s.setValue('home_notesOnlyUndone', _notesOnlyUndone.toString());
  }

  @override
  Widget build(BuildContext context) {
    final items = ref.watch(itemListProvider);
    final pendingCount = items.where((i) => i.status == 'pending').length;
    final notesState = ref.watch(notesProvider);
    final notesTodoCount = notesState.notes.where((n) => !n.isDone).length;

    return Scaffold(
      body: IndexedStack(
        index: _index,
        children: [
          ItemListScreen(key: ValueKey('items-${_itemsFilterPending ? 'pending' : 'all'}'), actions: widget.itemsActions, initialStatusFilter: _itemsFilterPending ? 'Pending' : 'All'),
          NotesListPage(actions: widget.notesActions),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        destinations: [
          NavigationDestination(
            icon: _withBadge(
              const Icon(Icons.list),
              pendingCount,
              'Mẹo: bấm lại để lọc Chờ xử lý/Tất cả',
            ),
            label: 'Danh sách',
          ),
          NavigationDestination(
            icon: _withBadge(
              const Icon(Icons.note),
              notesTodoCount,
              'Mẹo: bấm lại để lọc Chưa xong/Tất cả',
            ),
            label: 'Notes',
          ),
        ],
        onDestinationSelected: (i) {
          if (i == _index) {
            if (i == 0) {
              setState(() => _itemsFilterPending = !_itemsFilterPending);
              _persistHomePrefs();
              if (!widget.quietMode) {
                final msg = _itemsFilterPending ? 'Đang lọc: Chờ xử lý' : 'Đang lọc: Tất cả';
                ScaffoldMessenger.of(context)
                  ..hideCurrentSnackBar()
                  ..showSnackBar(SnackBar(content: Text(msg), duration: const Duration(seconds: 2)));
              }
            } else {
              setState(() => _notesOnlyUndone = !_notesOnlyUndone);
              ref.read(notesProvider.notifier).changeOnlyUndone(_notesOnlyUndone);
              _persistHomePrefs();
              if (!widget.quietMode) {
                final msg = _notesOnlyUndone ? 'Đang lọc: Chưa xong' : 'Đang lọc: Tất cả';
                ScaffoldMessenger.of(context)
                  ..hideCurrentSnackBar()
                  ..showSnackBar(SnackBar(content: Text(msg), duration: const Duration(seconds: 2)));
              }
            }
          } else {
            setState(() => _index = i);
            _persistHomePrefs();
          }
        },
      ),
    );
  }

  Widget _withBadge(Widget icon, int count, String tooltip) {
    final display = count > 99 ? '99+' : (count > 0 ? '$count' : '');
    final badge = display.isEmpty
        ? icon
        : Stack(
            clipBehavior: Clip.none,
            children: [
              icon,
              Positioned(
                right: -6,
                top: -6,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.error,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    display,
                    style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                ),
              )
            ],
          );
    return Tooltip(message: tooltip, child: badge);
  }
}
