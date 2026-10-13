import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mangatracker/core/components/app_empty_state.dart';
import 'package:mangatracker/core/components/offline_banner.dart';
import 'package:mangatracker/core/components/session_rejected_banner.dart';
import 'package:mangatracker/core/theme/app_spacing.dart';
import 'package:mangatracker/features/notifications/dto/app_notification.dto.dart';
import 'package:mangatracker/features/notifications/helpers/notification_grouping.dart';
import 'package:mangatracker/features/notifications/widgets/notification_list_footer.dart';
import 'package:mangatracker/features/notifications/widgets/notification_tile.dart';
import 'package:mangatracker/l10n/app_localizations.dart';

/// Liste du centre : bandeaux d'état, lignes groupées par jour, défilement
/// infini (la page suivante est demandée à l'approche de la fin).
class NotificationsList extends StatefulWidget {
  final List<AppNotificationDto> items;
  final bool isOffline;
  final bool requiresReauth;
  final bool hasMore;
  final bool isLoadingMore;
  final bool loadMoreFailed;
  final ValueChanged<AppNotificationDto> onOpen;
  final VoidCallback onLoadMore;
  final Future<void> Function() onRefresh;

  const NotificationsList({
    super.key,
    required this.items,
    required this.isOffline,
    required this.requiresReauth,
    required this.hasMore,
    required this.isLoadingMore,
    required this.loadMoreFailed,
    required this.onOpen,
    required this.onLoadMore,
    required this.onRefresh,
  });

  @override
  State<NotificationsList> createState() => _NotificationsListState();
}

class _NotificationsListState extends State<NotificationsList> {
  /// Distance du bas à laquelle la page suivante est demandée.
  static const double _prefetchExtent = 400;

  final ScrollController _controller = ScrollController();

  @override
  void initState() {
    super.initState();
    _controller.addListener(_maybeLoadMore);
    _checkAfterLayout();
  }

  @override
  void didUpdateWidget(covariant NotificationsList oldWidget) {
    super.didUpdateWidget(oldWidget);
    _checkAfterLayout();
  }

  /// Une page courte (grand écran) ne défile pas : sans ce contrôle après
  /// mise en page, la suite ne serait jamais demandée.
  void _checkAfterLayout() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _maybeLoadMore();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _maybeLoadMore() {
    if (!_controller.hasClients) return;
    final position = _controller.position;
    if (widget.hasMore &&
        !widget.isLoadingMore &&
        !widget.loadMoreFailed &&
        position.extentAfter < _prefetchExtent) {
      widget.onLoadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final entries = NotificationGrouping.flatten(widget.items, DateTime.now());
    final banners = <Widget>[
      if (widget.requiresReauth)
        SessionRejectedBanner(onReconnect: () => context.push('/login'))
      else if (widget.isOffline)
        const OfflineBanner(),
    ];
    final showFooter = widget.hasMore || widget.loadMoreFailed;
    final count = banners.length +
        (entries.isEmpty ? 1 : entries.length) +
        (showFooter ? 1 : 0);
    return RefreshIndicator(
      onRefresh: widget.onRefresh,
      child: ListView.builder(
        controller: _controller,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.m,
          AppSpacing.m,
          AppSpacing.m,
          AppSpacing.l,
        ),
        itemCount: count,
        itemBuilder: (context, index) {
          if (index < banners.length) return banners[index];
          final i = index - banners.length;
          if (entries.isEmpty && i == 0) {
            return AppEmptyState(
              icon: Icons.notifications_none_outlined,
              title: l10n.notificationsEmptyTitle,
              subtitle: l10n.notificationsEmptySubtitle,
            );
          }
          if (i >= entries.length) {
            return NotificationListFooter(
              failed: widget.loadMoreFailed,
              onRetry: widget.onLoadMore,
            );
          }
          final entry = entries[i];
          return switch (entry) {
            NotificationDayHeader(:final day) => NotificationDayLabel(day: day),
            NotificationItemEntry(:final notification) => Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.s),
                child: NotificationTile(
                  key: ValueKey(notification.id),
                  notification: notification,
                  onTap: () => widget.onOpen(notification),
                ),
              ),
          };
        },
      ),
    );
  }
}
