import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_project/main.dart';

void main() {
  testWidgets('MainApp displays Items title', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: MainApp()));

    expect(find.text('Items'), findsOneWidget);
  });
}
