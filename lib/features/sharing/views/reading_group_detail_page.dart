import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:mangatracker/core/components/app_error_state.dart';
import 'package:mangatracker/core/router/route_visibility_listener.dart';
import 'package:mangatracker/core/theme/app_colors.dart';
import 'package:mangatracker/core/theme/app_spacing.dart';
import 'package:mangatracker/core/utils/responsive_layout.dart';
import 'package:mangatracker/features/library/widgets/chapter_progress_feedback.dart';
import 'package:mangatracker/features/sharing/bloc/reading_groups_bloc.dart';
import 'package:mangatracker/features/sharing/dto/reading_group.dto.dart';
import 'package:mangatracker/features/sharing/widgets/reading_group_detail_sections.dart';
import 'package:mangatracker/features/sharing/widgets/reading_group_hero_card.dart';
import 'package:mangatracker/l10n/app_localizations.dart';

/// Page détail « Lectures à deux » — Design System V1 « Refined Classic ».
///
/// Source : `.claude-design/manga-tracker/project/profile-v1.jsx`.
///
/// Structure :
///  - AppBar : titre center, hairline en bas, fond off-white.
///  - Hero V1 (card blanche radius 16 + hairline) : titre manga centré +
///    "you vs friend" côte à côte avec mini progress bars relatives.
///  - Section "Progression" (ProfileEditSection) : row par membre avec
///    progress bar fine.
///  - Section "Actions" (ProfileEditSection) : rows pastel tile (Ma
///    progression — fenêtre de saisie —, Ouvrir le manga, liens, Inviter,
///    Quitter ou Supprimer pour l'owner).
///
/// Polling 30s (ReadingGroupDetailBloc) préservé, mais seulement tant que la
/// page est affichée ; relecture immédiate quand elle repasse au premier
/// plan (retour depuis la fiche du manga).
/// Confirmation dialog pour quitter / supprimer préservée.
class ReadingGroupDetailPage extends StatelessWidget
    with ResponsiveLayoutMixin {
  final int groupId;
  const ReadingGroupDetailPage({super.key, required this.groupId});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<ReadingGroupDetailBloc>(
      create: (_) =>
          ReadingGroupDetailBloc(groupId)..add(const LoadGroupDetail()),
      child: Builder(
        builder: (context) => RouteVisibilityListener(
          onVisible: () => context
              .read<ReadingGroupDetailBloc>()
              .add(const GroupDetailVisibilityChanged(true)),
          onHidden: () => context
              .read<ReadingGroupDetailBloc>()
              .add(const GroupDetailVisibilityChanged(false)),
          child: const _DetailScaffold(),
        ),
      ),
    );
  }
}

class _DetailScaffold extends StatelessWidget with ResponsiveLayoutMixin {
  const _DetailScaffold();

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final scheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;
    final bg = brightness == Brightness.dark
        ? AppColors.dsBgDark
        : AppColors.dsBgLight;

    return BlocConsumer<ReadingGroupDetailBloc, ReadingGroupDetailState>(
      listener: _listen,
      builder: (context, state) {
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
              l10n.readingGroupDetailTitle,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: scheme.onSurface,
              ),
            ),
          ),
          body: _buildBody(context, state, l10n),
        );
      },
    );
  }

  void _listen(BuildContext context, ReadingGroupDetailState state) {
    final l10n = AppLocalizations.of(context)!;
    if (state is ReadingGroupProgressUpdated) {
      _showProgressOutcome(context, state);
      return;
    }
    if (state is ReadingGroupDetailDeleted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.readingGroupDeleteSuccess)),
      );
      // Signale au caller (la liste) que le groupe a été supprimé pour qu'elle
      // recharge. Sans ça, le cache BLoC liste affiche encore l'ancien groupe.
      if (context.canPop()) {
        context.pop(true);
      } else {
        context.go('/reading-groups');
      }
    }
    if (state is ReadingGroupDetailDeleteFailed) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${l10n.readingGroupDeleteFailed}: ${state.message}',
          ),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  /// Issue de « Ma progression » : succès, ou la raison exacte du refus
  /// (avant : aucun retour, l'ancienne valeur restait affichée).
  void _showProgressOutcome(
    BuildContext context,
    ReadingGroupProgressUpdated state,
  ) {
    final bloc = context.read<ReadingGroupDetailBloc>();
    final router = GoRouter.of(context);
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        chapterProgressSnackBar(
          context,
          state.result,
          state.readChapters,
          onRetry: () {
            if (!bloc.isClosed) {
              bloc.add(UpdateMyGroupProgress(state.readChapters));
            }
          },
          onReconnect: () => router.push('/login'),
        ),
      );
  }

  Widget _buildBody(
    BuildContext context,
    ReadingGroupDetailState state,
    AppLocalizations l10n,
  ) {
    if (state is ReadingGroupDetailLoading ||
        state is ReadingGroupDetailInitial) {
      return const Center(child: CircularProgressIndicator());
    }
    if (state is ReadingGroupDetailError) {
      return AppErrorState(
        message: state.message,
        retryLabel: l10n.retry,
        onRetry: () => context
            .read<ReadingGroupDetailBloc>()
            .add(const LoadGroupDetail()),
      );
    }
    if (state is ReadingGroupDetailLoaded) {
      return _GroupView(
        group: state.group,
        isSavingProgress: state.isSavingProgress,
      );
    }
    if (state is ReadingGroupDetailDeleteFailed) {
      return _GroupView(group: state.group);
    }
    return const SizedBox.shrink();
  }
}

class _GroupView extends StatelessWidget with ResponsiveLayoutMixin {
  final ReadingGroupDto group;
  final bool isSavingProgress;
  _GroupView({required this.group, this.isSavingProgress = false});

  @override
  Widget build(BuildContext context) {
    final hPad = horizontalPadding(context);
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxContentWidth(context)),
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(hPad, AppSpacing.m, hPad, AppSpacing.xl),
          child: ReadingGroupCurrentUserScope(
            builder: (context, myId) => Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ReadingGroupHeroCard(group: group, currentUserId: myId),
                const SizedBox(height: AppSpacing.l),
                ReadingGroupProgressSection(
                  group: group,
                  currentUserId: myId,
                ),
                const SizedBox(height: AppSpacing.l),
                ReadingGroupActionsSection(
                  group: group,
                  currentUserId: myId,
                  isSavingProgress: isSavingProgress,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
