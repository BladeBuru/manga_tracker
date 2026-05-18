import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import 'package:mangatracker/core/components/pastel_tile.dart';
import 'package:mangatracker/core/service_locator/service_locator.dart';
import 'package:mangatracker/core/theme/app_colors.dart';
import 'package:mangatracker/features/auth/services/auth.service.dart';
import 'package:mangatracker/features/profile/services/gdpr.service.dart';
import 'package:mangatracker/features/profile/services/user.service.dart';
import 'package:mangatracker/features/profile/widgets/my_data_dialogs.dart';
import 'package:mangatracker/features/profile/widgets/my_data_info_banner.dart';
import 'package:mangatracker/features/profile/widgets/profile_dialogs.dart';
import 'package:mangatracker/features/profile/widgets/profile_edit_sections.dart';
import 'package:mangatracker/features/profile/widgets/profile_menu_row.dart';
import 'package:mangatracker/l10n/app_localizations.dart';

/// Page « Mes données » — exercice des droits RGPD.
///
/// Design System V1 « Refined Classic » : AppBar hairline + sections
/// groupées en cards 16px radius + PastelTile + ProfileMenuRow.
///
/// Conformité :
///  - Article 15 : droit d'accès → "Résumé de mes données"
///  - Article 20 : droit à la portabilité → "Exporter mes données"
///  - Article 17 : droit à l'effacement → "Supprimer mon compte"
///    (réutilise `ProfileDialogs.showDeleteAccountConfirm`)
class MyDataView extends StatefulWidget {
  const MyDataView({super.key});

  @override
  State<MyDataView> createState() => _MyDataViewState();
}

class _MyDataViewState extends State<MyDataView> {
  final GdprService _gdpr = getIt<GdprService>();
  final UserService _userService = getIt<UserService>();
  final AuthService _authService = getIt<AuthService>();
  bool _exporting = false;
  bool _summaryLoading = false;
  bool _deleting = false;

  // ─── Actions ─────────────────────────────────────────────────────────────

  Future<void> _showSummary() async {
    if (_summaryLoading) return;
    setState(() => _summaryLoading = true);
    final l10n = AppLocalizations.of(context)!;
    try {
      final summary = await _gdpr.getDataSummary();
      if (!mounted) return;
      if (summary == null) {
        _showSnack(l10n.gdprSummaryLoadFailed, error: true);
        return;
      }
      await MyDataDialogs.showSummary(context, summary);
    } finally {
      if (mounted) setState(() => _summaryLoading = false);
    }
  }

  Future<void> _exportData() async {
    if (_exporting) return;
    setState(() => _exporting = true);
    final l10n = AppLocalizations.of(context)!;
    try {
      final json = await _gdpr.exportData();
      if (!mounted) return;
      if (json == null) {
        _showSnack(l10n.gdprExportFailedSnack, error: true);
        return;
      }
      // UX simple, cross-platform : copier dans le presse-papier.
      await Clipboard.setData(ClipboardData(text: json));
      if (!mounted) return;
      _showSnack(l10n.gdprExportSuccessSnack);
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  Future<void> _onDeleteAccount() async {
    if (_deleting) return;
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await ProfileDialogs.showDeleteAccountConfirm(context);
    if (!confirmed || !mounted) return;
    setState(() => _deleting = true);
    try {
      await _userService.deleteAccount();
      await _authService.logout();
      if (!mounted) return;
      _showSnack(l10n.accountDeletedSuccess);
      context.go('/login');
    } catch (_) {
      if (!mounted) return;
      _showSnack(l10n.accountDeleteError, error: true);
    } finally {
      if (mounted) setState(() => _deleting = false);
    }
  }

  void _showSnack(String msg, {bool error = false}) {
    final scheme = Theme.of(context).colorScheme;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: error ? scheme.error : null,
      ),
    );
  }

