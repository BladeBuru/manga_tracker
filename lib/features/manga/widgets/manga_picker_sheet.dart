import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mangatracker/core/components/refreshable_manga_image.dart';
import 'package:mangatracker/core/theme/app_radius.dart';
import 'package:mangatracker/core/theme/app_spacing.dart';
import 'package:mangatracker/features/manga/bloc/manga_picker_cubit.dart';
import 'package:mangatracker/features/manga/dto/manga_quick_view.dto.dart';
import 'package:mangatracker/l10n/app_localizations.dart';
import 'package:mangatracker/core/router/app_modals.dart';

/// Ouvre la recherche d'une œuvre à recommander ; renvoie l'œuvre choisie
/// (ou `null`). [excludeMuId] : l'œuvre source, qui ne peut pas se
/// recommander elle-même.
Future<MangaQuickViewDto?> showMangaPickerSheet(
  BuildContext context, {
  num? excludeMuId,
}) {
  return showAppBottomSheet<MangaQuickViewDto>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Theme.of(context).scaffoldBackgroundColor,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder:
        (ctx) => BlocProvider(
          create: (_) => MangaPickerCubit(),
          child: _MangaPickerBody(excludeMuId: excludeMuId),
        ),
  );
}

class _MangaPickerBody extends StatelessWidget {
  final num? excludeMuId;

  const _MangaPickerBody({this.excludeMuId});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final media = MediaQuery.of(context);
    return Padding(
      padding: EdgeInsets.only(bottom: media.viewInsets.bottom),
      child: SafeArea(
        child: SizedBox(
          height: media.size.height * 0.75,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.m,
                  AppSpacing.m,
                  AppSpacing.m,
                  AppSpacing.s,
                ),
                child: Text(
                  l10n.communityRecoPickerTitle,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.m),
                child: TextField(
                  autofocus: true,
                  textInputAction: TextInputAction.search,
                  onChanged: context.read<MangaPickerCubit>().queryChanged,
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.search_outlined),
                    hintText: l10n.communityRecoPickerHint,
                    border: OutlineInputBorder(
                      borderRadius: AppRadius.circularXl,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.s),
              Expanded(child: _PickerResults(excludeMuId: excludeMuId)),
            ],
          ),
        ),
      ),
    );
  }
}

class _PickerResults extends StatelessWidget {
  final num? excludeMuId;

  const _PickerResults({this.excludeMuId});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return BlocBuilder<MangaPickerCubit, MangaPickerState>(
      builder: (context, state) {
        if (state.loading) {
          return const Center(child: CircularProgressIndicator());
        }
        if (state.failed) {
          return Center(child: Text(l10n.searchLoadFailed));
        }
        final results =
            state.results.where((m) => m.muId != excludeMuId).toList();
        if (state.query.isNotEmpty && results.isEmpty) {
          return Center(child: Text(l10n.communityRecoPickerEmpty));
        }
        return ListView.builder(
          itemCount: results.length,
          itemBuilder: (context, index) {
            final manga = results[index];
            return ListTile(
              key: ValueKey(manga.muId),
              leading: ClipRRect(
                borderRadius: AppRadius.circularSm,
                child: RefreshableMangaImage(
                  muId: manga.muId.toString(),
                  originalUrl: manga.mediumCoverUrl,
                  width: 40,
                  height: 56,
                  useProxy: true,
                ),
              ),
              title: Text(
                manga.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              subtitle: manga.year.isEmpty ? null : Text(manga.year),
              onTap: () => Navigator.of(context).pop(manga),
            );
          },
        );
      },
    );
  }
}
