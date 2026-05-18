import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:mangatracker/core/components/app_count_badge.dart';
import 'package:mangatracker/core/components/app_empty_state.dart';
import 'package:mangatracker/core/components/app_error_state.dart';
import 'package:mangatracker/core/service_locator/service_locator.dart';
import 'package:mangatracker/core/theme/app_colors.dart';
import 'package:mangatracker/core/theme/app_spacing.dart';
import 'package:mangatracker/core/utils/responsive_layout.dart';
import 'package:mangatracker/features/profile/services/user.service.dart';
import 'package:mangatracker/features/sharing/bloc/reading_groups_bloc.dart';
import 'package:mangatracker/features/sharing/dto/reading_group.dto.dart';
import 'package:mangatracker/features/sharing/widgets/reading_group_list_row.dart';
import 'package:mangatracker/l10n/app_localizations.dart';

/// Page liste « Lectures à deux » — Design System V1 « Refined Classic ».
///
/// Source : `.claude-design/manga-tracker/project/profile-v1.jsx` + `screen-account.jsx`.
///
/// Structure :
///  - AppBar : titre center, hairline en bas, fond off-white.
///  - Header de section "Mes groupes" + count badge à droite.
///  - Card V1 (radius 16 + hairline + shadow ultra-subtil), un row par
///    groupe (avatars superposés, manga, "Avec X", progression mono),
///    divider hairline entre les rows.
///  - Empty state pastel (icône groupes) + CTA "Découvrir un manga".
class ReadingGroupsListPage extends StatelessWidget with ResponsiveLayoutMixin {
  const ReadingGroupsListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<ReadingGroupsBloc>(
      create: (_) => ReadingGroupsBloc()..add(const LoadReadingGroups()),
      child: const _ReadingGroupsScaffold(),
    );
  }
}

class _ReadingGroupsScaffold extends StatelessWidget
    with ResponsiveLayoutMixin {
  const _ReadingGroupsScaffold();

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final scheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;
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
          l10n.readingGroupsTitle,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: scheme.onSurface,
          ),
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxContentWidth(context)),
          child: BlocBuilder<ReadingGroupsBloc, ReadingGroupsState>(
            builder: (context, state) {
              if (state is ReadingGroupsLoading ||
                  state is ReadingGroupsInitial) {
                return const Center(child: CircularProgressIndicator());
              }
              if (state is ReadingGroupsError) {
                return AppErrorState(
                  message: state.message,
                  retryLabel: l10n.retry,
                  onRetry: () => context
                      .read<ReadingGroupsBloc>()
                      .add(const LoadReadingGroups()),
                );
              }
              if (state is ReadingGroupsLoaded) {
                if (state.groups.isEmpty) {
                  return _EmptyView(onAction: () => context.go('/'));
                }
                return _GroupsListBody(groups: state.groups);
              }
              return const SizedBox.shrink();
            },
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Body : header "Mes groupes" + section card V1 avec dividers hairline.
// ─────────────────────────────────────────────────────────────────────────────

class _GroupsListBody extends StatefulWidget {
  final List<ReadingGroupDto> groups;
  const _GroupsListBody({required this.groups});

  @override
  State<_GroupsListBody> createState() => _GroupsListBodyState();
}

class _GroupsListBodyState extends State<_GroupsListBody>
    with ResponsiveLayoutMixin {
  // On charge l'id user une seule fois (UserService a un cache 7j, donc
  // pas coûteux). Sert à identifier "moi" parmi les membres pour chaque row.
  late final Future<int?> _currentUserId = _loadCurrentUserId();

  Future<int?> _loadCurrentUserId() async {
    try {
      final info = await getIt<UserService>().getUserInformation();
      return info.id;
    } catch (_) {
      return null;
    }
  }

  Future<void> _openDetail(BuildContext context, ReadingGroupDto group) async {
    final bloc = context.read<ReadingGroupsBloc>();
    final wasDeleted =
        await context.push<bool>('/reading-groups/${group.id}');
    if (wasDeleted == true) {
      bloc.add(const LoadReadingGroups());
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final hPad = horizontalPadding(context);

    return FutureBuilder<int?>(
      future: _currentUserId,
      builder: (context, snap) {
        final myId = snap.data;
        return RefreshIndicator(
          onRefresh: () async => context
              .read<ReadingGroupsBloc>()
              .add(const LoadReadingGroups()),
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.fromLTRB(hPad, AppSpacing.m, hPad, AppSpacing.l),
            children: [
              _SectionHeader(
                label: l10n.readingGroupListSectionTitle,
                count: widget.groups.length,
              ),
              Container(
                decoration: _cardDecoration(context),
                clipBehavior: Clip.antiAlias,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (int i = 0; i < widget.groups.length; i++) ...[
                      ReadingGroupListRow(
                        group: widget.groups[i],
                        currentUserId: myId,
                        onTap: () => _openDetail(context, widget.groups[i]),
                      ),
                      if (i < widget.groups.length - 1) const _RowHairline(),
                    ],
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  BoxDecoration _cardDecoration(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final isDark = brightness == Brightness.dark;
    return BoxDecoration(
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
    );
  }
}

class _RowHairline extends StatelessWidget {
  const _RowHairline();

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    // Indent left=72 pour aligner sous le texte (avatar 40 + spacing 14 + 16 padding).
    return Padding(
      padding: const EdgeInsets.only(left: 70),
      child: Container(
        height: 1,
        color: AppColors.dsHairline(brightness),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String label;
  final int count;

  const _SectionHeader({required this.label, required this.count});

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    return Padding(
      padding: const EdgeInsets.only(left: 4, right: 4, bottom: 10),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label.toUpperCase(),
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.88,
                color: AppColors.dsText2(brightness),
              ),
            ),
          ),
          AppCountBadge(count: count),
        ],
      ),
    );
  }
}

class _EmptyView extends StatelessWidget {
  final VoidCallback onAction;
  const _EmptyView({required this.onAction});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AppEmptyState(
      icon: Icons.groups_outlined,
      title: l10n.readingGroupEmptyTitle,
      subtitle: l10n.readingGroupEmptySubtitle,
      actionLabel: l10n.readingGroupEmptyAction,
      onAction: onAction,
    );
  }
}
