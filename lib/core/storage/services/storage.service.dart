import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../model/storage_item.model.dart';

class StorageService {
  // Standard secured storage
  final _secureStorage = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
  );

  // Separate instance to simulate “biometric-only” access if needed
  final _biometricStorage = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
  );

  Future<StorageService> init() async {
    return this;
  }

  // Standard write/read
  Future<void> writeSecureData(String key, String value) async {
    await _secureStorage.write(key: key, value: value);
  }

  Future<void> writeAllSecureData(List<StorageItem> newItems) async {
    for (var newItem in newItems) {
      await writeSecureData(newItem.key, newItem.value);
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

  Future<void> writeSecureDataBiometric(String key, String value) async {
    await _biometricStorage.write(key: key, value: value);
  }

  Future<String?> readSecureDataBiometric(String key) async {
    return await _biometricStorage.read(key: key);
  }
  Future<bool> hasBiometricCredentials() async {
    final creds = await readSecureDataBiometric('secure_credentials');
    return creds != null;
  }
}
