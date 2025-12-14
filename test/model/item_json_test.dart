import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_project/items/models/item.dart';

void main() {
  test('Item JSON roundtrip keeps new fields', () {
    final due = DateTime(2025, 12, 31, 23, 45);
    final item = Item(
      id: 'abc',
      title: 'Ghi chú',
      status: 'pending',
      dueAt: due,
      category: 'Công việc',
      priority: 2,
    );

    final json = item.toJson();
    expect(json['dueAt'], due.toIso8601String());
    expect(json['category'], 'Công việc');
    expect(json['priority'], 2);

    final parsed = Item.fromJson(json);
    expect(parsed.id, 'abc');
    expect(parsed.title, 'Ghi chú');
    expect(parsed.status, 'pending');
    expect(parsed.category, 'Công việc');
    expect(parsed.priority, 2);
    expect(parsed.dueAt, due);
  });
}
