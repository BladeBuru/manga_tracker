import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../../../core/services/app_update_service.dart';
import 'package:mangatracker/core/theme/app_radius.dart';

/// Widget pour afficher le changelog dans le profil
class ChangelogCard extends StatefulWidget {
  const ChangelogCard({super.key});

  @override
  State<ChangelogCard> createState() => _ChangelogCardState();
}

class _ChangelogCardState extends State<ChangelogCard> {
  ChangelogInfo? _changelogInfo;
  String _currentVersion = '';
  bool _isLoading = true;

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
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _showChangelogDialog() async {
    // Charger tous les changelogs pour la dialog
    final appUpdateService = AppUpdateService();
    final allChangelogs = await appUpdateService.getAllChangelogs();
    
    if (allChangelogs == null || allChangelogs.isEmpty) return;

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Quoi de neuf ?'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: allChangelogs.newVersions.map((changes) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Version ${_cleanVersion(changes.version)}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...changes.notes.map((note) => Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: MarkdownBody(
                            data: RegExp(r'^[#\-\*]').hasMatch("$note")
                                ? "$note"
                                : "- $note",
                            styleSheet: MarkdownStyleSheet(
                              p: const TextStyle(fontSize: 14),
                            ),
                          ),
                        )),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _markAsSeen();
            },
            child: const Text('Super !'),
          ),
        ],
      ),
    );
  }

  void _markAsSeen() async {
    final appUpdateService = AppUpdateService();
    await appUpdateService.markChangelogAsSeen();
    setState(() {
      _changelogInfo = null;
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

    final hasNewChangelog = _changelogInfo != null && !_changelogInfo!.isEmpty;

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

