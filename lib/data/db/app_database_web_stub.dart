// Stub file for non-web platforms
// This file is used when sqlite3_web is conditionally imported on non-web platforms
// It does nothing and exists only to satisfy the import

class IndexedDbFileSystem {
  static Never open({String? dbName}) {
    throw UnsupportedError('IndexedDbFileSystem is only supported on web platform');
  }
}
