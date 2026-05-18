import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mangatracker/core/components/app_empty_state.dart';
import 'package:mangatracker/core/components/app_error_state.dart';
import 'package:mangatracker/core/router/app_router.dart';
import 'package:mangatracker/core/service_locator/service_locator.dart';
import 'package:mangatracker/core/services/notification_counts_service.dart';
import 'package:mangatracker/core/theme/app_colors.dart';
import 'package:mangatracker/core/theme/app_spacing.dart';
import 'package:mangatracker/core/utils/responsive_layout.dart';
import 'package:mangatracker/features/profile/widgets/profile_edit_sections.dart';
import 'package:mangatracker/features/sharing/dto/share.dto.dart';
import 'package:mangatracker/features/sharing/services/sharing.service.dart';
import 'package:mangatracker/features/sharing/widgets/inbox_filter_chips.dart';
import 'package:mangatracker/features/sharing/widgets/inbox_share_tile.dart';
import 'package:mangatracker/l10n/app_localizations.dart';

/// Page Inbox des shares reçus — Design System V1 « Refined Classic ».
///
/// Refactor 2026-05-18 :
///  - App bar V1 (titre 16/700, hairline en bas, centré, page-bg).
///  - Page background `dsBg(brightness)`.
///  - Filter pills "Toutes / Non lues / Lues" avec compteurs.
///  - Liste groupée par "Aujourd'hui · Hier · Cette semaine · Plus tôt"
///    dans des `ProfileEditSection` (label uppercase tracké + card hairline).
///  - Chaque row : `InboxShareTile` (avatar + sender + titre + date + pill
///    NOUVEAU pour les non-vues).
///  - Empty state pastel V1, pull-to-refresh, error state, navigation à
///    `/manga/$muId` preservés.
///
/// Comportement métier conservé :
///  - markAllSeen() au mount + refresh NotificationCountsService.
///  - getInbox() au pull-to-refresh.
///  - Tap row → `context.push('/manga/$muId', extra: MangaDetailExtras(...))`.
class InboxPage extends StatefulWidget {
  const InboxPage({super.key});

  @override
  State<InboxPage> createState() => _InboxPageState();
}

class _InboxPageState extends State<InboxPage> with ResponsiveLayoutMixin {
  final SharingService _service = getIt<SharingService>();

  List<MangaShareDto>? _items;
  String? _error;
  InboxFilter _filter = InboxFilter.all;

  @override
  void initState() {
    super.initState();
    _loadAndMarkSeen();
  }

  Future<void> _loadAndMarkSeen() async {
    try {
      final items = await _service.getInbox();
      if (!mounted) return;
      setState(() {
        _items = items;
        _error = null;
      });
      // ignore: unawaited_futures
      _service.markAllSeen().then((_) {
        try {
          getIt<NotificationCountsService>().refresh();
        } catch (_) {}
      }).onError((_, __) {});
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    }
  }

  void _openShare(MangaShareDto share) {
    final muId = int.tryParse(share.mangaMuId);
    if (muId != null && muId > 0) {
      context.push(
        '/manga/$muId',
        extra: MangaDetailExtras(title: share.mangaTitle),
      );
    }
  }

  List<MangaShareDto> _applyFilter(List<MangaShareDto> all) {
    switch (_filter) {
      case InboxFilter.all:
        return all;
      case InboxFilter.unread:
        return all.where((s) => s.isNew).toList(growable: false);
      case InboxFilter.read:
        return all.where((s) => !s.isNew).toList(growable: false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final brightness = Theme.of(context).brightness;
    final scheme = Theme.of(context).colorScheme;
    final bg = brightness == Brightness.dark
        ? AppColors.dsBgDark
        : AppColors.dsBgLight;
    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
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
        centerTitle: true,
        title: Text(
          l10n.inboxTitle,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: scheme.onSurface,
            letterSpacing: -0.15,
          ),
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxContentWidth(context)),
          child: _buildBody(context, l10n),
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context, AppLocalizations l10n) {
    if (_error != null) {
      return AppErrorState(
        message: _error!,
        retryLabel: l10n.retry,
        onRetry: _loadAndMarkSeen,
      );
    }
    if (_items == null) {
      return const Center(child: CircularProgressIndicator());
    }
    final all = _items!;
    final unread = all.where((s) => s.isNew).length;
    final filtered = _applyFilter(all);
    final hPad = horizontalPadding(context);

    return RefreshIndicator(
      onRefresh: _loadAndMarkSeen,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding:
            EdgeInsets.fromLTRB(hPad, AppSpacing.m, hPad, AppSpacing.l),
        children: [
          if (all.isNotEmpty)
            InboxFilterChips(
              selected: _filter,
              totalCount: all.length,
              unreadCount: unread,
              readCount: all.length - unread,
              onChanged: (f) => setState(() => _filter = f),
              labelAll: l10n.inboxFilterAll,
              labelUnread: l10n.inboxFilterUnread,
              labelRead: l10n.inboxFilterRead,
            ),
          if (all.isNotEmpty) const SizedBox(height: AppSpacing.m),
          if (filtered.isEmpty)
            _InboxEmpty(l10n: l10n, filter: _filter, isFiltered: all.isNotEmpty)
          else
            ..._buildGroupedSections(filtered, l10n),
        ],
      ),
    );
  }

