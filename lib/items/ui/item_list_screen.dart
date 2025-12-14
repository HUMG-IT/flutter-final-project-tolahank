import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/settings_repository_selected.dart';
import '../../data/db/app_database.dart'
    if (dart.library.html) '../../data/db/app_database_stub.dart';
import '../models/item.dart';
import '../providers/item_provider.dart';

class ItemListScreen extends ConsumerStatefulWidget {
  final List<Widget>? actions;
  final String? initialStatusFilter; // 'All' | 'Pending' | 'Done'
  final String settingsDoc;
  const ItemListScreen(
      {super.key,
      this.actions,
      this.initialStatusFilter,
      this.settingsDoc = 'settings'});

  @override
  ConsumerState<ItemListScreen> createState() => _ItemListScreenState();
}

class _ItemListScreenState extends ConsumerState<ItemListScreen> {
  late final TextEditingController _searchCtrl;
  String _query = '';
  String _statusFilter = 'All'; // All | Pending | Done
  String _categoryFilter = 'All';
  String _sortBy = 'Priority'; // Priority | Due | Title

  @override
  void initState() {
    super.initState();
    _searchCtrl = TextEditingController(text: _query);
    _statusFilter = widget.initialStatusFilter ?? 'All';
    _loadPrefs();
  }

  // Removed unused settings doc accessor after migrating to SettingsRepository.

  Future<void> _loadPrefs() async {
    await AppDatabase.open();
    final s = SettingsRepository();
    final category = s.getValue('items_selectedCategory');
    final status = s.getValue('items_selectedStatus');
    final search = s.getValue('items_searchKeyword');
    final sort = s.getValue('items_sortBy');
    setState(() {
      if (category != null) _categoryFilter = category;
      if (status != null) _statusFilter = status;
      if (search != null) {
        _searchCtrl.text = search;
        _query = search;
      }
      if (sort != null) _sortBy = sort;
    });
  }

  Future<void> _persistPrefs() async {
    final s = SettingsRepository();
    await s.setValue('items_selectedCategory', _categoryFilter);
    await s.setValue('items_selectedStatus', _statusFilter);
    await s.setValue('items_searchKeyword', _searchCtrl.text);
    await s.setValue('items_sortBy', _sortBy);
  }

