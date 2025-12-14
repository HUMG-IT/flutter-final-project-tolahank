import '../../items/models/item.dart';

class ItemsRepository {
  static final ItemsRepository _instance = ItemsRepository._();
  factory ItemsRepository() => _instance;
  ItemsRepository._();

  final List<Item> _items = [];

  List<Item> getAll() => List.unmodifiable(_items);
  void insert(Item item) => _items.add(item);
  void update(Item item) {
    final i = _items.indexWhere((e) => e.id == item.id);
    if (i != -1) _items[i] = item;
  }
  void delete(String id) => _items.removeWhere((e) => e.id == id);
}