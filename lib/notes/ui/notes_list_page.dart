import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../data/repositories/settings_repository_selected.dart';
import '../../data/db/app_database.dart'
    if (dart.library.html) '../../data/db/app_database_stub.dart';
import '../state/notes_provider.dart';
import '../models/note.dart';
import 'note_detail_page.dart';

class NotesListPage extends ConsumerStatefulWidget {
  final List<Widget>? actions;
  final String settingsDoc;
  const NotesListPage({super.key, this.actions, this.settingsDoc = 'settings'});

  @override
  ConsumerState<NotesListPage> createState() => _NotesListPageState();
}

class _NotesListPageState extends ConsumerState<NotesListPage> {
  late final TextEditingController _searchCtrl;

  @override
  void initState() {
    super.initState();
    _searchCtrl = TextEditingController();
    _loadPrefs();
  }

  Future<void> _loadPrefs() async {
    await AppDatabase.open();
    final s = SettingsRepository();
    final String? search = s.getValue('notesSearchKeyword');
    final String? sort = s.getValue('notesSortMode');
    final String? tag = s.getValue('notesSelectedTag');
    if (search != null && search.isNotEmpty) {
      _searchCtrl.text = search;
      ref.read(notesProvider.notifier).changeSearch(search);
    }
    if (sort != null) {
      ref.read(notesProvider.notifier).changeSortMode(sort);
    }
    ref.read(notesProvider.notifier).changeTag(tag);
  }

