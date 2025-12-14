import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_project/items/models/item.dart';
import 'package:flutter_project/items/providers/item_provider.dart';
import 'package:flutter_project/items/ui/item_list_screen.dart';
import 'package:flutter_project/data/repositories/items_repository.dart';
import 'package:flutter_project/data/db/app_database.dart';

class DummyRepo extends ItemsRepository {
  final List<Item> store = [];
  @override
  List<Item> getAll() => [...store];
  @override
  void insert(Item item) => store.add(item);
  @override
  void update(Item item) {
    final i = store.indexWhere((e) => e.id == item.id);
    if (i != -1) store[i] = item;
  }
  @override
  void delete(String id) => store.removeWhere((e) => e.id == id);
}

class TestItemListNotifier extends ItemListNotifier {
  final List<Item> initial;
  TestItemListNotifier(this.initial)
      : super(DummyRepo(), null);
  @override
  Future<void> load() async {
    // Avoid real DB open in tests
    state = initial;
  }
}

void main() {
  testWidgets('Filter by category shows matching items only', (WidgetTester tester) async {
    final initial = [
      Item(id: '1', title: 'A', category: 'Work'),
      Item(id: '2', title: 'B', category: 'Personal'),
      Item(id: '3', title: 'C', category: 'Work'),
    ];
    final container = ProviderContainer(overrides: [
      itemListProvider.overrideWith((ref) => TestItemListNotifier(initial)),
    ]);

    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: const MaterialApp(
        home: ItemListScreen(settingsDoc: 'item_category_test'),
      ),
    ));
    await tester.pumpAndSettle();

    // Clear any persisted search to ensure full list is shown
    final searchField = find.byKey(const Key('itemsSearchField'));
    if (searchField.evaluate().isNotEmpty) {
      await tester.enterText(searchField, '');
      await tester.pumpAndSettle();
    }

    // Reset filters to 'All' to avoid persisted prefs
    final statusDropdown = find.byKey(const Key('statusDropdown'));
    expect(statusDropdown, findsOneWidget);
    await tester.tap(statusDropdown);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Tất cả').last);
    await tester.pumpAndSettle();

    final categoryDropdown = find.byKey(const Key('categoryDropdown'));
    expect(categoryDropdown, findsOneWidget);
    await tester.tap(categoryDropdown);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Mọi loại').last);
    await tester.pumpAndSettle();

    // Ensure items rendered
    expect(find.byType(ListTile), findsNWidgets(3));

    // Open category dropdown
    final categoryDropdown2 = find.byKey(const Key('categoryDropdown'));
    expect(categoryDropdown2, findsOneWidget);
    await tester.tap(categoryDropdown2);
    await tester.pumpAndSettle();

    // Select 'Công việc'
    await tester.tap(find.text('Công việc').first);
    await tester.pumpAndSettle();

    // Verify only Work items remain
    final tiles = tester.widgetList<ListTile>(find.byType(ListTile)).toList();
    expect(tiles.length, 2);
    final titles = tiles.map((t) => (t.title as Text).data).toList();
    expect(titles.contains('A'), isTrue);
    expect(titles.contains('C'), isTrue);
    expect(titles.contains('B'), isFalse);
  });
}
