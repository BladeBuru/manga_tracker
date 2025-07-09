import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:open_file/open_file.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:mangatracker/main.dart';
import 'package:permission_handler/permission_handler.dart';

import '../notifier/notifier.dart';
import '../service_locator/service_locator.dart';

class VersionCheckerService {
  static const String remoteUrl = 'https://bladeburu.github.io/manga_tracker/assets/version.json';
  static const String latestReleaseUrl = 'https://api.github.com/repos/BladeBuru/manga_tracker/releases/latest';

  final Notifier _notifier = getIt<Notifier>();
  final Dio _dio = Dio();

  Future<bool> isUpdateAvailable() async {
    try {
      final localVersion = (await PackageInfo.fromPlatform()).version;
      debugPrint("🔍 Version locale : $localVersion");

      final response = await http.get(Uri.parse(remoteUrl));
      if (response.statusCode != 200) {
        debugPrint("❌ Erreur HTTP ${response.statusCode}");
        return false;
      }

      final data = jsonDecode(response.body);
      final remoteVersion = data['latestVersion'];
      if (remoteVersion == null || remoteVersion is! String) {
        debugPrint("❌ Erreur : version non définie ou invalide dans le JSON");
        return false;
      }

      debugPrint("📦 Version distante : $remoteVersion");

      final isAvailable = _isVersionHigher(remoteVersion, localVersion);
      debugPrint("🔄 Mise à jour disponible : $isAvailable");
      return isAvailable;
    } catch (e) {
      debugPrint("❌ Erreur lors de la vérification : $e");
      return false;
    }
  }

  // =======================================================================
  // FONCTION ENTIÈREMENT RÉÉCRITE
  // =======================================================================
  Future<void> downloadAndInstallApk() async {
    try {
      _notifier.info('Recherche de la dernière version...');
      final resp = await http.get(Uri.parse(latestReleaseUrl), headers: {
        'Accept': 'application/vnd.github+json',
      });
      if (resp.statusCode != 200) {
        _notifier.error('Impossible de récupérer les infos de release.');
        return;
      }

      final json = jsonDecode(resp.body);
      final assets = json['assets'] as List<dynamic>;
      final apkAsset = assets.firstWhere(
            (a) => (a['name'] as String).endsWith('.apk'),
        orElse: () => null,
      );
      if (apkAsset == null) {
        _notifier.error('APK introuvable dans la dernière release.');
        return;
      }

      final apkUrl = apkAsset['browser_download_url'] as String;
      _notifier.info('Téléchargement de la mise à jour...');
      final dir = await getTemporaryDirectory();
      final path = '${dir.path}/manga_tracker_update.apk';
      await _dio.download(apkUrl, path);
      debugPrint("📁 Fichier téléchargé à : $path");

      // --- LOGIQUE DE PERMISSION ET D'INSTALLATION CORRIGÉE ---

      // 1. On vérifie si on a déjà la permission
      var status = await Permission.requestInstallPackages.status;

      // 2. Si la permission n'est PAS accordée...
      if (!status.isGranted) {
        final context = navigatorKey.currentContext;
        if (context != null) {
          // ...on affiche une boîte de dialogue pour prévenir l'utilisateur.
          await showDialog(
            context: context,
            builder: (ctx) => AlertDialog(
              title: const Text("Autorisation requise"),
              content: const Text(
                "Pour installer la mise à jour, vous devez autoriser l'installation d'applications depuis cette source dans l'écran suivant.",
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

        // 3. APRÈS, on demande la permission technique.
        status = await Permission.requestInstallPackages.request();
      }

      // 4. On vérifie une dernière fois : si la permission est maintenant accordée, on installe.
      if (status.isGranted) {
        _notifier.info("Lancement de l'installation...");
        await OpenFile.open(path);
      } else {
        _notifier.warning("L'autorisation a été refusée.");
      }

    } catch (e) {
      debugPrint("❌ Erreur critique lors de la mise à jour : $e");
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

  // LES FONCTIONS promptInstallPermission et _showOldAndroidInfo ONT ÉTÉ SUPPRIMÉES

  Future<String> getLocalVersion() async {
    final info = await PackageInfo.fromPlatform();
    return info.version;
  }
}