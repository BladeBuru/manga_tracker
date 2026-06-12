import 'package:flutter/foundation.dart';
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

  /// Diagnostic D6 (hotfix-v0-10-1) — déconnexions répétées sur tablette
  /// Huawei (EMUI/HarmonyOS, keystore réputé instable sans Google Services).
  /// Logs **debug uniquement** : clé + présence + longueur, JAMAIS le
  /// contenu (règle RGPD projet). À lire via `adb logcat` sur la tablette
  /// pour confirmer/infirmer la perte de tokens au boot ou au refresh.
  void _diag(String op, String key, {String? value, bool? verified}) {
    if (!kDebugMode) return;
    final presence = value == null ? 'ABSENT' : 'présent(len=${value.length})';
    final check = verified == null ? '' : ' verified=$verified';
    debugPrint('🔐 SecureStorage.$op[$key] → $presence$check');
  }

  // Standard write/read
  Future<void> writeSecureData(String key, String value) async {
    await _secureStorage.write(key: key, value: value);
    // Read-back : détecte les écritures silencieusement perdues (symptôme
    // keystore EMUI). Coût négligeable, debug only pour le log.
    if (kDebugMode) {
      final readBack = await _secureStorage.read(key: key);
      _diag('write', key, value: value, verified: readBack == value);
    }
  }

  Future<void> writeAllSecureData(List<StorageItem> newItems) async {
    for (var newItem in newItems) {
      await writeSecureData(newItem.key, newItem.value);
    }
  }

  Future<String?> readSecureData(String key) async {
    final value = await _secureStorage.read(key: key);
    _diag('read', key, value: value);
    return value;
  }

  Future<void> deleteSecureData(String key) async {
    await _secureStorage.delete(key: key);
    _diag('delete', key);
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
    _diag('deleteAll', '*');
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
