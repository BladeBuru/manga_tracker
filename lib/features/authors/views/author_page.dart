import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:mangatracker/core/components/app_empty_state.dart';
import 'package:mangatracker/core/components/app_error_state.dart';
import 'package:mangatracker/core/components/data_source_credit.dart';
import 'package:mangatracker/core/components/offline_banner.dart';
import 'package:mangatracker/core/theme/app_breakpoints.dart';
import 'package:mangatracker/core/theme/app_colors.dart';
import 'package:mangatracker/core/theme/app_spacing.dart';
import 'package:mangatracker/features/authors/bloc/author_cubit.dart';
import 'package:mangatracker/features/authors/widgets/author_header.dart';
import 'package:mangatracker/features/authors/widgets/author_works_grid.dart';
import 'package:mangatracker/features/home/helpers/home_layout_metrics.dart';
import 'package:mangatracker/l10n/app_localizations.dart';

/// Page d'un auteur / dessinateur (`/authors/:authorId`) : mini bio et
/// ensemble de ses œuvres. Ouverte depuis les noms cliquables de la fiche
/// manga ; [initialName] s'affiche dans la barre avant la réponse.
class AuthorPage extends StatelessWidget {
  final int authorId;
  final String? initialName;

  /// Injectable pour les tests.
  final AuthorCubit? cubit;

  const AuthorPage({
    super.key,
    required this.authorId,
    this.initialName,
    this.cubit,
  });

  @override
  Widget build(BuildContext context) {
    final provided = cubit;
    final child = _AuthorScaffold(initialName: initialName);
    if (provided != null) {
      return BlocProvider.value(value: provided..load(), child: child);
    }
    return BlocProvider(
      create: (_) => AuthorCubit(authorId: authorId)..load(),
      child: child,
    );
  }
}

class _AuthorScaffold extends StatelessWidget {
  final String? initialName;

  const _AuthorScaffold({this.initialName});

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    return BlocBuilder<AuthorCubit, AuthorState>(
      builder: (context, state) {
        final name = state is AuthorLoaded ? state.author.name : initialName;
        return Scaffold(
          backgroundColor:
              brightness == Brightness.dark
                  ? AppColors.dsBgDark
                  : AppColors.dsBgLight,
          appBar: AppBar(title: Text(name ?? '')),
          body: LayoutBuilder(
            builder:
                (context, constraints) => RefreshIndicator(
                  onRefresh: () => context.read<AuthorCubit>().load(),
                  child: AppContentWidth(
                    child: CustomScrollView(
                      slivers: _slivers(context, state, constraints.maxWidth),
                    ),
                  ),
                ),
          ),
        );
      },
    );
  }

  List<Widget> _slivers(BuildContext context, AuthorState state, double width) {
    final l10n = AppLocalizations.of(context)!;
    switch (state) {
      case AuthorLoading():
        return const [
          SliverFillRemaining(
            hasScrollBody: false,
            child: Center(child: CircularProgressIndicator()),
          ),
        ];
      case AuthorError(:final notFound, :final isOffline):
        return [
          SliverFillRemaining(
            hasScrollBody: false,
            child:
                notFound
                    ? AppEmptyState(
                      icon: Icons.person_search_outlined,
                      title: l10n.authorNotFound,
                      actionLabel: l10n.back,
                      onAction: () => context.pop(),
                    )
                    : AppErrorState(
                      message:
                          isOffline ? l10n.networkError : l10n.authorLoadError,
                      retryLabel: l10n.retry,
                      onRetry: () => context.read<AuthorCubit>().load(),
                    ),
          ),
        ];
      case AuthorLoaded(:final author, :final isOffline):
        final metrics = HomeLayoutMetrics.of(width);
        final hPad = metrics.horizontalPadding;
        return [
          SliverPadding(
            padding: EdgeInsets.fromLTRB(hPad, AppSpacing.m, hPad, 0),
            sliver: SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (isOffline) const OfflineBanner(),
                  AuthorHeader(author: author),
                  const SizedBox(height: AppSpacing.l),
                  Text(
                    l10n.authorWorksTitle(author.works.length),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  if (!author.worksComplete)
                    Padding(
                      padding: const EdgeInsets.only(top: AppSpacing.xs),
                      child: Text(
                        l10n.authorWorksIncomplete,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                  const SizedBox(height: AppSpacing.m),
                ],
              ),
            ),
          ),
          if (author.works.isEmpty)
            SliverToBoxAdapter(
              child: AppEmptyState(
                icon: Icons.auto_stories_outlined,
                title: l10n.authorNoWorks,
              ),
            )
          else
            AuthorWorksGrid(
              works: author.works,
              metrics: metrics,
              availableWidth: width,
            ),
          const SliverToBoxAdapter(child: DataSourceCredit()),
          const SliverPadding(padding: EdgeInsets.only(bottom: AppSpacing.l)),
        ];
    }
  }
}
