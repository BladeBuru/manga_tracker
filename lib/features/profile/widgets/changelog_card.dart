import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../../../core/services/app_update_service.dart';
import '../../../core/services/translation_service.dart';
import '../../../core/services/language_service.dart';
import '../../../core/service_locator/service_locator.dart';
import '../../../core/components/changelog_dialog.dart';
import 'package:mangatracker/core/theme/app_radius.dart';

/// Widget pour afficher le changelog dans le profil
class ChangelogCard extends StatefulWidget {
  const ChangelogCard({super.key});

  @override
  State<ChangelogCard> createState() => _ChangelogCardState();
}

class _ChangelogCardState extends State<ChangelogCard> {
  ChangelogInfo? _changelogInfo;
  ChangelogInfo? _translatedChangelogInfo;
  String _currentVersion = '';
  bool _isLoading = true;
  final TranslationService _translationService = getIt<TranslationService>();

  @override
  void initState() {
    super.initState();
    _loadChangelog();
  }

  Future<void> _loadChangelog() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final appUpdateService = AppUpdateService();
      final newChangelog = await appUpdateService.getNewChangelog();
      final allChangelogs = await appUpdateService.getAllChangelogs();
      
      setState(() {
        _currentVersion = packageInfo.version;
        // Afficher les nouveaux changelogs s'il y en a, sinon tous les changelogs
        _changelogInfo = newChangelog ?? allChangelogs;
        // Initialiser avec les changelogs originaux pour les afficher immédiatement
        _translatedChangelogInfo = _changelogInfo;
        _isLoading = false;
      });
      
