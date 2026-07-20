import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mangatracker/core/notifier/notifier.dart';
import 'package:mangatracker/core/service_locator/service_locator.dart';
import 'package:mangatracker/core/services/connectivity_service.dart';
import 'package:mangatracker/core/theme/app_spacing.dart';
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
  final int currentTotal;
  final int readChapters;

  const ReportChaptersDialog({
    super.key,
    required this.bloc,
    required this.muId,
    required this.currentTotal,
    required this.readChapters,
  });

  /// Borne haute serveur : total actuel + 200.
  static const int maxReportDelta = 200;

  /// Ouvre le dialog depuis le CTA du bloc chapitres (le `context` doit être
  /// sous le `BlocProvider<DetailBloc>` de la page détail).
  static Future<void> show(
    BuildContext context, {
    required int muId,
    required int currentTotal,
    required int readChapters,
  }) {
    final bloc = context.read<DetailBloc>();
    return showDialog<void>(
      context: context,
      builder: (_) => ReportChaptersDialog(
        bloc: bloc,
        muId: muId,
        currentTotal: currentTotal,
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
  bool _hasError = false;

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
    if (parsed == null || parsed <= widget.currentTotal) {
      return l10n.reportMoreChaptersInvalidLow(widget.currentTotal);
    }
    if (parsed > widget.currentTotal + ReportChaptersDialog.maxReportDelta) {
      return l10n.reportMoreChaptersInvalidHigh(
        widget.currentTotal + ReportChaptersDialog.maxReportDelta,
      );
    }
    return null;
  }

  void _submit(AppLocalizations l10n) {
    if (_isSubmitting || !(_formKey.currentState?.validate() ?? false)) return;
    setState(() {
      _isSubmitting = true;
      _hasError = false;
    });
    widget.bloc.add(ReportMoreChapters(
      widget.muId,
      int.parse(_controller.text.trim()),
      onResult: (success) => _onResult(success, l10n),
    ));
  }

  void _onResult(bool success, AppLocalizations l10n) {
    if (!mounted) return;
    if (success) {
      Navigator.of(context).pop();
      getIt<Notifier>().success(l10n.reportMoreChaptersSuccess);
    } else {
      setState(() {
        _isSubmitting = false;
        _hasError = true;
      });
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
            if (offline || _hasError) ...[
              const SizedBox(height: AppSpacing.s),
              Text(
                offline
                    ? l10n.reportMoreChaptersOffline
                    : l10n.reportMoreChaptersError,
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
