import 'package:flutter/material.dart';
import 'package:mangatracker/core/components/app_skeleton_box.dart';
import 'package:mangatracker/core/theme/app_radius.dart';
import 'package:mangatracker/core/theme/app_spacing.dart';
import 'package:mangatracker/features/notifications/helpers/notification_grouping.dart';
import 'package:mangatracker/l10n/app_localizations.dart';

/// En-tête de tranche : « Aujourd'hui », « Hier », « Plus tôt ».
class NotificationDayLabel extends StatelessWidget {
  final NotificationDay day;

  const NotificationDayLabel({super.key, required this.day});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final label = switch (day) {
      NotificationDay.today => l10n.inboxGroupToday,
      NotificationDay.yesterday => l10n.inboxGroupYesterday,
      NotificationDay.earlier => l10n.inboxGroupOlder,
    };
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.xs,
        AppSpacing.s,
        AppSpacing.xs,
        AppSpacing.s,
      ),
      child: Semantics(
        header: true,
        child: Text(
          label.toUpperCase(),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: scheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.8,
              ),
        ),
      ),
    );
  }
}

/// Bas de liste : chargement de la page suivante, ou échec avec reprise.
class NotificationListFooter extends StatelessWidget {
  final bool failed;
  final VoidCallback onRetry;

  const NotificationListFooter({
    super.key,
    required this.failed,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    if (!failed) {
      return const Padding(
        padding: EdgeInsets.all(AppSpacing.m),
        child: Center(
          child: SizedBox.square(
            dimension: AppSpacing.l,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.s),
      child: Wrap(
        alignment: WrapAlignment.center,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: AppSpacing.s,
        children: [
          Text(
            l10n.notificationsLoadMoreError,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontSize: Theme.of(context).textTheme.labelMedium?.fontSize,
                ),
          ),
          TextButton(onPressed: onRetry, child: Text(l10n.retry)),
        ],
      ),
    );
  }
}

/// Squelette du premier chargement (pas de cache) : quelques lignes.
class NotificationsSkeleton extends StatelessWidget {
  const NotificationsSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(AppSpacing.m),
      itemCount: 6,
      itemBuilder: (context, _) => Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.s),
        child: AppSkeletonBox(
          height: AppSpacing.jumbo + AppSpacing.l,
          borderRadius: AppRadius.circularXxxl,
        ),
      ),
    );
  }
}