      // Traduire les changelogs en arrière-plan sans bloquer l'affichage
      if (_changelogInfo != null) {
        _translateChangelogs();
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  /// Traduit les changelogs si nécessaire (en arrière-plan)
  Future<void> _translateChangelogs() async {
    if (_changelogInfo == null || _changelogInfo!.isEmpty) return;
    
    try {
      // Obtenir la langue actuelle de l'application
      final languageService = await getIt.getAsync<LanguageService>();
      final currentLocale = languageService.getCurrentLocale();
      final targetLanguage = currentLocale.languageCode;
      
      // Ne traduire que si la langue n'est pas le français (langue par défaut)
      if (targetLanguage != 'fr') {
        debugPrint('🔄 Traduction changelogs: début (${_changelogInfo!.newVersions.length} versions)');
        final translatedVersions = <VersionChanges>[];
        
        for (int v = 0; v < _changelogInfo!.newVersions.length; v++) {
          final versionChanges = _changelogInfo!.newVersions[v];
          debugPrint('🔄 Traduction version ${v + 1}/${_changelogInfo!.newVersions.length}: ${versionChanges.version} (${versionChanges.notes.length} notes)');
          
          final translatedNotes = <String>[];
          
          for (int n = 0; n < versionChanges.notes.length; n++) {
            final note = versionChanges.notes[n];
            
            // Convertir la note en texte (gérer différents types)
            String noteText;
            if (note is String) {
              noteText = note;
            } else if (note is List) {
              // Si c'est une liste, joindre les éléments
              noteText = note.map((e) => e.toString()).join('\n');
            } else {
              noteText = note.toString();
            }
            
            // Nettoyer le texte (enlever les préfixes markdown si présents)
            noteText = noteText.trim();
            if (noteText.startsWith('- ')) {
              noteText = noteText.substring(2);
            }
            if (noteText.startsWith('* ')) {
              noteText = noteText.substring(2);
            }
            
            debugPrint('  📝 Note ${n + 1}/${versionChanges.notes.length}: ${noteText.length} caractères');
            
            if (noteText.isNotEmpty) {
              // Vérifier le cache par version et note
              String? translated = await _translationService.getCachedChangelogTranslation(
                versionChanges.version,
                noteText,
                targetLanguage,
              );
              
              if (translated == null) {
                // Pas dans le cache, traduire
                translated = await _translationService.translateText(
                  noteText,
                  targetLanguage,
                );
                
                // Mettre en cache si la traduction a réussi
                if (translated != null && translated != noteText && translated.isNotEmpty) {
                  await _translationService.cacheChangelogTranslation(
                    versionChanges.version,
                    noteText,
                    targetLanguage,
                    translated,
                  );
                }
              } else {
                debugPrint('  ✅ Note ${n + 1} trouvée dans le cache');
              }
              
              if (translated != null && translated != noteText && translated.isNotEmpty) {
                debugPrint('  ✅ Note ${n + 1} traduite: ${translated.length} caractères');
                translatedNotes.add(translated);
              } else {
                debugPrint('  ⚠️ Note ${n + 1} non traduite ou identique, garder original');
                translatedNotes.add(noteText);
              }
            } else {
              translatedNotes.add(noteText);
            }
            
            // Petite pause entre les notes pour éviter de surcharger l'API
            if (n < versionChanges.notes.length - 1) {
              await Future.delayed(const Duration(milliseconds: 300));
            }
          }
          
          translatedVersions.add(VersionChanges(
            version: versionChanges.version,
            notes: translatedNotes,
          ));
          
          // Pause entre les versions
          if (v < _changelogInfo!.newVersions.length - 1) {
            await Future.delayed(const Duration(milliseconds: 500));
          }
        }
        
        debugPrint('✅ Traduction changelogs: terminée (${translatedVersions.length} versions traduites)');
        
        // Mettre à jour uniquement si le widget est toujours monté
        if (mounted) {
          setState(() {
            _translatedChangelogInfo = ChangelogInfo(translatedVersions);
          });
        }
      }
      // Si français, _translatedChangelogInfo est déjà initialisé avec _changelogInfo
    } catch (e, stackTrace) {
      debugPrint('❌ Erreur lors de la traduction des changelogs: $e');
      debugPrint('❌ Stack trace: $stackTrace');
      // En cas d'erreur, garder les changelogs originaux
    }
  }

  Future<void> _showChangelogDialog() async {
    // Charger tous les changelogs pour la dialog
    final appUpdateService = AppUpdateService();
    final allChangelogs = await appUpdateService.getAllChangelogs();
    
    if (allChangelogs == null || allChangelogs.isEmpty) return;
    
    ChangelogDialog.show(
      context,
      allChangelogs,
      barrierDismissible: true,
      onClose: _markAsSeen,
    );
  }

  void _markAsSeen() async {
    final appUpdateService = AppUpdateService();
    await appUpdateService.markChangelogAsSeen();
    setState(() {
      _changelogInfo = null;
      _translatedChangelogInfo = null;
    });
  }

  String _cleanVersion(String version) {
    return version.replaceAll('+', ' build ');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_isLoading) {
      return const SizedBox.shrink();
    }

    final displayChangelog = _translatedChangelogInfo ?? _changelogInfo;
    final hasNewChangelog = displayChangelog != null && !displayChangelog.isEmpty;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.xl),
        side: BorderSide(
          color: hasNewChangelog
              ? theme.colorScheme.primary
              : theme.colorScheme.outline.withValues(alpha: 0.1),
          width: hasNewChangelog ? 2 : 1,
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: hasNewChangelog
                ? theme.colorScheme.primary.withValues(alpha: 0.1)
                : theme.colorScheme.surfaceContainerHighest,
            borderRadius: AppRadius.circularXl,
          ),
          child: Icon(
            hasNewChangelog ? Icons.new_releases : Icons.info_outline,
            color: hasNewChangelog
                ? theme.colorScheme.primary
                : theme.colorScheme.onSurface.withValues(alpha: 0.6),
            size: 24,
          ),
        ),
        title: Text(
          hasNewChangelog
              ? 'Nouvelles fonctionnalités disponibles'
              : 'Version actuelle',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          'v${_cleanVersion(_currentVersion)}',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
          ),
        ),
        trailing: hasNewChangelog
            ? Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary,
                  borderRadius: AppRadius.circularXl,
                ),
                child: Text(
                  'Nouveau',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              )
            : Icon(
                Icons.chevron_right,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
              ),
        onTap: _showChangelogDialog,
      ),
    );
  }
}