  @override
  Widget build(BuildContext context) {
    final items = ref.watch(itemListProvider);
    List<Item> filtered = items.where((it) {
      final matchesQuery = _query.isEmpty ||
          it.title.toLowerCase().contains(_query.toLowerCase());
      final matchesStatus = _statusFilter == 'All' ||
          (_statusFilter == 'Pending' && it.status == 'pending') ||
          (_statusFilter == 'Done' && it.status == 'done');
      final matchesCategory =
          _categoryFilter == 'All' || (it.category ?? '') == _categoryFilter;
      return matchesQuery && matchesStatus && matchesCategory;
    }).toList();

    switch (_sortBy) {
      case 'Due':
        filtered.sort((a, b) =>
            (a.dueAt ?? DateTime(9999)).compareTo(b.dueAt ?? DateTime(9999)));
        break;
      case 'Title':
        filtered.sort(
            (a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));
        break;
      case 'Priority':
      default:
        filtered.sort((a, b) => b.priority.compareTo(a.priority));
        break;
    }

    final extraActions = <Widget>[
      IconButton(
        tooltip: 'Tạo dữ liệu demo',
        icon: const Icon(Icons.auto_awesome),
        onPressed: _seedDemoItems,
      ),
    ];
    return Scaffold(
      appBar: AppBar(title: const Text('Việc cần làm'), actions: [
        if (widget.actions != null) ...widget.actions!,
        ...extraActions,
      ]),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            Align(
              alignment: Alignment.center,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1100),
                child: Card(
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
                    child: Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      alignment: WrapAlignment.start,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        SizedBox(
                          width: 360,
                          child: TextField(
                            key: const Key('itemsSearchField'),
                            controller: _searchCtrl,
                            decoration: const InputDecoration(
                              prefixIcon: Icon(Icons.search),
                              hintText: 'Tìm theo tiêu đề...',
                              filled: true,
                              isDense: true,
                              border: OutlineInputBorder(),
                            ),
                            onChanged: (v) {
                              setState(() => _query = v);
                              _persistPrefs();
                            },
                          ),
                        ),
                        SizedBox(
                          width: 200,
                          child: DropdownButtonFormField<String>(
                            key: const Key('statusDropdown'),
                            value: _statusFilter,
                            isExpanded: true,
                            decoration: const InputDecoration(
                              isDense: true,
                              border: OutlineInputBorder(),
                              labelText: 'Trạng thái',
                            ),
                            items: const [
                              DropdownMenuItem(
                                  value: 'All', child: Text('Tất cả')),
                              DropdownMenuItem(
                                  value: 'Pending', child: Text('Chờ xử lý')),
                              DropdownMenuItem(
                                  value: 'Done', child: Text('Hoàn thành')),
                            ],
                            onChanged: (v) {
                              setState(() => _statusFilter = v ?? 'All');
                              _persistPrefs();
                            },
                          ),
                        ),
                        SizedBox(
                          width: 200,
                          child: DropdownButtonFormField<String>(
                            key: const Key('categoryDropdown'),
                            value: _categoryFilter,
                            isExpanded: true,
                            decoration: const InputDecoration(
                              isDense: true,
                              border: OutlineInputBorder(),
                              labelText: 'Loại',
                            ),
                            items: const [
                              DropdownMenuItem(
                                  value: 'All', child: Text('Mọi loại')),
                              DropdownMenuItem(
                                  value: 'Work', child: Text('Công việc')),
                              DropdownMenuItem(
                                  value: 'Personal', child: Text('Cá nhân')),
                              DropdownMenuItem(
                                  value: 'Study', child: Text('Học tập')),
                            ],
                            onChanged: (v) {
                              setState(() => _categoryFilter = v ?? 'All');
                              _persistPrefs();
                            },
                          ),
                        ),
                        SizedBox(
                          width: 200,
                          child: DropdownButtonFormField<String>(
                            key: const Key('sortDropdown'),
                            value: _sortBy,
                            isExpanded: true,
                            decoration: const InputDecoration(
                              isDense: true,
                              border: OutlineInputBorder(),
                              labelText: 'Sắp xếp',
                            ),
                            items: const [
                              DropdownMenuItem(
                                  value: 'Priority', child: Text('Độ gấp')),
                              DropdownMenuItem(
                                  value: 'Due', child: Text('Ngày giờ')),
                              DropdownMenuItem(
                                  value: 'Title', child: Text('Tiêu đề')),
                            ],
                            onChanged: (v) {
                              setState(() => _sortBy = v ?? 'Priority');
                              _persistPrefs();
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: filtered.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.task_alt,
                              size: 80,
                              color: Theme.of(context).colorScheme.outline),
                          const SizedBox(height: 16),
                          Text(
                            'Chưa có việc cần làm',
                            style: Theme.of(context).textTheme.headlineSmall,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Nhấn nút + để thêm việc mới',
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
                      itemCount: filtered.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final it = filtered[index];
                        final isDone = it.status == 'done';
                        return Card(
                          elevation: 0,
                          clipBehavior: Clip.antiAlias,
                          color: isDone
                              ? Theme.of(context)
                                  .colorScheme
                                  .surfaceContainerLow
                              : Theme.of(context).colorScheme.surface,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                            side: BorderSide(
                              color: isDone
                                  ? Theme.of(context)
                                      .colorScheme
                                      .outline
                                      .withOpacity(0.3)
                                  : _getPriorityColor(context, it.priority)
                                      .withOpacity(0.5),
                              width: 2,
                            ),
                          ),
                          child: InkWell(
                            onTap: () async {
                              final edited = await showDialog<Item?>(
                                context: context,
                                builder: (_) => _ItemDialog(
                                  initialTitle: it.title,
                                  initialCategory: it.category,
                                  initialPriority: it.priority,
                                  initialDueAt: it.dueAt,
                                  initialDescription: it.description,
                                ),
                              );
                              if (!mounted) return;
                              if (edited != null) {
                                try {
                                  await ref
                                      .read(itemListProvider.notifier)
                                      .update(edited.copyWith(
                                          id: it.id, status: it.status));
                                  if (!mounted) return;
                                  if (!context.mounted) return;
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Đã cập nhật'),
                                      behavior: SnackBarBehavior.floating,
                                    ),
                                  );
                                } catch (e) {
                                  if (!mounted) return;
                                  if (!context.mounted) return;
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Lỗi: $e')),
                                  );
                                }
                              }
                            },
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      GestureDetector(
                                        onTap: () async {
                                          try {
                                            await ref
                                                .read(itemListProvider.notifier)
                                                .toggleStatus(it.id);
                                            if (!mounted) return;
                                          } catch (e) {
                                            if (!mounted) return;
                                            if (!context.mounted) return;
                                            ScaffoldMessenger.of(context)
                                                .showSnackBar(
                                              SnackBar(
                                                  content: Text('Lỗi: $e')),
                                            );
                                          }
                                        },
                                        child: Icon(
                                          isDone
                                              ? Icons.check_circle
                                              : Icons.radio_button_unchecked,
                                          color: isDone
                                              ? Theme.of(context)
                                                  .colorScheme
                                                  .primary
                                              : Theme.of(context)
                                                  .colorScheme
                                                  .outline,
                                          size: 28,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              it.title,
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .titleMedium
                                                  ?.copyWith(
                                                    fontWeight: FontWeight.bold,
                                                    decoration: isDone
                                                        ? TextDecoration
                                                            .lineThrough
                                                        : null,
                                                    color: isDone
                                                        ? Theme.of(context)
                                                            .colorScheme
                                                            .onSurfaceVariant
                                                        : Theme.of(context)
                                                            .colorScheme
                                                            .onSurface,
                                                  ),
                                            ),
                                            if (it.description != null &&
                                                it.description!.isNotEmpty) ...[
                                              const SizedBox(height: 4),
                                              Text(
                                                it.description!,
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .bodySmall
                                                    ?.copyWith(
                                                      color: Theme.of(context)
                                                          .colorScheme
                                                          .onSurfaceVariant,
                                                    ),
                                              ),
                                            ],
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: _getPriorityColor(
                                                  context, it.priority)
                                              .withOpacity(0.2),
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              Icons.flag,
                                              size: 14,
                                              color: _getPriorityColor(
                                                  context, it.priority),
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              _getPriorityText(it.priority),
                                              style: TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.bold,
                                                color: _getPriorityColor(
                                                    context, it.priority),
                                              ),
                                            ),
                                          ],
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
                                              Future.delayed(Duration.zero,
                                                  () async {
                                                final edited =
                                                    await showDialog<Item?>(
                                                  context: context,
                                                  builder: (_) => _ItemDialog(
                                                    initialTitle: it.title,
                                                    initialCategory:
                                                        it.category,
                                                    initialPriority:
                                                        it.priority,
                                                    initialDueAt: it.dueAt,
                                                    initialDescription:
                                                        it.description,
                                                  ),
                                                );
                                                if (!mounted) return;
                                                if (edited != null) {
                                                  try {
                                                    await ref
                                                        .read(itemListProvider
                                                            .notifier)
                                                        .update(edited.copyWith(
                                                            id: it.id,
                                                            status: it.status));
                                                    if (!context.mounted)
                                                      return;
                                                    ScaffoldMessenger.of(
                                                            context)
                                                        .showSnackBar(
                                                      const SnackBar(
                                                        content:
                                                            Text('Đã cập nhật'),
                                                        behavior:
                                                            SnackBarBehavior
                                                                .floating,
                                                      ),
                                                    );
                                                  } catch (e) {
                                                    if (!context.mounted)
                                                      return;
                                                    ScaffoldMessenger.of(
                                                            context)
                                                        .showSnackBar(
                                                      SnackBar(
                                                          content:
                                                              Text('Lỗi: $e')),
                                                    );
                                                  }
                                                }
                                              });
                                            },
                                          ),
                                          PopupMenuItem(
                                            child: Row(
                                              children: [
                                                Icon(
                                                  isDone
                                                      ? Icons.remove_done
                                                      : Icons.done,
                                                  size: 20,
                                                  color: Theme.of(context)
                                                      .colorScheme
                                                      .tertiary,
                                                ),
                                                const SizedBox(width: 8),
                                                Text(isDone
                                                    ? 'Đánh dấu chưa xong'
                                                    : 'Đánh dấu hoàn thành'),
                                              ],
                                            ),
                                            onTap: () async {
                                              try {
                                                await ref
                                                    .read(itemListProvider
                                                        .notifier)
                                                    .toggleStatus(it.id);
                                              } catch (e) {
                                                if (!context.mounted) return;
                                                ScaffoldMessenger.of(context)
                                                    .showSnackBar(
                                                  SnackBar(
                                                      content: Text('Lỗi: $e')),
                                                );
                                              }
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
                                                        'Xóa việc cần làm'),
                                                    content: Text(
                                                        'Bạn có chắc muốn xóa "${it.title}"?'),
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
                                                  try {
                                                    await ref
                                                        .read(itemListProvider
                                                            .notifier)
                                                        .remove(it.id);
                                                    if (!context.mounted)
                                                      return;
                                                    ScaffoldMessenger.of(
                                                            context)
                                                        .showSnackBar(
                                                      const SnackBar(
                                                        content: Text('Đã xóa'),
                                                        behavior:
                                                            SnackBarBehavior
                                                                .floating,
                                                      ),
                                                    );
                                                  } catch (e) {
                                                    if (!context.mounted)
                                                      return;
                                                    ScaffoldMessenger.of(
                                                            context)
                                                        .showSnackBar(
                                                      SnackBar(
                                                          content:
                                                              Text('Lỗi: $e')),
                                                    );
                                                  }
                                                }
                                              });
                                            },
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  Row(
                                    children: [
                                      if (it.category != null) ...[
                                        Icon(
                                          Icons.category_outlined,
                                          size: 14,
                                          color: Theme.of(context)
                                              .colorScheme
                                              .onSurfaceVariant,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          it.category!,
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodySmall
                                              ?.copyWith(
                                                color: Theme.of(context)
                                                    .colorScheme
                                                    .onSurfaceVariant,
                                              ),
                                        ),
                                        const SizedBox(width: 12),
                                      ],
                                      if (it.dueAt != null) ...[
                                        Icon(
                                          Icons.access_time,
                                          size: 14,
                                          color: _isOverdue(it.dueAt!)
                                              ? Theme.of(context)
                                                  .colorScheme
                                                  .error
                                              : Theme.of(context)
                                                  .colorScheme
                                                  .onSurfaceVariant,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          _formatDueDate(it.dueAt!),
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodySmall
                                              ?.copyWith(
                                                color: _isOverdue(it.dueAt!)
                                                    ? Theme.of(context)
                                                        .colorScheme
                                                        .error
                                                    : Theme.of(context)
                                                        .colorScheme
                                                        .onSurfaceVariant,
                                                fontWeight:
                                                    _isOverdue(it.dueAt!)
                                                        ? FontWeight.bold
                                                        : null,
                                              ),
                                        ),
                                      ],
                                      const Spacer(),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 8, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: isDone
                                              ? Theme.of(context)
                                                  .colorScheme
                                                  .primaryContainer
                                              : Theme.of(context)
                                                  .colorScheme
                                                  .tertiaryContainer,
                                          borderRadius:
                                              BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          isDone ? 'Hoàn thành' : 'Chờ xử lý',
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                            color: isDone
                                                ? Theme.of(context)
                                                    .colorScheme
                                                    .onPrimaryContainer
                                                : Theme.of(context)
                                                    .colorScheme
                                                    .onTertiaryContainer,
                                          ),
                                        ),
                                      ),
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
        heroTag: 'items_fab',
        child: const Icon(Icons.add),
        onPressed: () async {
          final created = await showDialog<Item?>(
              context: context, builder: (_) => const _ItemDialog());
          if (!mounted) return;
          if (created != null) {
            try {
              await ref.read(itemListProvider.notifier).add(created);
              if (!mounted) return;
              if (!context.mounted) return;
              ScaffoldMessenger.of(context)
                  .showSnackBar(const SnackBar(content: Text('Added')));
            } catch (e) {
              if (!mounted) return;
              if (!context.mounted) return;
              ScaffoldMessenger.of(context)
                  .showSnackBar(SnackBar(content: Text('Error: $e')));
            }
          }
        },
      ),
    );
  }

  Future<void> _seedDemoItems() async {
    final now = DateTime.now();
    final items = [
      Item(
          title: 'Viết báo cáo tuần',
          category: 'Work',
          priority: 2,
          dueAt: now.add(const Duration(days: 1)),
          description: 'Chuẩn bị slide và số liệu',
          status: 'pending'),
      Item(
          title: 'Mua quà sinh nhật',
          category: 'Personal',
          priority: 1,
          dueAt: now.add(const Duration(days: 3)),
          description: 'Cho em gái, ngân sách 300k',
          status: 'pending'),
      Item(
          title: 'Ôn chương 3 Toán',
          category: 'Study',
          priority: 1,
          description: 'Làm bài tập 3.1-3.5',
          status: 'pending'),
      Item(
          title: 'Tập thể dục',
          category: 'Personal',
          priority: 0,
          description: 'Chạy bộ 20 phút',
          status: 'done'),
      Item(
          title: 'Review PR #124',
          category: 'Work',
          priority: 2,
          description: 'Kiểm tra logic và test',
          status: 'pending'),
      Item(
          title: 'Dọn tủ sách',
          category: 'Personal',
          priority: 0,
          status: 'pending'),
    ];
    for (final it in items) {
      await ref.read(itemListProvider.notifier).add(it);
    }
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã tạo dữ liệu demo cho Items')));
  }

  String _subtitleFor(Item it) {
    final statusText = it.status == 'done' ? 'Hoàn thành' : 'Chờ xử lý';
    final cat = it.category != null ? ' • ${it.category}' : '';
    final pr = ' • Độ gấp: ${_priorityLabel(it.priority)}';
    final due = it.dueAt != null ? ' • Hạn ${_formatDateTime(it.dueAt!)}' : '';
    final desc = (it.description != null && it.description!.isNotEmpty)
        ? '\n${it.description}'
        : '';
    return '$statusText$cat$pr$due$desc';
  }

  String _formatDateTime(DateTime dt) {
    final d =
        '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
    final t =
        '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    return '$d $t';
  }

  String _priorityLabel(int p) {
    switch (p) {
      case 0:
        return 'Không gấp';
      case 2:
        return 'Rất gấp';
      case 1:
      default:
        return 'Bình thường';
    }
  }

  Color _getPriorityColor(BuildContext context, int priority) {
    switch (priority) {
      case 0:
        return Theme.of(context).colorScheme.tertiary;
      case 2:
        return Theme.of(context).colorScheme.error;
      case 1:
      default:
        return Theme.of(context).colorScheme.primary;
    }
  }

  String _getPriorityText(int priority) {
    switch (priority) {
      case 0:
        return 'Thấp';
      case 2:
        return 'Cao';
      case 1:
      default:
        return 'TB';
    }
  }

  bool _isOverdue(DateTime dueAt) {
    return dueAt.isBefore(DateTime.now());
  }

  String _formatDueDate(DateTime dueAt) {
    final now = DateTime.now();
    final diff = dueAt.difference(now);

    if (diff.isNegative) {
      if (diff.inDays < -1) {
        return 'Quá ${diff.inDays.abs()} ngày';
      } else if (diff.inHours < -1) {
        return 'Quá ${diff.inHours.abs()} giờ';
      } else {
        return 'Quá hạn';
      }
    }

    if (diff.inDays > 0) {
      return 'Còn ${diff.inDays} ngày';
    } else if (diff.inHours > 0) {
      return 'Còn ${diff.inHours} giờ';
    } else if (diff.inMinutes > 0) {
      return 'Còn ${diff.inMinutes} phút';
    } else {
      return 'Sắp hết hạn';
    }
  }
}

