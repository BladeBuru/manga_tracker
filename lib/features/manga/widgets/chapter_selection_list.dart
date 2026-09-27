import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mangatracker/core/components/app_chip.dart';
import 'package:mangatracker/core/theme/app_spacing.dart';
import 'package:mangatracker/features/manga/utils/chapter_range_selection.dart';
import 'package:mangatracker/l10n/app_localizations.dart';

/// Liste des chapitres à télécharger.
///
/// - Ouverte sur le premier chapitre NON LU (un chapitre lu reste visible
///   au-dessus pour se situer) : plus besoin de descendre depuis le 1.
/// - Chapitres lus signalés (« Lu »), chapitres déjà téléchargés marqués et
///   non sélectionnables.
/// - Appui : coche / décoche un chapitre.
/// - Appui long : coche tout l'intervalle depuis le dernier chapitre coché.
/// - Appui long puis glisser : coche en continu, avec défilement automatique
///   près des bords.
class ChapterSelectionList extends StatefulWidget {
  const ChapterSelectionList({
    super.key,
    required this.totalChapters,
    required this.readChapters,
    required this.downloaded,
    required this.selected,
    required this.onSelectionChanged,
    required this.onAnchor,
  });

  final int totalChapters;
  final int? readChapters;
  final Set<int> downloaded;
  final Set<int> selected;
  final ValueChanged<Set<int>> onSelectionChanged;

  /// Chapitre coché le plus récemment (bouton « intervalle » du parent).
  final ValueChanged<int> onAnchor;

  /// Hauteur fixe d'une ligne : permet d'ouvrir sur un chapitre précis et de
  /// savoir quelle ligne est sous le doigt pendant le glisser.
  static const double itemExtent = 56;

  @override
  State<ChapterSelectionList> createState() => _ChapterSelectionListState();
}

class _ChapterSelectionListState extends State<ChapterSelectionList> {
  static const double _edge = 48;
  static const double _autoScrollStep = 12;

  late final ScrollController _scroll;
  double _viewportHeight = 0;
  int? _anchor;

  int? _dragStart;
  Set<int> _dragBase = const {};
  bool _dragMoved = false;
  double _dragDy = 0;
  Timer? _autoScroll;
  double _autoScrollDirection = 0;

  @override
  void initState() {
    super.initState();
    final first = ChapterRangeSelection.firstUnread(
      readChapters: widget.readChapters,
      total: widget.totalChapters,
    );
    final topIndex = (first - 2).clamp(0, widget.totalChapters);
    _scroll = ScrollController(
      initialScrollOffset: topIndex * ChapterSelectionList.itemExtent,
    );
  }

  @override
  void dispose() {
    _autoScroll?.cancel();
    _scroll.dispose();
    super.dispose();
  }

  int _chapterAt(double dy) => ChapterRangeSelection.chapterAt(
        dy: dy,
        scrollOffset: _scroll.hasClients ? _scroll.offset : 0,
        itemExtent: ChapterSelectionList.itemExtent,
        itemCount: widget.totalChapters,
      );

  void _setAnchor(int chapter) {
    _anchor = chapter;
    widget.onAnchor(chapter);
  }

  void _toggle(int chapter) {
    if (widget.downloaded.contains(chapter)) return;
    final next = {...widget.selected};
    if (!next.remove(chapter)) {
      next.add(chapter);
      _setAnchor(chapter);
    }
    widget.onSelectionChanged(next);
  }

  void _onLongPressStart(LongPressStartDetails details) {
    _dragStart = _chapterAt(details.localPosition.dy);
    _dragBase = {...widget.selected};
    _dragMoved = false;
    _dragDy = details.localPosition.dy;
    HapticFeedback.selectionClick();
  }

  void _onLongPressMove(LongPressMoveUpdateDetails details) {
    _dragDy = details.localPosition.dy;
    _extendDrag();
    _updateAutoScroll();
  }

