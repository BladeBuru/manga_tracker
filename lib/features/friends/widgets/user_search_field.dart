import 'dart:async';

import 'package:flutter/material.dart';
import 'package:mangatracker/core/components/app_avatar.dart';
import 'package:mangatracker/core/theme/app_colors.dart';
import 'package:mangatracker/features/friends/dto/friend.dto.dart';
import 'package:mangatracker/l10n/app_localizations.dart';

/// Champ de recherche d'utilisateur — design V1 « Refined Classic ».
///
/// Pill input :
///  - container surface (blanc / surface dark) ; radius 14 ; padding 12/14
///  - border 1.5px (`primary` si query non vide, sinon `hairline`)
///  - icône person_search_outlined gauche, clear × droit quand query non vide
///
/// Debounce 300 ms — préserve l'ancien comportement. Les résultats s'affichent
/// dans une carte V1 indépendante en-dessous (radius 16, hairline border).
class UserSearchField extends StatefulWidget {
  final List<UserSearchResultDto> results;
  final ValueChanged<String> onQueryChanged;
  final ValueChanged<int> onSendRequest;

  const UserSearchField({
    super.key,
    required this.results,
    required this.onQueryChanged,
    required this.onSendRequest,
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

  void _onResultTap(UserSearchResultDto user) {
    widget.onSendRequest(user.id);
    _clear();
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
          _SearchResultsCard(
            results: widget.results,
            onTap: _onResultTap,
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

class _SearchResultsCard extends StatelessWidget {
  final List<UserSearchResultDto> results;
  final ValueChanged<UserSearchResultDto> onTap;

  const _SearchResultsCard({required this.results, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final isDark = brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context)!;
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.dsSurfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.dsHairline(brightness),
          width: 1,
        ),
        boxShadow: isDark
            ? null
            : const [
                BoxShadow(
                  color: Color(0x0A140A0A),
                  blurRadius: 2,
                  offset: Offset(0, 1),
                ),
              ],
      ),
      clipBehavior: Clip.antiAlias,
      child: results.isEmpty
          ? Padding(
              padding: const EdgeInsets.symmetric(
                vertical: 22,
                horizontal: 16,
              ),
              child: Text(
                l10n.friendsSearchEmpty,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.dsText3(brightness),
                  fontWeight: FontWeight.w500,
                ),
              ),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (int i = 0; i < results.length; i++) ...[
                  _SearchResultRow(
                    user: results[i],
                    onTap: () => onTap(results[i]),
                  ),
                  if (i < results.length - 1)
                    Padding(
                      padding: const EdgeInsets.only(left: 58),
                      child: Container(
                        height: 1,
                        color: AppColors.dsHairline(brightness),
                      ),
                    ),
                ],
              ],
            ),
    );
  }
}

class _SearchResultRow extends StatelessWidget {
  final UserSearchResultDto user;
  final VoidCallback onTap;

  const _SearchResultRow({required this.user, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final scheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 10, 10, 10),
        child: Row(
          children: [
            AppAvatar(
              url: user.avatarUrl,
              fallback: user.effectiveDisplayName,
              size: AppAvatarSize.medium,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    user.effectiveDisplayName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w600,
                      letterSpacing: -0.075,
                      color: scheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '@${user.username}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12.5,
                      color: AppColors.dsText2(brightness),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            FilledButton.tonal(
              onPressed: onTap,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.dsRedSoft(brightness),
                foregroundColor: scheme.primary,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                minimumSize: const Size(0, 30),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(999),
                ),
                textStyle: const TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
              child: Text(l10n.friendsAddRequest),
            ),
          ],
        ),
      ),
    );
  }
}