class _ItemDialog extends StatefulWidget {
  final String? initialTitle;
  final String? initialCategory;
  final int? initialPriority;
  final DateTime? initialDueAt;
  final String? initialDescription;
  const _ItemDialog(
      {this.initialTitle,
      this.initialCategory,
      this.initialPriority,
      this.initialDueAt,
      this.initialDescription});
  @override
  State<_ItemDialog> createState() => _ItemDialogState();
}

class _ItemDialogState extends State<_ItemDialog> {
  final _formKey = GlobalKey<FormState>();
  late String _title;
  String? _category;
  int _priority = 1;
  DateTime? _dueAt;
  String? _description;

  @override
  void initState() {
    super.initState();
    _title = widget.initialTitle ?? '';
    _category = widget.initialCategory;
    _priority = widget.initialPriority ?? 1;
    _dueAt = widget.initialDueAt;
    _description = widget.initialDescription;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      title: Text(widget.initialTitle == null ? 'Thêm mục' : 'Sửa mục'),
      content: SingleChildScrollView(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  initialValue: _title,
                  decoration: const InputDecoration(labelText: 'Tiêu đề'),
                  validator: (v) =>
                      (v == null || v.isEmpty) ? 'Bắt buộc' : null,
                  onSaved: (v) => _title = v ?? '',
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: _category,
                  decoration: const InputDecoration(labelText: 'Loại'),
                  items: const [
                    DropdownMenuItem(value: null, child: Text('Không')),
                    DropdownMenuItem(value: 'Work', child: Text('Công việc')),
                    DropdownMenuItem(value: 'Personal', child: Text('Cá nhân')),
                    DropdownMenuItem(value: 'Study', child: Text('Học tập')),
                  ],
                  onChanged: (v) => setState(() => _category = v),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<int>(
                  value: _priority,
                  decoration: const InputDecoration(labelText: 'Độ gấp'),
                  items: const [
                    DropdownMenuItem(value: 0, child: Text('Không gấp')),
                    DropdownMenuItem(value: 1, child: Text('Bình thường')),
                    DropdownMenuItem(value: 2, child: Text('Rất gấp')),
                  ],
                  onChanged: (v) => setState(() => _priority = v ?? 1),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  initialValue: _description ?? '',
                  minLines: 3,
                  maxLines: 6,
                  decoration: const InputDecoration(labelText: 'Mô tả'),
                  onChanged: (v) => _description = v,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: InputDecorator(
                        decoration:
                            const InputDecoration(labelText: 'Hạn (ngày giờ)'),
                        child: Text(_dueAt != null
                            ? _formatDateTimeDialog(_dueAt!)
                            : 'Không đặt'),
                      ),
                    ),
                    TextButton(
                      onPressed: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: _dueAt ?? DateTime.now(),
                          firstDate: DateTime(2000),
                          lastDate: DateTime(2100),
                        );
                        if (!context.mounted) return;
                        if (date == null) return;
                        final time = await showTimePicker(
                          context: context,
                          initialTime:
                              TimeOfDay.fromDateTime(_dueAt ?? DateTime.now()),
                        );
                        if (!context.mounted) return;
                        final combined = DateTime(
                          date.year,
                          date.month,
                          date.day,
                          time?.hour ?? 0,
                          time?.minute ?? 0,
                        );
                        if (!mounted) return;
                        setState(() => _dueAt = combined);
                      },
                      child: const Text('Chọn'),
                    ),
                    TextButton(
                      onPressed: () => setState(() => _dueAt = null),
                      child: const Text('Xóa'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Hủy')),
        ElevatedButton(
          onPressed: () {
            if (_formKey.currentState?.validate() ?? false) {
              _formKey.currentState?.save();
              final item = Item(
                title: _title,
                category: _category,
                priority: _priority,
                dueAt: _dueAt,
                description: _description,
              );
              Navigator.of(context).pop(item);
            }
          },
          child: Text(widget.initialTitle == null ? 'Thêm' : 'Lưu'),
        ),
      ],
    );
  }

  String _formatDateTimeDialog(DateTime dt) {
    final d =
        '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
    final t =
        '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    return '$d $t';
  }
}
