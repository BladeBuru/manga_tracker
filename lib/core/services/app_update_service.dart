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
    // Vérifier si on est en mode dev - si oui, pas de mise à jour automatique
    final packageInfo = await PackageInfo.fromPlatform();
    final currentPackageName = packageInfo.packageName;
    if (currentPackageName.contains('.dev')) {
      return false; // Les versions dev ne peuvent pas être mises à jour depuis GitHub Releases
    }
    
    final data = await _fetchAndCacheData();
    if (data == null) return false;
    try {
      final localVersion = packageInfo.version;
      final remoteVersion = data['latestVersion'];
      if (remoteVersion == null || remoteVersion is! String) return false;
      return _isVersionHigher(remoteVersion, localVersion);
    } catch (e) {
      return false;
    }
  }

  /// Récupère tous les changelogs disponibles
  Future<ChangelogInfo?> getAllChangelogs() async {
    try {
      final data = await _fetchAndCacheData();
      final allChangelogs = data?['changelog'] as List<dynamic>?;
      if (data == null || allChangelogs == null) return null;

      final relevantNotes = allChangelogs
          .map((entry) => VersionChanges(
                version: (entry as Map)['version'] as String,
                notes: entry['notes'] as List<dynamic>,
              ))
          .toList();

      return ChangelogInfo(relevantNotes);
    } catch (e, st) {
      print('getAllChangelogs error: $e\n$st');
      return null;
    }
  }

  /// Récupère les notes de version qui n'ont pas encore été montrées à l'utilisateur.
  /// Retourne un objet ChangelogInfo s'il y a des nouveautés, sinon null.
  Future<ChangelogInfo?> getNewChangelog() async {
    try {
      final data = await _fetchAndCacheData();
      final allChangelogs = data?['changelog'] as List<dynamic>?;
      if (data == null || allChangelogs == null) return null;

      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = packageInfo.version;

      final prefs = await SharedPreferences.getInstance();
      final lastShownVersion = prefs.getString(_prefsKey) ?? '0.0.0';

      if (_isVersionHigher(currentVersion, lastShownVersion)) {
        final relevantNotes = allChangelogs
            .where((entry) {
          final v = (entry as Map)['version']?.toString() ?? '';
          return v.isNotEmpty && _isVersionHigher(v, lastShownVersion);
        })
            .map((entry) => VersionChanges(
          version: (entry as Map)['version'] as String,
          notes: entry['notes'] as List<dynamic>,
        ))
            .toList();

        return ChangelogInfo(relevantNotes);
      }
      return null;
    } catch (e, st) {
      print('getNewChangelog error: $e\n$st');
      return null;
    }
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
      // Vérifier le package name actuel pour détecter l'environnement
      final packageInfo = await PackageInfo.fromPlatform();
      final currentPackageName = packageInfo.packageName;
      
      // Si on est en mode dev, on ne peut pas installer la version prod depuis GitHub
      if (currentPackageName.contains('.dev')) {
        final context = navigatorKey.currentContext;
        if (context != null) {
          await showDialog(
            context: context,
            builder: (ctx) => AlertDialog(
              title: const Text("Mise à jour non disponible"),
              content: const Text(
                "Vous utilisez actuellement la version de développement. "
                "Les mises à jour automatiques ne sont disponibles que pour la version de production. "
                "Pour mettre à jour la version de développement, veuillez la reconstruire depuis le code source."
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text("Compris"),
                ),
              ],
            ),
          );
        }
        return;
      }

      _notifier.info('Recherche de la dernière version...');
      final resp = await http.get(Uri.parse(_latestReleaseUrl), headers: {'Accept': 'application/vnd.github+json'});
      if (resp.statusCode != 200) {
        _notifier.error('Impossible de récupérer les infos de release.');
        return;
      }
      final json = jsonDecode(resp.body);
      final assets = json['assets'] as List<dynamic>;
      
      // Chercher l'APK de production (pas de dev)
      final apkAsset = assets.firstWhere(
        (a) {
          final name = (a['name'] as String).toLowerCase();
          return name.endsWith('.apk') && !name.contains('dev');
        },
        orElse: () => null,
      );
      
      if (apkAsset == null) {
        _notifier.error('APK de production introuvable dans la dernière release.');
        return;
      }
      final apkUrl = apkAsset['browser_download_url'] as String;
      _notifier.info('Téléchargement de la mise à jour...');
      final dir = await getTemporaryDirectory();
      final path = '${dir.path}/manga_tracker_update.apk';
      await _dio.download(apkUrl, path);

      // Vérifier que le package name correspond avant l'installation
      // Note: Cette vérification nécessiterait d'extraire le package name de l'APK,
      // ce qui est complexe. On fait confiance au fait que GitHub Releases ne publie que la version prod.
      
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
    if (remote.contains('-dev')) return false;

    final rp = _parseSemver(remote);
    final lp = _parseSemver(local);
    for (int i = 0; i < 3; i++) {
      if (rp[i] > lp[i]) return true;
      if (rp[i] < lp[i]) return false;
    }
    return false;
  }
  List<int> _parseSemver(String v) {
    if (v.isEmpty) return [0, 0, 0];
    v = v.trim();
    if (v.startsWith('v') || v.startsWith('V')) {
      v = v.substring(1);
    }
    final plus = v.indexOf('+');
    if (plus != -1) v = v.substring(0, plus);

    final dash = v.indexOf('-');
    if (dash != -1) v = v.substring(0, dash);

    final parts = v.split('.');
    final major = _safeInt(parts.isNotEmpty ? parts[0] : '0');
    final minor = _safeInt(parts.length > 1 ? parts[1] : '0');
    final patch = _safeInt(parts.length > 2 ? parts[2] : '0');
    return [major, minor, patch];
  }

  int _safeInt(String s) {
    final m = RegExp(r'^\d+').firstMatch(s.trim());
    return m != null ? int.parse(m.group(0)!) : 0;
  }


}