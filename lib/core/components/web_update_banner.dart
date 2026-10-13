import 'package:flutter/material.dart';
import 'package:mangatracker/core/platform/browser_bridge.dart' as browser;
import 'package:mangatracker/core/services/web_version_watcher.dart';
import 'package:mangatracker/core/theme/app_radius.dart';
import 'package:mangatracker/core/theme/app_spacing.dart';
import 'package:mangatracker/l10n/app_localizations.dart';

/// Web : bandeau non bloquant « Une nouvelle version est disponible —
/// Recharger », par-dessus l'application ([child]).
///
/// Vérifie au démarrage puis à chaque retour sur l'onglet du navigateur.
/// Placé dans `MaterialApp.builder` (au-dessus du `Navigator`) : pas
/// d'infobulle ici, faute d'`Overlay`.
class WebUpdateBanner extends StatefulWidget {
  final Widget child;
  final WebVersionWatcher? watcher;

  /// Recharge la page (injectable pour les tests).
  final VoidCallback onReload;

  const WebUpdateBanner({
    super.key,
    required this.child,
    this.watcher,
    this.onReload = browser.reloadPage,
  });

  @override
  State<WebUpdateBanner> createState() => _WebUpdateBannerState();
}

class _WebUpdateBannerState extends State<WebUpdateBanner> {
  late final WebVersionWatcher _watcher = widget.watcher ?? WebVersionWatcher();
  late final AppLifecycleListener _lifecycle;
  bool _dismissed = false;

  @override
  void initState() {
    super.initState();
    _lifecycle = AppLifecycleListener(onResume: _watcher.check);
    WidgetsBinding.instance.addPostFrameCallback((_) => _watcher.check());
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    if (widget.watcher == null) _watcher.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        ValueListenableBuilder<bool>(
          valueListenable: _watcher.updateAvailable,
          builder: (context, available, _) {
            if (!available || _dismissed) return const SizedBox.shrink();
            return Positioned(
              left: AppSpacing.m,
              right: AppSpacing.m,
              top: MediaQuery.paddingOf(context).top + AppSpacing.s,
              child: _BannerCard(
                onReload: widget.onReload,
                onDismiss: () => setState(() => _dismissed = true),
              ),
            );
          },
        ),
      ],
    );
  }
}

class _BannerCard extends StatelessWidget {
  final VoidCallback onReload;
  final VoidCallback onDismiss;

  const _BannerCard({required this.onReload, required this.onDismiss});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        // Surface du thème (pas `inverse*` : le thème ne les définit pas,
        // le bouton « Recharger » devenait invisible en mode sombre).
        child: Material(
          elevation: 3,
          color: scheme.surfaceContainerHigh,
          shape: RoundedRectangleBorder(
            borderRadius: AppRadius.circularXl,
            side: BorderSide(color: scheme.outlineVariant),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.m,
              AppSpacing.xs,
              AppSpacing.xs,
              AppSpacing.xs,
            ),
            child: Row(
              children: [
                Icon(Icons.system_update_alt_outlined, color: scheme.primary),
                const SizedBox(width: AppSpacing.s),
                Expanded(
                  child: Text(
                    l10n?.newVersionAvailable ?? '',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: scheme.onSurface),
                  ),
                ),
                TextButton(
                  onPressed: onReload,
                  child: Text(l10n?.reloadApp ?? ''),
                ),
                // Pas d'Overlay ici : libellé d'accessibilité, sans infobulle.
                IconButton(
                  onPressed: onDismiss,
                  icon: Icon(
                    Icons.close_outlined,
                    color: scheme.onSurfaceVariant,
                    semanticLabel: l10n?.close,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