  // ─── Build ───────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final bg = brightness == Brightness.dark
        ? AppColors.dsBgDark
        : AppColors.dsBgLight;
    return Scaffold(
      backgroundColor: bg,
      appBar: _MyDataAppBar(bg: bg),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final hPad = constraints.maxWidth >= 600 ? 32.0 : 16.0;
          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 700),
              child: ListView(
                padding: EdgeInsets.fromLTRB(hPad, 16, hPad, 32),
                children: [
                  const MyDataInfoBanner(),
                  const SizedBox(height: 22),
                  _PersonalDataSection(
                    summaryLoading: _summaryLoading,
                    onShowSummary: _showSummary,
                  ),
                  const SizedBox(height: 22),
                  _MyRightsSection(
                    exporting: _exporting,
                    onExport: _exportData,
                    onPrivacy: () => MyDataDialogs.showLegalDoc(
                      context,
                      isPrivacy: true,
                    ),
                    onTos: () => MyDataDialogs.showLegalDoc(
                      context,
                      isPrivacy: false,
                    ),
                  ),
                  const SizedBox(height: 22),
                  _DeletionSection(
                    deleting: _deleting,
                    onDelete: _onDeleteAccount,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

}

// ─────────────────────────────────────────────────────────────────────────────
// AppBar privée — chevron + label "Profil" (gauche) + titre centré + hairline
// bottom border. Style aligné avec ProfileEditView.
// ─────────────────────────────────────────────────────────────────────────────

class _MyDataAppBar extends StatelessWidget implements PreferredSizeWidget {
  final Color bg;
  const _MyDataAppBar({required this.bg});

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final brightness = Theme.of(context).brightness;
    final scheme = Theme.of(context).colorScheme;
    return AppBar(
      backgroundColor: bg,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      shape: Border(
        bottom: BorderSide(
          color: AppColors.dsHairline(brightness),
          width: 1,
        ),
      ),
      title: Text(
        l10n.myDataTitle,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: scheme.onSurface,
        ),
      ),
      centerTitle: true,
      leading: TextButton(
        onPressed: () => context.pop(),
        style: TextButton.styleFrom(
          foregroundColor: scheme.primary,
          padding: const EdgeInsets.symmetric(horizontal: 4),
          minimumSize: const Size(64, 40),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.chevron_left, size: 22, color: scheme.primary),
            Text(
              l10n.myDataBackLabel,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: scheme.primary,
              ),
            ),
          ],
        ),
      ),
      leadingWidth: 90,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Sections (sous-widgets privés pour rester < 150 lignes / classe)
// ─────────────────────────────────────────────────────────────────────────────

class _PersonalDataSection extends StatelessWidget {
  final bool summaryLoading;
  final VoidCallback onShowSummary;

  const _PersonalDataSection({
    required this.summaryLoading,
    required this.onShowSummary,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return ProfileEditSection(
      label: l10n.myDataSectionPersonalData,
      children: [
        ProfileMenuRow(
          leading: const PastelTile(
            icon: Icons.donut_small_outlined,
            color: PastelTileColor.green,
          ),
          title: l10n.myDataSummaryTitle,
          subtitle: l10n.myDataSummarySubtitle,
          onTap: summaryLoading ? null : onShowSummary,
          trailing: summaryLoading ? const _RowSpinner() : null,
        ),
      ],
    );
  }
}

class _MyRightsSection extends StatelessWidget {
  final bool exporting;
  final VoidCallback onExport;
  final VoidCallback onPrivacy;
  final VoidCallback onTos;

  const _MyRightsSection({
    required this.exporting,
    required this.onExport,
    required this.onPrivacy,
    required this.onTos,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return ProfileEditSection(
      label: l10n.myDataSectionMyRights,
      children: [
        ProfileMenuRow(
          leading: const PastelTile(
            icon: Icons.download_outlined,
            color: PastelTileColor.blue,
          ),
          title: l10n.gdprExportTitle,
          subtitle: l10n.myDataExportSubtitle,
          onTap: exporting ? null : onExport,
          trailing: exporting ? const _RowSpinner() : null,
        ),
        ProfileMenuRow(
          leading: const PastelTile(
            icon: Icons.privacy_tip_outlined,
            color: PastelTileColor.teal,
          ),
          title: l10n.privacyPolicyTitle,
          subtitle: l10n.privacyPolicySubtitle,
          onTap: onPrivacy,
        ),
        ProfileMenuRow(
          leading: const PastelTile(
            icon: Icons.menu_book_outlined,
            color: PastelTileColor.purple,
          ),
          title: l10n.termsOfServiceTitle,
          subtitle: l10n.termsOfServiceSubtitle,
          onTap: onTos,
        ),
      ],
    );
  }
}

class _DeletionSection extends StatelessWidget {
  final bool deleting;
  final VoidCallback onDelete;

  const _DeletionSection({
    required this.deleting,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return ProfileEditSection(
      label: l10n.myDataSectionDeletion,
      children: [
        ProfileMenuRow(
          danger: true,
          leading: const PastelTile(
            icon: Icons.delete_outline,
            color: PastelTileColor.red,
          ),
          title: l10n.deleteAccount,
          subtitle: l10n.myDataDeleteAccountSubtitle,
          onTap: deleting ? null : onDelete,
          trailing: deleting ? const _RowSpinner() : null,
        ),
      ],
    );
  }
}

class _RowSpinner extends StatelessWidget {
  const _RowSpinner();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 18,
      height: 18,
      child: CircularProgressIndicator(
        strokeWidth: 2,
        color: Theme.of(context).colorScheme.primary,
      ),
    );
  }
}
