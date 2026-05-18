import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:mangatracker/core/components/app_error_state.dart';
import 'package:mangatracker/core/theme/app_colors.dart';
import 'package:mangatracker/features/stats/bloc/stats_bloc.dart';
import 'package:mangatracker/features/stats/dto/user_stats.dto.dart';
import 'package:mangatracker/features/stats/widgets/stats_genres_section.dart';
import 'package:mangatracker/features/stats/widgets/stats_hero_card.dart';
import 'package:mangatracker/features/stats/widgets/stats_offline_banner.dart';
import 'package:mangatracker/features/stats/widgets/stats_overview_section.dart';
import 'package:mangatracker/features/stats/widgets/stats_status_section.dart';
import 'package:mangatracker/l10n/app_localizations.dart';

/// Page Statistiques — Design System V1 « Refined Classic ».
///
/// Refonte 2026-05-18 : structure groupée en sections card+hairline alignée
/// sur `profile_edit.view.dart`. Lecture seule, pull-to-refresh.
///
/// Sources design :
///  - `.claude-design/manga-tracker/project/screen-account.jsx` (Highlight +
///    Section/Card patterns)
///  - `.claude-design/manga-tracker/project/profile-v1.jsx` (sections groupées)
///  - `.claude-design/manga-tracker/project/tokens.css` (palette ds*)
class StatsView extends StatelessWidget {
  const StatsView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<StatsBloc>(
      create: (_) => StatsBloc()..add(const LoadStats()),
      child: const _StatsScaffold(),
    );
  }
}

class _StatsScaffold extends StatelessWidget {
  const _StatsScaffold();

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
        centerTitle: true,
        shape: Border(
          bottom: BorderSide(
            color: AppColors.dsHairline(brightness),
            width: 1,
          ),
        ),
        title: Text(
          l10n.statsTitle,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: scheme.onSurface,
          ),
        ),
      ),
      body: BlocBuilder<StatsBloc, StatsState>(
        builder: (context, state) {
          if (state is StatsLoading || state is StatsInitial) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is StatsError) {
            return AppErrorState(
              message: state.message,
              retryLabel: l10n.retry,
              onRetry: () =>
                  context.read<StatsBloc>().add(const LoadStats()),
            );
          }
          if (state is StatsLoaded) {
            return RefreshIndicator(
              onRefresh: () async =>
                  context.read<StatsBloc>().add(const RefreshStats()),
              child: _StatsContent(
                stats: state.stats,
                isOffline: state.isOffline,
              ),
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }
}

class _StatsContent extends StatelessWidget {
  final UserStatsDto stats;
  final bool isOffline;
  const _StatsContent({required this.stats, required this.isOffline});

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).toString();
    final dateFmt = DateFormat.yMMMMd(locale);
    final lastReadFormatted =
        stats.lastReadAt != null ? dateFmt.format(stats.lastReadAt!) : null;

    return LayoutBuilder(
      builder: (context, constraints) {
        final hPad = constraints.maxWidth >= 600 ? 32.0 : 16.0;
        return ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.fromLTRB(hPad, 12, hPad, 24),
          children: [
            if (isOffline) ...[
              const Align(
                alignment: Alignment.centerLeft,
                child: StatsOfflineBanner(),
              ),
              const SizedBox(height: 12),
            ],
            StatsHeroCard(
              accountCreatedAt: stats.accountCreatedAt,
              formattedDate: dateFmt.format(stats.accountCreatedAt),
              totalMangas: stats.totalMangas,
            ),
            const SizedBox(height: 22),
            StatsOverviewSection(
              stats: stats,
              lastReadFormatted: lastReadFormatted,
              emptyDash: '—',
            ),
            const SizedBox(height: 22),
            StatsStatusSection(byStatus: stats.mangasByStatus),
            const SizedBox(height: 22),
            StatsGenresSection(topGenres: stats.topGenres),
            const SizedBox(height: 24),
          ],
        );
      },
    );
  }
}
