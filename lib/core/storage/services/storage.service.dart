import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../model/storage_item.model.dart';

class StorageService {
  final _secureStorage = const FlutterSecureStorage(
      aOptions: AndroidOptions(
    encryptedSharedPreferences: true,
  ));

  Future<StorageService> init() async {
    return this;
  }

  Future<void> writeSecureData(StorageItem newItem) async {
    await _secureStorage.write(key: newItem.key, value: newItem.value);
  }

  Future<void> writeAllSecureData(List<StorageItem> newItems) async {
    for (var newItem in newItems) {
      writeSecureData(newItem);
    }
  }

  Future<String?> readSecureData(String key) async {
    return await _secureStorage.read(key: key);
  }

  Future<void> deleteSecureData(String key) async {
    await _secureStorage.delete(key: key);
  }

  Future<bool> containsKeyInSecureData(String key) async {
    return await _secureStorage.containsKey(key: key);
  }

  Future<List<StorageItem>> readAllSecureData() async {
    var allData = await _secureStorage.readAll();
    return allData.entries.map((e) => StorageItem(e.key, e.value)).toList();
  }

  Future<void> deleteAllSecureData() async {
    await _secureStorage.deleteAll();
  }
}