  void _extendDrag() {
    final start = _dragStart;
    if (start == null) return;
    final current = _chapterAt(_dragDy);
    if (current != start) _dragMoved = true;
    if (!_dragMoved) return;
    widget.onSelectionChanged(_dragBase.union(ChapterRangeSelection.range(
      start,
      current,
      excluded: widget.downloaded,
    )));
  }

  void _onLongPressEnd(LongPressEndDetails details) {
    _stopAutoScroll();
    final start = _dragStart;
    _dragStart = null;
    if (start == null) return;
    if (_dragMoved) {
      _setAnchor(_chapterAt(details.localPosition.dy));
      return;
    }
    // Appui long sans glisser : tout l'intervalle depuis le dernier coché.
    final anchor = _anchor;
    if (anchor != null && anchor != start && widget.selected.contains(anchor)) {
      widget.onSelectionChanged(_dragBase.union(ChapterRangeSelection.range(
        anchor,
        start,
        excluded: widget.downloaded,
      )));
    } else if (!widget.downloaded.contains(start)) {
      widget.onSelectionChanged({..._dragBase, start});
    }
    _setAnchor(start);
  }

  void _updateAutoScroll() {
    if (_dragDy < _edge) {
      _autoScrollDirection = -1;
    } else if (_dragDy > _viewportHeight - _edge) {
      _autoScrollDirection = 1;
    } else {
      _stopAutoScroll();
      return;
    }
    _autoScroll ??= Timer.periodic(const Duration(milliseconds: 16), (_) {
      if (!_scroll.hasClients) return;
      final position = _scroll.position;
      final target = (position.pixels + _autoScrollDirection * _autoScrollStep)
          .clamp(position.minScrollExtent, position.maxScrollExtent);
      if (target == position.pixels) return;
      _scroll.jumpTo(target);
      _extendDrag();
    });
  }

  void _stopAutoScroll() {
    _autoScroll?.cancel();
    _autoScroll = null;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        _viewportHeight = constraints.maxHeight;
        return GestureDetector(
          onLongPressStart: _onLongPressStart,
          onLongPressMoveUpdate: _onLongPressMove,
          onLongPressEnd: _onLongPressEnd,
          onLongPressCancel: _stopAutoScroll,
          child: ListView.builder(
            controller: _scroll,
            itemExtent: ChapterSelectionList.itemExtent,
            itemCount: widget.totalChapters,
            itemBuilder: (context, index) {
              final chapter = index + 1;
              return _ChapterRow(
                chapter: chapter,
                isRead: chapter <= (widget.readChapters ?? 0),
                isDownloaded: widget.downloaded.contains(chapter),
                isSelected: widget.selected.contains(chapter),
                onTap: () => _toggle(chapter),
              );
            },
          ),
        );
      },
    );
  }
}

class _ChapterRow extends StatelessWidget {
  const _ChapterRow({
    required this.chapter,
    required this.isRead,
    required this.isDownloaded,
    required this.isSelected,
    required this.onTap,
  });

  final int chapter;
  final bool isRead;
  final bool isDownloaded;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return InkWell(
      onTap: isDownloaded ? null : onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
        child: Row(
          children: [
            Checkbox(
              value: isSelected,
              onChanged: isDownloaded ? null : (_) => onTap(),
            ),
            Expanded(
              child: Text(
                '${l10n?.chapter ?? 'Chapitre'} $chapter',
                style: isRead
                    ? theme.textTheme.bodyMedium
                        ?.copyWith(color: scheme.onSurfaceVariant)
                    : theme.textTheme.bodyLarge,
              ),
            ),
            if (isRead)
              AppChip.outlined(
                label: l10n?.chapterReadBadge ?? 'Lu',
                icon: Icons.visibility_outlined,
              ),
            if (isDownloaded)
              Padding(
                padding: const EdgeInsets.only(left: AppSpacing.s),
                child: Icon(
                  Icons.offline_pin_outlined,
                  color: scheme.primary,
                  semanticLabel:
                      l10n?.chapterAlreadyDownloaded ?? 'Déjà téléchargé',
                ),
              ),
          ],
        ),
      ),
    );
  }
}
