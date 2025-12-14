import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_project/data/repositories/settings_repository.dart';
import 'package:flutter_project/data/db/app_database.dart';
import 'package:flutter_project/notes/ui/notes_list_page.dart';

void main() {
  testWidgets('NotesListPage loads persisted sort mode and tag', (tester) async {
    await AppDatabase.open();
    final s = SettingsRepository();
    await s.setValue('notesSortMode', 'created_desc');
    await s.setValue('notesSelectedTag', 'work');

    await tester.pumpWidget(const ProviderScope(child: MaterialApp(home: NotesListPage(settingsDoc: 'notes_test'))));
    await tester.pumpAndSettle();

    final sort = find.byKey(const Key('notesSortDropdown'));
    expect(sort, findsOneWidget);
    // Selected label visible
    expect(find.descendant(of: sort, matching: find.text('Mới nhất')), findsOneWidget);
  });
}
