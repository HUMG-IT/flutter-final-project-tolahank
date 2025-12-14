import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_project/data/repositories/settings_repository.dart';
import 'package:flutter_project/data/db/app_database.dart';
import 'package:flutter_project/items/ui/item_list_screen.dart';

void main() {
  testWidgets('ItemListScreen loads persisted filters', (tester) async {
    await AppDatabase.open();
    final s = SettingsRepository();
    await s.setValue('items_selectedStatus', 'Pending');
    await s.setValue('items_selectedCategory', 'Work');
    await s.setValue('items_searchKeyword', '');
    await s.setValue('items_sortBy', 'Due');

    await tester.pumpWidget(const ProviderScope(child: MaterialApp(home: ItemListScreen(settingsDoc: 'items_test'))));
    await tester.pumpAndSettle();

    final status = find.byKey(const Key('statusDropdown'));
    final category = find.byKey(const Key('categoryDropdown'));
    final sort = find.byKey(const Key('sortDropdown'));

    expect(status, findsOneWidget);
    expect(category, findsOneWidget);
    expect(sort, findsOneWidget);

    // Verify selected texts visible in dropdown buttons
    expect(find.descendant(of: status, matching: find.text('Chờ xử lý')), findsOneWidget);
    expect(find.descendant(of: category, matching: find.text('Công việc')), findsOneWidget);
    expect(find.descendant(of: sort, matching: find.text('Ngày giờ')), findsOneWidget);
  });
}
