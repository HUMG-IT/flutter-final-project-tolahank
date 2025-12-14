import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_project/items/models/item.dart';

void main() {
  test('Item serialization roundtrip', () {
    final it = Item(title: 'A');
    final json = it.toJson();
    final it2 = Item.fromJson(json);
    expect(it2.title, equals('A'));
    expect(it2.id, equals(it.id));
    expect(it2.status, equals('pending'));
  });
}
