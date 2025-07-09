import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:open_file/open_file.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mangatracker/main.dart';
import 'package:dio/dio.dart';
import '../notifier/notifier.dart';
import '../service_locator/service_locator.dart';


class ChangelogInfo {
  final List<VersionChanges> newVersions;
  ChangelogInfo(this.newVersions);
  bool get isEmpty => newVersions.isEmpty;
}

class VersionChanges {
  final String version;
  final List<dynamic> notes;
  VersionChanges({required this.version, required this.notes});
}


// --- Le Service ---

class AppUpdateService {
  static const String _remoteUrl = 'https://bladeburu.github.io/manga_tracker/assets/version.json';
  static const String _latestReleaseUrl = 'https://api.github.com/repos/BladeBuru/manga_tracker/releases/latest';
  static const String _prefsKey = 'last_version_shown_changelog';

  final Notifier _notifier = getIt<Notifier>();
  final Dio _dio = Dio();
  Map<String, dynamic>? _cachedVersionData;

  Future<Map<String, dynamic>?> _fetchAndCacheData() async {
    if (_cachedVersionData != null) return _cachedVersionData;
    try {
      final response = await http.get(Uri.parse(_remoteUrl));
      if (response.statusCode == 200) {
        _cachedVersionData = jsonDecode(response.body);
        return _cachedVersionData;
      }
      return null;
    } catch (e) {
      return null;
    }
  }


  /// Vérifie si une mise à jour est disponible en ligne.
  Future<bool> isUpdateAvailable() async {
    final data = await _fetchAndCacheData();
    if (data == null) return false;
    try {
      final localVersion = (await PackageInfo.fromPlatform()).version;
      final remoteVersion = data['latestVersion'];
      if (remoteVersion == null || remoteVersion is! String) return false;
      return _isVersionHigher(remoteVersion, localVersion);
    } catch (e) {
      return false;
    }
  }

  /// Récupère les notes de version qui n'ont pas encore été montrées à l'utilisateur.
  /// Retourne un objet ChangelogInfo s'il y a des nouveautés, sinon null.
  Future<ChangelogInfo?> getNewChangelog() async {
    final data = await _fetchAndCacheData();
    final allChangelogs = data?['changelog'] as List<dynamic>?;
    if (data == null || allChangelogs == null) return null;

    final packageInfo = await PackageInfo.fromPlatform();
    final currentVersion = packageInfo.version;

    final prefs = await SharedPreferences.getInstance();
    final lastShownVersion = prefs.getString(_prefsKey) ?? '0.0.0';

    if (_isVersionHigher(currentVersion, lastShownVersion)) {
      final relevantNotes = allChangelogs
          .where((entry) => _isVersionHigher(entry['version'], lastShownVersion))
          .map((entry) => VersionChanges(version: entry['version'], notes: entry['notes']))
          .toList();

      return ChangelogInfo(relevantNotes);
    }
    return null;
  }

  /// Sauvegarde la version actuelle comme étant la dernière version "vue".
  Future<void> markChangelogAsSeen() async {
    final packageInfo = await PackageInfo.fromPlatform();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, packageInfo.version);
  }

  /// Gère le téléchargement et l'installation de la mise à jour.
  Future<void> downloadAndInstallUpdate() async {
    try {
      _notifier.info('Recherche de la dernière version...');
      final resp = await http.get(Uri.parse(_latestReleaseUrl), headers: {'Accept': 'application/vnd.github+json'});
      if (resp.statusCode != 200) {
        _notifier.error('Impossible de récupérer les infos de release.');
        return;
      }
      final json = jsonDecode(resp.body);
      final assets = json['assets'] as List<dynamic>;
      final apkAsset = assets.firstWhere((a) => (a['name'] as String).endsWith('.apk'), orElse: () => null);
      if (apkAsset == null) {
        _notifier.error('APK introuvable dans la dernière release.');
        return;
      }
      final apkUrl = apkAsset['browser_download_url'] as String;
      _notifier.info('Téléchargement de la mise à jour...');
      final dir = await getTemporaryDirectory();
      final path = '${dir.path}/manga_tracker_update.apk';
      await _dio.download(apkUrl, path);

      var status = await Permission.requestInstallPackages.status;
      if (!status.isGranted) {
        final context = navigatorKey.currentContext;
        if (context != null) {
          await showDialog(
            context: context,
            builder: (ctx) => AlertDialog(
              title: const Text("Autorisation requise"),
              content: const Text("Pour installer la mise à jour, vous devez autoriser l'installation d'applications depuis cette source dans l'écran suivant."),
              actions: [ TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text("Compris")) ],
            ),
          );
        }
        status = await Permission.requestInstallPackages.request();
      }
      if (status.isGranted) {
        _notifier.info("Lancement de l'installation...");
        await OpenFile.open(path);
      } else {
        _notifier.warning("L'autorisation a été refusée.");
      }
    } catch (e) {
      _notifier.error('Erreur lors de la mise à jour : ${e.toString()}');
    }
  }

  bool _isVersionHigher(String remote, String local) {
    final remoteParts = remote.split('.').map(int.parse).toList();
    final localParts = local.split('.').map(int.parse).toList();
    for (int i = 0; i < remoteParts.length; i++) {
      if (i >= localParts.length || remoteParts[i] > localParts[i]) return true;
      if (remoteParts[i] < localParts[i]) return false;
    }
    return false;
  }
}