  Future<void> _persistPrefs(
      {String? sortMode, String? selectedTag, String? searchKeyword}) async {
    final s = SettingsRepository();
    if (searchKeyword != null)
      await s.setValue('notesSearchKeyword', searchKeyword);
    if (sortMode != null) await s.setValue('notesSortMode', sortMode);
    if (selectedTag != null) {
      await s.setValue('notesSelectedTag', selectedTag);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(notesProvider);
    final notifier = ref.read(notesProvider.notifier);
    final notes = notifier.filteredNotes;
    final allTags = {
      for (final n in state.notes) ...n.tags,
    }.toList()
      ..sort();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Công việc'),
        actions: [
          if (widget.actions != null) ...widget.actions!,
          IconButton(
            tooltip: 'Tạo dữ liệu demo',
            icon: const Icon(Icons.auto_awesome),
            onPressed: _seedDemoNotes,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            Card(
              elevation: 0,
              clipBehavior: Clip.antiAlias,
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(
                    color: Theme.of(context).colorScheme.outlineVariant),
              ),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        key: const Key('notesSearchField'),
                        controller: _searchCtrl,
                        decoration: const InputDecoration(
                          prefixIcon: Icon(Icons.search),
                          hintText: 'Tìm theo tiêu đề...',
                          filled: true,
                          isDense: true,
                          border: OutlineInputBorder(),
                        ),
                        onChanged: (v) {
                          notifier.changeSearch(v);
                          _persistPrefs(
                              searchKeyword: v,
                              sortMode: state.sortMode,
                              selectedTag: state.selectedTag ?? '');
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        key: const Key('notesSortDropdown'),
                        initialValue: state.sortMode,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          isDense: true,
                          border: OutlineInputBorder(),
                          labelText: 'Sắp xếp',
                        ),
                        items: const [
                          DropdownMenuItem(
                              value: 'status_created_desc',
                              child: Text('Trạng thái + Mới nhất')),
                          DropdownMenuItem(
                              value: 'created_desc', child: Text('Mới nhất')),
                          DropdownMenuItem(
                              value: 'created_asc', child: Text('Cũ nhất')),
                        ],
                        onChanged: (v) {
                          if (v != null) {
                            notifier.changeSortMode(v);
                            _persistPrefs(
                                sortMode: v,
                                selectedTag: state.selectedTag ?? '');
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 40,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: const Text('All'),
                      selected: state.selectedTag == null ||
                          state.selectedTag!.isEmpty,
                      onSelected: (_) {
                        notifier.changeTag(null);
                        _persistPrefs(
                            sortMode: state.sortMode, selectedTag: '');
                      },
                    ),
                  ),
                  for (final tag in allTags)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(tag),
                        selected: state.selectedTag == tag,
                        onSelected: (_) {
                          notifier.changeTag(tag);
                          _persistPrefs(
                              sortMode: state.sortMode, selectedTag: tag);
                        },
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: notes.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.note_add_outlined,
                              size: 80,
                              color: Theme.of(context).colorScheme.outline),
                          const SizedBox(height: 16),
                          Text(
                            'Chưa có công việc',
                            style: Theme.of(context).textTheme.headlineSmall,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Nhấn nút + để tạo công việc mới',
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurfaceVariant,
                                ),
                          ),
                        ],
                      ),
                    )
                  : ListView.separated(
                      itemCount: notes.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final n = notes[index];
                        return Card(
                          elevation: 0,
                          clipBehavior: Clip.antiAlias,
                          color: n.isDone
                              ? Theme.of(context)
                                  .colorScheme
                                  .surfaceContainerLow
                              : Theme.of(context).colorScheme.surface,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                            side: BorderSide(
                              color: n.isDone
                                  ? Theme.of(context)
                                      .colorScheme
                                      .outline
                                      .withOpacity(0.3)
                                  : Theme.of(context)
                                      .colorScheme
                                      .primary
                                      .withOpacity(0.3),
                              width: 1,
                            ),
                          ),
                          child: InkWell(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) => NoteDetailPage(initial: n)),
                              );
                            },
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        n.isDone
                                            ? Icons.check_circle
                                            : Icons.radio_button_unchecked,
                                        color: n.isDone
                                            ? Theme.of(context)
                                                .colorScheme
                                                .primary
                                            : Theme.of(context)
                                                .colorScheme
                                                .outline,
                                        size: 24,
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Text(
                                          n.title,
                                          style: Theme.of(context)
                                              .textTheme
                                              .titleMedium
                                              ?.copyWith(
                                                fontWeight: FontWeight.bold,
                                                decoration: n.isDone
                                                    ? TextDecoration.lineThrough
                                                    : null,
                                                color: n.isDone
                                                    ? Theme.of(context)
                                                        .colorScheme
                                                        .onSurfaceVariant
                                                    : Theme.of(context)
                                                        .colorScheme
                                                        .onSurface,
                                              ),
                                        ),
                                      ),
                                      PopupMenuButton(
                                        icon: Icon(Icons.more_vert,
                                            color: Theme.of(context)
                                                .colorScheme
                                                .onSurfaceVariant),
                                        itemBuilder: (_) => [
                                          PopupMenuItem(
                                            child: Row(
                                              children: [
                                                Icon(Icons.edit,
                                                    size: 20,
                                                    color: Theme.of(context)
                                                        .colorScheme
                                                        .primary),
                                                const SizedBox(width: 8),
                                                const Text('Sửa'),
                                              ],
                                            ),
                                            onTap: () {
                                              Future.delayed(Duration.zero, () {
                                                Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                      builder: (_) =>
                                                          NoteDetailPage(
                                                              initial: n)),
                                                );
                                              });
                                            },
                                          ),
                                          PopupMenuItem(
                                            child: Row(
                                              children: [
                                                Icon(
                                                  n.isDone
                                                      ? Icons.remove_done
                                                      : Icons.done,
                                                  size: 20,
                                                  color: Theme.of(context)
                                                      .colorScheme
                                                      .tertiary,
                                                ),
                                                const SizedBox(width: 8),
                                                Text(n.isDone
                                                    ? 'Đánh dấu chưa xong'
                                                    : 'Đánh dấu hoàn thành'),
                                              ],
                                            ),
                                            onTap: () {
                                              final updated =
                                                  n.copyWith(isDone: !n.isDone);
                                              ref
                                                  .read(notesProvider.notifier)
                                                  .updateNote(updated);
                                            },
                                          ),
                                          PopupMenuItem(
                                            child: Row(
                                              children: [
                                                Icon(Icons.delete,
                                                    size: 20,
                                                    color: Theme.of(context)
                                                        .colorScheme
                                                        .error),
                                                const SizedBox(width: 8),
                                                const Text('Xóa'),
                                              ],
                                            ),
                                            onTap: () {
                                              Future.delayed(Duration.zero,
                                                  () async {
                                                final confirm =
                                                    await showDialog<bool>(
                                                  context: context,
                                                  builder: (_) => AlertDialog(
                                                    title: const Text(
                                                        'Xóa công việc'),
                                                    content: Text(
                                                        'Bạn có chắc muốn xóa "${n.title}"?'),
                                                    actions: [
                                                      TextButton(
                                                        onPressed: () =>
                                                            Navigator.pop(
                                                                context, false),
                                                        child:
                                                            const Text('Hủy'),
                                                      ),
                                                      FilledButton(
                                                        onPressed: () =>
                                                            Navigator.pop(
                                                                context, true),
                                                        child:
                                                            const Text('Xóa'),
                                                      ),
                                                    ],
                                                  ),
                                                );
                                                if (confirm == true) {
                                                  await ref
                                                      .read(notesProvider
                                                          .notifier)
                                                      .deleteNote(n.id);
                                                  if (!context.mounted) return;
                                                  ScaffoldMessenger.of(context)
                                                      .showSnackBar(
                                                    const SnackBar(
                                                        content: Text(
                                                            'Đã xóa công việc')),
                                                  );
                                                }
                                              });
                                            },
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  if (n.content.isNotEmpty) ...[
                                    const SizedBox(height: 8),
                                    Text(
                                      n.content,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyMedium
                                          ?.copyWith(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .onSurfaceVariant,
                                          ),
                                    ),
                                  ],
                                  const SizedBox(height: 12),
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.access_time,
                                        size: 14,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onSurfaceVariant,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        _formatDateTime(n.createdAt),
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall
                                            ?.copyWith(
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .onSurfaceVariant,
                                            ),
                                      ),
                                      if (n.tags.isNotEmpty) ...[
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Wrap(
                                            spacing: 4,
                                            runSpacing: 4,
                                            children: n.tags
                                                .map((tag) => Chip(
                                                      label: Text(tag),
                                                      labelStyle:
                                                          Theme.of(context)
                                                              .textTheme
                                                              .labelSmall,
                                                      visualDensity:
                                                          VisualDensity.compact,
                                                      padding: const EdgeInsets
                                                          .symmetric(
                                                          horizontal: 4),
                                                      backgroundColor:
                                                          Theme.of(context)
                                                              .colorScheme
                                                              .primaryContainer,
                                                    ))
                                                .toList(),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'notes_fab',
        child: const Icon(Icons.add),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const NoteDetailPage()),
          );
        },
      ),
    );
  }

  String _subtitleFor(Note n) {
    final date = _formatDateTime(n.createdAt);
    final tags = n.tags.isNotEmpty ? ' • ${n.tags.join(', ')}' : '';
    return '${n.isDone ? 'Hoàn thành' : 'Chưa xong'} • $date$tags\n${n.content}';
  }

  String _formatDateTime(DateTime dt) {
    final d =
        '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
    final t =
        '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    return '$d $t';
  }

  Future<void> _seedDemoNotes() async {
    final now = DateTime.now();
    final notes = [
      Note(
          id: const Uuid().v4(),
          title: 'Checklist đi Đà Lạt',
          content: 'Áo ấm, máy ảnh, thuê xe',
          tags: ['travel', 'todo'],
          createdAt: now,
          isDone: false),
      Note(
          id: const Uuid().v4(),
          title: 'Ý tưởng bài blog',
          content: 'Flutter Riverpod + Localstore',
          tags: ['flutter', 'writing'],
          createdAt: now.subtract(const Duration(hours: 5)),
          isDone: false),
      Note(
          id: const Uuid().v4(),
          title: 'Món cần thử',
          content: 'Bún chả, phở gà',
          tags: ['food'],
          createdAt: now.subtract(const Duration(days: 1)),
          isDone: true),
      Note(
          id: const Uuid().v4(),
          title: 'Ghi chú họp',
          content: 'Roadmap Q1 và KPI',
          tags: ['work'],
          createdAt: now.subtract(const Duration(days: 2)),
          isDone: false),
    ];
    for (final n in notes) {
      await ref.read(notesProvider.notifier).addNote(n);
    }
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã tạo dữ liệu demo cho Notes')));
  }
}