  List<Widget> _buildGroupedSections(
    List<MangaShareDto> items,
    AppLocalizations l10n,
  ) {
    final groups = _InboxGrouping.group(items);
    final widgets = <Widget>[];
    for (var i = 0; i < groups.length; i++) {
      final group = groups[i];
      widgets.add(
        ProfileEditSection(
          label: _labelFor(group.bucket, l10n),
          children: [
            for (final share in group.items)
              InboxShareTile(share: share, onTap: () => _openShare(share)),
          ],
        ),
      );
      if (i < groups.length - 1) {
        widgets.add(const SizedBox(height: 22));
      }
    }
    return widgets;
  }

  String _labelFor(_InboxBucket bucket, AppLocalizations l10n) {
    switch (bucket) {
      case _InboxBucket.today:
        return l10n.inboxGroupToday;
      case _InboxBucket.yesterday:
        return l10n.inboxGroupYesterday;
      case _InboxBucket.thisWeek:
        return l10n.inboxGroupThisWeek;
      case _InboxBucket.older:
        return l10n.inboxGroupOlder;
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Empty state (deux variantes : globalement vide / filtre vide).
// ─────────────────────────────────────────────────────────────────────────────

class _InboxEmpty extends StatelessWidget {
  final AppLocalizations l10n;
  final InboxFilter filter;
  final bool isFiltered;
  const _InboxEmpty({
    required this.l10n,
    required this.filter,
    required this.isFiltered,
  });

  @override
  Widget build(BuildContext context) {
    if (isFiltered) {
      final msg = filter == InboxFilter.unread
          ? l10n.inboxEmptyFilteredUnread
          : l10n.inboxEmptyFilteredRead;
      return AppEmptyState(
        icon: Icons.inbox_outlined,
        title: msg,
      );
    }
    return AppEmptyState(
      icon: Icons.inbox_outlined,
      title: l10n.inboxEmptyTitle,
      subtitle: l10n.inboxEmptySubtitle,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Grouping logic — par bucket date relatif à `DateTime.now()`.
// ─────────────────────────────────────────────────────────────────────────────

enum _InboxBucket { today, yesterday, thisWeek, older }

class _InboxGrouping {
  final _InboxBucket bucket;
  final List<MangaShareDto> items;
  const _InboxGrouping(this.bucket, this.items);

  static List<_InboxGrouping> group(List<MangaShareDto> items) {
    final now = DateTime.now();
    final startOfToday = DateTime(now.year, now.month, now.day);
    final startOfYesterday = startOfToday.subtract(const Duration(days: 1));
    final startOfWeek = startOfToday.subtract(const Duration(days: 7));

    final buckets = <_InboxBucket, List<MangaShareDto>>{
      _InboxBucket.today: [],
      _InboxBucket.yesterday: [],
      _InboxBucket.thisWeek: [],
      _InboxBucket.older: [],
    };

    for (final share in items) {
      final local = share.createdAt.toLocal();
      if (!local.isBefore(startOfToday)) {
        buckets[_InboxBucket.today]!.add(share);
      } else if (!local.isBefore(startOfYesterday)) {
        buckets[_InboxBucket.yesterday]!.add(share);
      } else if (!local.isBefore(startOfWeek)) {
        buckets[_InboxBucket.thisWeek]!.add(share);
      } else {
        buckets[_InboxBucket.older]!.add(share);
      }
    }

    // Conserve l'ordre des buckets non-vides.
    return [
      for (final entry in buckets.entries)
        if (entry.value.isNotEmpty) _InboxGrouping(entry.key, entry.value),
    ];
  }
}
