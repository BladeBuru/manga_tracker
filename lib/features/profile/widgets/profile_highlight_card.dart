import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';

import 'package:mangatracker/core/components/changelog_dialog.dart';
import 'package:mangatracker/core/components/pastel_tile.dart';
import 'package:mangatracker/core/services/app_update_service.dart';
import 'package:mangatracker/core/services/language_service.dart';
import 'package:mangatracker/core/services/translation_service.dart';
import 'package:mangatracker/core/service_locator/service_locator.dart';
import 'package:mangatracker/core/theme/app_colors.dart';
import 'package:mangatracker/l10n/app_localizations.dart';

// ╔═══════════════════════════════════════════════════════════════════════╗
// ║  ProfileHighlightCard — carte "Nouvelles fonctionnalités" (Design V1).║
// ║  Carte bordée rouge avec PastelTile sparkles + titre + version mono   ║
// ║  + pill "Nouveau" rouge. Tap → ouvre ChangelogDialog avec traduction. ║
// ║                                                                       ║
// ║  Source : `.claude-design/manga-tracker/project/screen-account.jsx`   ║
// ║           (lignes 41-70).                                             ║
// ╚═══════════════════════════════════════════════════════════════════════╝

class ProfileHighlightCard extends StatefulWidget {
  const ProfileHighlightCard({super.key});

  @override
  State<ProfileHighlightCard> createState() => _ProfileHighlightCardState();
}

class _ProfileHighlightCardState extends State<ProfileHighlightCard> {
  ChangelogInfo? _changelogInfo;
  ChangelogInfo? _translatedChangelogInfo;
  String _currentVersion = '';
  bool _isLoading = true;
  // **Fix 2026-05-18** : sépare la notion de "nouveau changelog non vu"
  // du contenu changelog affiché dans le dialog. Avant, on faisait fallback
  // sur `allChangelogs` ce qui rendait `hasNew` toujours vrai → le badge
  // "Nouveau" persistait après lecture. Désormais : on track explicitement
  // si l'utilisateur n'a pas encore vu la version courante.
  bool _hasNewChangelog = false;
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

      if (!mounted) return;
      // `newChangelog` est non-null UNIQUEMENT si l'utilisateur n'a pas
      // encore vu la version courante (cf. AppUpdateService.markChangelogAsSeen).
      // On affiche systématiquement les "allChangelogs" dans le dialog, mais
      // seul `_hasNewChangelog` contrôle l'état "à voir" (border rouge + pill).
      setState(() {
        _currentVersion = packageInfo.version;
        _changelogInfo = allChangelogs;
        _translatedChangelogInfo = allChangelogs;
        _hasNewChangelog = newChangelog != null && !newChangelog.isEmpty;
        _isLoading = false;
      });

      if (_changelogInfo != null) {
        _translateChangelogs();
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  Future<void> _translateChangelogs() async {
    if (_changelogInfo == null || _changelogInfo!.isEmpty) return;

    try {
      final languageService = await getIt.getAsync<LanguageService>();
      final targetLanguage = languageService.getCurrentLocale().languageCode;
      if (targetLanguage == 'fr') return;

      final translatedVersions = <VersionChanges>[];
      for (final versionChanges in _changelogInfo!.newVersions) {
        final translatedNotes = <String>[];
        for (final note in versionChanges.notes) {
          String noteText = note is String ? note : note.toString();
          noteText = noteText.trim();
          if (noteText.startsWith('- ') || noteText.startsWith('* ')) {
            noteText = noteText.substring(2);
          }
          if (noteText.isEmpty) {
            translatedNotes.add(noteText);
            continue;
          }
          String? translated = await _translationService
              .getCachedChangelogTranslation(
            versionChanges.version,
            noteText,
            targetLanguage,
          );
          translated ??= await _translationService.translateText(
            noteText,
            targetLanguage,
          );
          if (translated != null && translated != noteText && translated.isNotEmpty) {
            await _translationService.cacheChangelogTranslation(
              versionChanges.version,
              noteText,
              targetLanguage,
              translated,
            );
            translatedNotes.add(translated);
          } else {
            translatedNotes.add(noteText);
          }
        }
        translatedVersions
            .add(VersionChanges(version: versionChanges.version, notes: translatedNotes));
      }

      if (mounted) {
        setState(() {
          _translatedChangelogInfo = ChangelogInfo(translatedVersions);
        });
      }
    } catch (e, stackTrace) {
      debugPrint('Erreur traduction changelog: $e');
      debugPrint('$stackTrace');
    }
  }

  Future<void> _showChangelogDialog() async {
    // **Fix 2026-05-18** : utilise la version DÉJÀ TRADUITE en mémoire si
    // dispo, au lieu de refetcher (sinon le dialog s'ouvre en français même
    // si la langue active est l'EN/JA/etc.). Bonus : 1 round-trip de moins.
    final source = _translatedChangelogInfo ?? _changelogInfo;
    if (source == null || source.isEmpty) {
      // Fallback si pas de cache en mémoire (cas edge : tap pendant le load).
      final appUpdateService = AppUpdateService();
      final allChangelogs = await appUpdateService.getAllChangelogs();
      if (allChangelogs == null || allChangelogs.isEmpty) return;
      if (!mounted) return;
      ChangelogDialog.show(
        context,
        allChangelogs,
        barrierDismissible: true,
        onClose: _markAsSeen,
      );
      return;
    }
    if (!mounted) return;
    ChangelogDialog.show(
      context,
      source,
      barrierDismissible: true,
      onClose: _markAsSeen,
    );
  }

  Future<void> _markAsSeen() async {
    final appUpdateService = AppUpdateService();
    await appUpdateService.markChangelogAsSeen();
    if (!mounted) return;
    // **Fix 2026-05-18** : on garde le contenu changelog dispo pour re-ouvrir
    // l'historique plus tard, mais on supprime le badge "Nouveau". Avant on
    // mettait tout à null → la carte disparaissait après la première lecture.
    setState(() {
      _hasNewChangelog = false;
    });
  }

  String _cleanVersion(String version) {
    return version.replaceAll('+', ' build ');
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const SizedBox.shrink();

    final l10n = AppLocalizations.of(context)!;
    final brightness = Theme.of(context).brightness;
    final isDark = brightness == Brightness.dark;
    final scheme = Theme.of(context).colorScheme;
    // **Fix 2026-05-18** : `hasNew` est désormais piloté par `_hasNewChangelog`
    // explicite (true uniquement si la version courante n'a pas été vue).
    final hasNew = _hasNewChangelog;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: _showChangelogDialog,
        child: Ink(
          decoration: BoxDecoration(
            color: isDark ? AppColors.dsSurfaceDark : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: hasNew ? AppColors.primary : AppColors.dsHairline(brightness),
              width: 1,
            ),
          ),
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const PastelTile(
                icon: Icons.auto_awesome_outlined,
                color: PastelTileColor.red,
                iconSize: 20,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      l10n.profileHighlightTitle,
                      style: TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w700,
                        color: scheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'v${_cleanVersion(_currentVersion)}',
                      style: TextStyle(
                        fontFamily: 'JetBrainsMono',
                        fontFeatures: const [FontFeature.tabularFigures()],
                        fontSize: 11.5,
                        color: AppColors.dsText2(brightness),
                      ),
                    ),
                  ],
                ),
              ),
              if (hasNew) ...[
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    l10n.profileNewBadge,
                    style: const TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.23, // 0.02em * 11.5
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
