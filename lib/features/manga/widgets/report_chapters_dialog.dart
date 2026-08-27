import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mangatracker/core/notifier/notifier.dart';
import 'package:mangatracker/core/service_locator/service_locator.dart';
import 'package:mangatracker/core/services/connectivity_service.dart';
import 'package:mangatracker/core/theme/app_spacing.dart';
import 'package:mangatracker/features/library/services/chapter_report.service.dart';
import 'package:mangatracker/features/manga/bloc/detail_bloc.dart';
import 'package:mangatracker/features/manga/bloc/detail_event.dart';
import 'package:mangatracker/l10n/app_localizations.dart';

/// Dialog « Signaler plus de chapitres » (chantier A).
///
/// Pré-rempli avec `readChapters + 1`, validation des bornes serveur
/// (> total actuel et ≤ total + [maxReportDelta]), désactivé hors ligne
/// (pas de queue offline pour ce signalement).
class ReportChaptersDialog extends StatefulWidget {
  final DetailBloc bloc;
  final int muId;

  /// Total EFFECTIF affiché (= `max(officiel, signalement user)`). Sert la
  /// borne BASSE : un nouveau signalement doit dépasser ce qui est déjà connu.
  final int currentTotal;

  /// Total OFFICIEL (MU), avant signalement utilisateur. Sert la borne HAUTE :
  /// le serveur valide contre `officiel + [maxReportDelta]`. `null` → on
  /// retombe sur [currentTotal] (aligné quand aucun report n'est actif).
  final int? officialTotal;
  final int readChapters;

  const ReportChaptersDialog({
    super.key,
    required this.bloc,
    required this.muId,
    required this.currentTotal,
    this.officialTotal,
    required this.readChapters,
  });

  /// Borne haute serveur : total officiel + 200.
  static const int maxReportDelta = 200;

  /// Ouvre le dialog depuis le CTA du bloc chapitres (le `context` doit être
  /// sous le `BlocProvider<DetailBloc>` de la page détail).
  static Future<void> show(
    BuildContext context, {
    required int muId,
    required int currentTotal,
    int? officialTotal,
    required int readChapters,
  }) {
    final bloc = context.read<DetailBloc>();
    return showDialog<void>(
      context: context,
      builder: (_) => ReportChaptersDialog(
        bloc: bloc,
        muId: muId,
        currentTotal: currentTotal,
        officialTotal: officialTotal,
        readChapters: readChapters,
      ),
    );
  }

  @override
  State<ReportChaptersDialog> createState() => _ReportChaptersDialogState();
}

class _ReportChaptersDialogState extends State<ReportChaptersDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _controller;
  bool _isSubmitting = false;

  /// Cause du dernier échec serveur (`null` = pas d'erreur). Mappée vers un
  /// message l10n adapté dans [build].
  ChapterReportFailure? _errorFailure;

  /// Borne haute : le serveur valide contre le total OFFICIEL + delta.
  int get _upperBoundBase => widget.officialTotal ?? widget.currentTotal;

  bool get _isOffline {
    try {
      return !getIt<ConnectivityService>().isConnected;
    } catch (_) {
      return false;
    }
  }

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: '${widget.readChapters + 1}');
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String? _validate(String? value, AppLocalizations l10n) {
    final parsed = int.tryParse((value ?? '').trim());
    // Borne basse : > total effectif affiché (signaler PLUS que le connu).
    if (parsed == null || parsed <= widget.currentTotal) {
      return l10n.reportMoreChaptersInvalidLow(widget.currentTotal);
    }
    // Borne haute alignée sur le serveur : officiel + delta (pas effectif).
    if (parsed > _upperBoundBase + ReportChaptersDialog.maxReportDelta) {
      return l10n.reportMoreChaptersInvalidHigh(
        _upperBoundBase + ReportChaptersDialog.maxReportDelta,
      );
    }
    return null;
  }

  void _submit(AppLocalizations l10n) {
    if (_isSubmitting || !(_formKey.currentState?.validate() ?? false)) return;
    setState(() {
      _isSubmitting = true;
      _errorFailure = null;
    });
    widget.bloc.add(ReportMoreChapters(
      widget.muId,
      int.parse(_controller.text.trim()),
      onResult: (failure) => _onResult(failure, l10n),
    ));
  }

  void _onResult(ChapterReportFailure? failure, AppLocalizations l10n) {
    if (!mounted) return;
    if (failure == null) {
      Navigator.of(context).pop();
      getIt<Notifier>().success(l10n.reportMoreChaptersSuccess);
    } else {
      setState(() {
        _isSubmitting = false;
        _errorFailure = failure;
      });
    }
  }

  /// Mappe une cause d'échec typée vers un message l10n adapté.
  String _errorMessage(ChapterReportFailure failure, AppLocalizations l10n) {
    switch (failure) {
      case ChapterReportFailure.invalidTotal:
        // 400 permanent : le total officiel a bougé côté serveur → recharger.
        return l10n.reportMoreChaptersErrorInvalid;
      case ChapterReportFailure.throttled:
        // 429 temporaire : trop de signalements récents.
        return l10n.reportMoreChaptersErrorThrottled;
      case ChapterReportFailure.notInLibrary:
      case ChapterReportFailure.unknown:
        return l10n.reportMoreChaptersError;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final offline = _isOffline;

    return AlertDialog(
      title: Text(l10n.reportMoreChaptersDialogTitle),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.reportMoreChaptersExplainer,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: AppSpacing.m),
            TextFormField(
              controller: _controller,
              enabled: !offline && !_isSubmitting,
              keyboardType: TextInputType.number,
              autovalidateMode: AutovalidateMode.onUserInteraction,
              decoration: InputDecoration(
                labelText: l10n.reportMoreChaptersInputLabel,
                border: const OutlineInputBorder(),
              ),
              validator: (value) => _validate(value, l10n),
            ),
            if (offline || _errorFailure != null) ...[
              const SizedBox(height: AppSpacing.s),
              Text(
                offline
                    ? l10n.reportMoreChaptersOffline
                    : _errorMessage(_errorFailure!, l10n),
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: scheme.error),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          onPressed: (offline || _isSubmitting) ? null : () => _submit(l10n),
          child: _isSubmitting
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(l10n.reportMoreChaptersSubmit),
        ),
      ],
    );
  }
}
