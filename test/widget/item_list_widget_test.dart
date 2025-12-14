import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_project/items/ui/item_list_screen.dart';
import 'package:flutter_project/items/providers/item_provider.dart';
import 'package:flutter_project/items/models/item.dart';

void main() {
  testWidgets('shows empty then displays item', (tester) async {
    final container = ProviderContainer();
    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: const MaterialApp(
        home: ItemListScreen(settingsDoc: 'item_list_widget_test'),
      ),
    ));

    expect(find.text('Chưa có mục nào'), findsOneWidget);

    await container.read(itemListProvider.notifier).add(Item(title: 'Hello'));
    await tester.pumpAndSettle();

    expect(find.text('Hello'), findsOneWidget);
  });
}
