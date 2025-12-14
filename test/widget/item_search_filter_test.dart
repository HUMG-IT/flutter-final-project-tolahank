import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:flutter_project/items/models/item.dart';
import 'package:flutter_project/items/providers/item_provider.dart';
import 'package:flutter_project/items/ui/item_list_screen.dart';

void main() {
  testWidgets('search and status filter work', (tester) async {
    final container = ProviderContainer();

    // Build the screen with a container scope
    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: const MaterialApp(
        home: ItemListScreen(settingsDoc: 'item_search_test'),
      ),
    ));

    // Seed data
    await container.read(itemListProvider.notifier).add(Item(title: 'Buy milk', status: 'pending'));
    await container.read(itemListProvider.notifier).add(Item(title: 'Write report', status: 'done'));
    await container.read(itemListProvider.notifier).add(Item(title: 'Call mom', status: 'pending'));
    await tester.pumpAndSettle();

    // Initially should show all 3
    expect(find.text('Buy milk'), findsOneWidget);
    expect(find.text('Write report'), findsOneWidget);
    expect(find.text('Call mom'), findsOneWidget);

    // Search for 'buy' should filter to 'Buy milk'
    final searchField = find.byType(TextField);
    expect(searchField, findsOneWidget);
    await tester.enterText(searchField, 'buy');
    await tester.pumpAndSettle();
    expect(find.text('Buy milk'), findsOneWidget);
    expect(find.text('Write report'), findsNothing);
    expect(find.text('Call mom'), findsNothing);

    // Clear search
    await tester.enterText(searchField, '');
    await tester.pumpAndSettle();

    // Đổi trạng thái lọc sang 'Chờ xử lý'
    // Mở dropdown trạng thái bằng key
    final statusDropdown = find.byKey(const Key('statusDropdown'));
    expect(statusDropdown, findsOneWidget);
    await tester.tap(statusDropdown);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Chờ xử lý').last);
    await tester.pumpAndSettle();

    // Should show only pending items
    expect(find.text('Buy milk'), findsOneWidget);
    expect(find.text('Call mom'), findsOneWidget);
    expect(find.text('Write report'), findsNothing);

    // Chuyển sang 'Hoàn thành'
    await tester.tap(statusDropdown);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Hoàn thành').last);
    await tester.pumpAndSettle();

    expect(find.text('Write report'), findsOneWidget);
    expect(find.text('Buy milk'), findsNothing);
    expect(find.text('Call mom'), findsNothing);

    // Trở lại 'Tất cả'
    await tester.tap(statusDropdown);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Tất cả').last);
    await tester.pumpAndSettle();

    expect(find.text('Buy milk'), findsOneWidget);
    expect(find.text('Write report'), findsOneWidget);
    expect(find.text('Call mom'), findsOneWidget);
  });
}