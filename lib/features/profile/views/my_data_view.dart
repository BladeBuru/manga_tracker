import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mangatracker/core/service_locator/service_locator.dart';
import 'package:mangatracker/core/theme/app_radius.dart';
import 'package:mangatracker/features/profile/services/gdpr.service.dart';
import 'package:mangatracker/l10n/app_localizations.dart';

/// Page « Mes données » — exercice des droits RGPD.
///
/// Conformité :
///  - Article 15 : droit d'accès → bouton "Voir mes données"
///  - Article 20 : droit à la portabilité → bouton "Exporter mes données"
///  - Article 17 : droit à l'effacement → renvoie vers la suppression de
///    compte existante (pas de duplication)
///
/// Le contenu est délibérément simple et copyable. Pas de BLoC : pas
/// d'état complexe à gérer.
class MyDataView extends StatefulWidget {
  const MyDataView({super.key});

  @override
  State<MyDataView> createState() => _MyDataViewState();
}

class _MyDataViewState extends State<MyDataView> {
  final GdprService _gdpr = getIt<GdprService>();
  bool _exporting = false;

  Future<void> _showSummary() async {
    final summary = await _gdpr.getDataSummary();
    if (!mounted) return;
    if (summary == null) {
      _showError('Erreur de chargement');
      return;
    }
    final formatted =
        const JsonEncoder.withIndent('  ').convert(summary);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Mes données'),
        content: SingleChildScrollView(
          child: SelectableText(
            formatted,
            style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }

  Future<void> _exportData() async {
    setState(() => _exporting = true);
    try {
      final json = await _gdpr.exportData();
      if (!mounted) return;
      if (json == null) {
        _showError("Échec de l'export");
        return;
      }

      // UX simple, cross-platform : copier dans le presse-papier.
      // Pour une vraie expérience "télécharger un fichier", brancher
      // path_provider + share_plus selon la plateforme.
      await Clipboard.setData(ClipboardData(text: json));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Vos données ont été copiées dans le presse-papier (JSON).',
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n?.myDataTitle ?? 'Mes données'),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final horizontalPadding = constraints.maxWidth >= 600 ? 24.0 : 16.0;
          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: ListView(
                padding: EdgeInsets.symmetric(
                  horizontal: horizontalPadding,
                  vertical: 16,
                ),
                children: [
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.lg),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                l10n?.gdprIntro ??
                    'Conformément au RGPD, vous disposez de droits sur vos données personnelles. '
                        'Cette page vous permet de les exercer simplement.',
                style: theme.textTheme.bodyMedium,
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Droit d'accès (article 15)
          _ActionTile(
            icon: Icons.visibility_outlined,
            title: l10n?.gdprAccessTitle ?? 'Voir mes données',
            subtitle: l10n?.gdprAccessSubtitle ??
                'Article 15 — résumé des informations stockées',
            onTap: _showSummary,
          ),
          const SizedBox(height: 8),

          // Droit à la portabilité (article 20)
          _ActionTile(
            icon: Icons.download_outlined,
            title: l10n?.gdprExportTitle ?? 'Exporter mes données',
            subtitle: l10n?.gdprExportSubtitle ??
                'Article 20 — JSON complet copié dans le presse-papier',
            loading: _exporting,
            onTap: _exporting ? null : _exportData,
          ),
          const SizedBox(height: 24),

          // Liens documents légaux
          Text(
            l10n?.gdprLegalDocs ?? 'Documents légaux',
            style: theme.textTheme.titleSmall,
          ),
          const SizedBox(height: 8),
          ListTile(
            leading: const Icon(Icons.privacy_tip_outlined),
            title: Text(
              l10n?.privacyPolicyTitle ?? 'Politique de confidentialité',
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _openLegalDoc(context, 'privacy'),
          ),
          ListTile(
            leading: const Icon(Icons.description_outlined),
            title: Text(
              l10n?.termsOfServiceTitle ?? "Conditions d'utilisation",
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _openLegalDoc(context, 'tos'),
          ),

          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.orange.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.info_outline, color: Colors.orange, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    l10n?.gdprDeleteHint ??
                        'Pour supprimer définitivement votre compte, rendez-vous dans '
                            'Profil → Supprimer mon compte. Cette action est irréversible.',
                    style: theme.textTheme.bodySmall,
                  ),
                ),
              ],
            ),
          ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _openLegalDoc(BuildContext context, String kind) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          kind == 'privacy'
              ? 'Politique de confidentialité'
              : "Conditions d'utilisation",
        ),
        content: SingleChildScrollView(
          child: Text(
            kind == 'privacy'
                ? "La politique de confidentialité complète est disponible à l'adresse : "
                    "[À renseigner par l'éditeur]\n\n"
                    "Données collectées : email, mot de passe (hashé), bibliothèque manga, "
                    "préférences. Aucune donnée n'est vendue à des tiers."
                : "Les CGU complètes sont disponibles à l'adresse : "
                    "[À renseigner par l'éditeur]\n\n"
                    "Manga Tracker est fourni en l'état, sans garantie. "
                    "L'éditeur décline toute responsabilité pour l'utilisation "
                    "non conforme par l'utilisateur (contenu illégal, scraping, etc.).",
            style: const TextStyle(fontSize: 13),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;
  final bool loading;

  const _ActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.onTap,
    this.loading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: ListTile(
        leading: loading
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Icon(icon),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
