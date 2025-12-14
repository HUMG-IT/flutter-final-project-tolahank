// Localstore removed. This service is now a no-op stub.

class ItemLocalService {
  const ItemLocalService();

  Future<void> savePendingFlag(bool isPending) async {}
  Future<bool?> loadPendingFlag() async => null;
}
