import 'dart:async';

import 'package:flutter/material.dart';
import 'package:mangatracker/core/theme/app_colors.dart';
import 'package:mangatracker/features/friends/dto/friend.dto.dart';
import 'package:mangatracker/features/friends/widgets/user_search_results.dart';
import 'package:mangatracker/l10n/app_localizations.dart';

/// Champ de recherche d'utilisateur — design V1 « Refined Classic ».
///
/// Pill input :
///  - container surface (blanc / surface dark) ; radius 14 ; padding 12/14
///  - border 1.5px (`primary` si query non vide, sinon `hairline`)
///  - icône person_search_outlined gauche, clear × droit quand query non vide
///
/// Debounce 300 ms. Les résultats ([UserSearchResultsCard]) s'affichent
/// dessous ; un appui sur l'action d'un résultat ne l'exécute plus
/// directement : la page demande d'abord confirmation, et la recherche reste
/// affichée (le bouton passe à « Demande envoyée »).
class UserSearchField extends StatefulWidget {
  final List<UserSearchResultDto> results;
  final bool loading;
  final Object? error;
  final FriendRelation Function(UserSearchResultDto user) relationOf;
  final ValueChanged<String> onQueryChanged;
  final void Function(UserSearchResultDto user, FriendRelation relation)
      onAction;

  const UserSearchField({
    super.key,
    required this.results,
    required this.relationOf,
    required this.onQueryChanged,
    required this.onAction,
    this.loading = false,
    this.error,
  });

  @override
  State<UserSearchField> createState() => _UserSearchFieldState();
}

class _UserSearchFieldState extends State<UserSearchField> {
  final TextEditingController _ctrl = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  Timer? _debounce;
  bool _hasQuery = false;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _ctrl.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    final hasQuery = value.trim().isNotEmpty;
    if (hasQuery != _hasQuery) {
      setState(() => _hasQuery = hasQuery);
    }
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      widget.onQueryChanged(value);
    });
  }

  void _clear() {
    _debounce?.cancel();
    _ctrl.clear();
    setState(() => _hasQuery = false);
    widget.onQueryChanged('');
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _SearchPill(
          controller: _ctrl,
          focusNode: _focusNode,
          hasQuery: _hasQuery,
          onChanged: _onChanged,
          onClear: _clear,
        ),
        if (_hasQuery) ...[
          const SizedBox(height: 14),
          UserSearchResultsCard(
            results: widget.results,
            loading: widget.loading,
            error: widget.error,
            relationOf: widget.relationOf,
            onAction: widget.onAction,
          ),
        ],
      ],
    );
  }
}

class _SearchPill extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool hasQuery;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  const _SearchPill({
    required this.controller,
    required this.focusNode,
    required this.hasQuery,
    required this.onChanged,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final scheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;
    final isDark = brightness == Brightness.dark;
    final borderColor =
        hasQuery ? scheme.primary : AppColors.dsHairline(brightness);
    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      decoration: BoxDecoration(
        color: isDark ? AppColors.dsSurfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor, width: 1.5),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      child: Row(
        children: [
          Icon(
            Icons.person_search_outlined,
            size: 18,
            color: AppColors.dsText3(brightness),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: controller,
              focusNode: focusNode,
              onChanged: onChanged,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: scheme.onSurface,
              ),
              decoration: InputDecoration(
                isCollapsed: true,
                hintText: l10n.friendsSearchHint,
                hintStyle: TextStyle(
                  color: AppColors.dsText3(brightness),
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                ),
                border: InputBorder.none,
                contentPadding:
                    const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
          if (hasQuery)
            IconButton(
              onPressed: onClear,
              icon: Icon(
                Icons.close,
                size: 16,
                color: AppColors.dsText3(brightness),
              ),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
              tooltip: l10n.friendsSearchClear,
            ),
        ],
      ),
    );
  }
}
