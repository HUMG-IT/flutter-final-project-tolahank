import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../models/note.dart';
import '../state/notes_provider.dart';

class NoteDetailPage extends ConsumerStatefulWidget {
  final Note? initial;
  const NoteDetailPage({super.key, this.initial});

  @override
  ConsumerState<NoteDetailPage> createState() => _NoteDetailPageState();
}

class _NoteDetailPageState extends ConsumerState<NoteDetailPage> {
  final _formKey = GlobalKey<FormState>();
  late String _title;
  late String _content;
  late bool _isDone;
  late List<String> _tags;

  @override
  void initState() {
    super.initState();
    _title = widget.initial?.title ?? '';
    _content = widget.initial?.content ?? '';
    _isDone = widget.initial?.isDone ?? false;
    _tags = [...(widget.initial?.tags ?? const [])];
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.initial != null;
    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Sửa công việc' : 'Tạo công việc mới'),
        actions: [
          if (isEditing)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              tooltip: 'Xóa ghi chú',
              onPressed: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (_) => AlertDialog(
                    title: const Text('Xóa công việc'),
                    content:
                        const Text('Bạn có chắc chắn muốn xóa công việc này?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('Hủy'),
                      ),
                      FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor: Theme.of(context).colorScheme.error,
                        ),
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text('Xóa'),
                      ),
                    ],
                  ),
                );
                if (confirm == true && widget.initial != null) {
                  await ref
                      .read(notesProvider.notifier)
                      .deleteNote(widget.initial!.id);
                  if (!mounted) return;
                  if (!context.mounted) return;
                  Navigator.pop(context);
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Đã xóa công việc'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              },
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Card(
                elevation: 0,
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Thông tin công việc',
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        initialValue: _title,
                        decoration: InputDecoration(
                          labelText: 'Tiêu đề',
                          hintText: 'Nhập tiêu đề công việc...',
                          prefixIcon: const Icon(Icons.title),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: Theme.of(context).colorScheme.surface,
                        ),
                        validator: (v) => (v == null || v.isEmpty)
                            ? 'Vui lòng nhập tiêu đề'
                            : null,
                        onSaved: (v) => _title = v ?? '',
                        textInputAction: TextInputAction.next,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        initialValue: _content,
                        maxLines: 8,
                        decoration: InputDecoration(
                          labelText: 'Nội dung',
                          hintText: 'Nhập nội dung công việc...',
                          alignLabelWithHint: true,
                          prefixIcon: const Padding(
                            padding: EdgeInsets.only(bottom: 100),
                            child: Icon(Icons.notes),
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: Theme.of(context).colorScheme.surface,
                        ),
                        onSaved: (v) => _content = v ?? '',
                      ),
                      const SizedBox(height: 16),
                      Card(
                        elevation: 0,
                        color: Theme.of(context).colorScheme.surface,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(
                            color: _isDone
                                ? Theme.of(context).colorScheme.primary
                                : Theme.of(context).colorScheme.outline,
                            width: 1,
                          ),
                        ),
                        child: SwitchListTile(
                          title: Row(
                            children: [
                              Icon(
                                _isDone
                                    ? Icons.check_circle
                                    : Icons.radio_button_unchecked,
                                color: _isDone
                                    ? Theme.of(context).colorScheme.primary
                                    : Theme.of(context).colorScheme.outline,
                              ),
                              const SizedBox(width: 12),
                              const Text('Đánh dấu hoàn thành'),
                            ],
                          ),
                          subtitle: Text(
                            _isDone
                                ? 'Công việc đã hoàn thành'
                                : 'Công việc chưa hoàn thành',
                            style: TextStyle(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
                            ),
                          ),
                          value: _isDone,
                          onChanged: (v) => setState(() => _isDone = v),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Card(
                elevation: 0,
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: _TagEditor(
                    tags: _tags,
                    onChanged: (t) => setState(() => _tags = t),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  if (isEditing) ...[
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.cancel_outlined),
                        label: const Text('Hủy'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ),
                    const SizedBox(width: 12),
                  ],
                  Expanded(
                    flex: 2,
                    child: FilledButton.icon(
                      icon: Icon(isEditing ? Icons.save : Icons.add),
                      label: Text(isEditing ? 'Cập nhật' : 'Tạo công việc'),
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () async {
                        if (_formKey.currentState?.validate() ?? false) {
                          _formKey.currentState?.save();
                          if (isEditing) {
                            final updated = widget.initial!.copyWith(
                              title: _title,
                              content: _content,
                              isDone: _isDone,
                              tags: _tags,
                            );
                            await ref
                                .read(notesProvider.notifier)
                                .updateNote(updated);
                            if (!context.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Đã cập nhật công việc'),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          } else {
                            final id = const Uuid().v4();
                            final note = Note(
                              id: id,
                              title: _title,
                              content: _content,
                              isDone: _isDone,
                              createdAt: DateTime.now(),
                              tags: _tags,
                            );
                            if (!mounted) return;
                            await ref
                                .read(notesProvider.notifier)
                                .addNote(note);
                            if (!context.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Đã tạo công việc mới'),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          }
                          if (!context.mounted) return;
                          Navigator.pop(context);
                        }
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TagEditor extends StatefulWidget {
  final List<String> tags;
  final ValueChanged<List<String>> onChanged;
  const _TagEditor({required this.tags, required this.onChanged});

  @override
  State<_TagEditor> createState() => _TagEditorState();
}

class _TagEditorState extends State<_TagEditor> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.label_outline,
                color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 8),
            Text(
              'Thẻ (Tags)',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (widget.tags.isEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Theme.of(context).colorScheme.outlineVariant,
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline,
                    color: Theme.of(context).colorScheme.onSurfaceVariant),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Chưa có thẻ nào. Thêm thẻ để phân loại ghi chú.',
                    style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant),
                  ),
                ),
              ],
            ),
          )
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: widget.tags
                .map((tag) => Chip(
                      avatar: Icon(Icons.label, size: 18),
                      label: Text(tag),
                      deleteIcon: const Icon(Icons.close, size: 18),
                      onDeleted: () {
                        final next = [...widget.tags]..remove(tag);
                        widget.onChanged(next);
                      },
                      backgroundColor:
                          Theme.of(context).colorScheme.secondaryContainer,
                      labelStyle: TextStyle(
                        color:
                            Theme.of(context).colorScheme.onSecondaryContainer,
                      ),
                    ))
                .toList(),
          ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _controller,
                decoration: InputDecoration(
                  hintText: 'Nhập tên thẻ mới...',
                  prefixIcon: const Icon(Icons.add_circle_outline),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Theme.of(context).colorScheme.surface,
                ),
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _addTag(),
              ),
            ),
            const SizedBox(width: 8),
            FilledButton.icon(
              icon: const Icon(Icons.add),
              label: const Text('Thêm'),
              style: FilledButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: _addTag,
            ),
          ],
        ),
      ],
    );
  }

  void _addTag() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    final next = [...widget.tags];
    if (!next.contains(text)) {
      next.add(text);
      widget.onChanged(next);
    }
    _controller.clear();
  }
}
