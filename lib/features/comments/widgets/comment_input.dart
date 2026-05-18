import 'package:flutter/material.dart';
import 'package:mangatracker/core/theme/app_radius.dart';
import 'package:mangatracker/l10n/app_localizations.dart';

/// Champ d'input pour poster un nouveau commentaire (Phase 7.1).
///
/// Validation : 3-2000 chars (côté serveur aussi).
///
/// **2026-05-18** — le rating optionnel (Slider 1-10) a été retiré pour
/// éviter la duplication avec la rangée "Votre note" en bas de la fiche
/// manga (ces étoiles pilotent `UserManga.rating`, c'est le rating perso
/// légitime). La signature `onSubmit(content, rating)` est conservée pour
/// ne pas casser le BLoC, mais `rating` est toujours `null` à l'envoi.
class CommentInput extends StatefulWidget {
  final void Function(String content, int? rating) onSubmit;
  final String? initialContent;

  /// Conservé pour compat avec les anciens appelants — ignoré côté UI
  /// puisque le sélecteur de rating a été retiré.
  final int? initialRating;
  final String? submitLabel;

  const CommentInput({
    super.key,
    required this.onSubmit,
    this.initialContent,
    this.initialRating,
    this.submitLabel,
  });

  @override
  State<CommentInput> createState() => _CommentInputState();
}

class _CommentInputState extends State<CommentInput> {
  late final TextEditingController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.initialContent ?? '');
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  bool get _isValid {
    final text = _ctrl.text.trim();
    return text.length >= 3 && text.length <= 2000;
  }

  void _submit() {
    if (!_isValid) return;
    widget.onSubmit(_ctrl.text.trim(), null);
    _ctrl.clear();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: _ctrl,
          maxLines: 3,
          maxLength: 2000,
          decoration: InputDecoration(
            hintText: l10n.commentsInputHint,
            border: OutlineInputBorder(borderRadius: AppRadius.circularLg),
            counterText: '',
          ),
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerRight,
          child: FilledButton.icon(
            onPressed: _isValid ? _submit : null,
            icon: const Icon(Icons.send_rounded, size: 18),
            label: Text(widget.submitLabel ?? l10n.commentsPost),
          ),
        ),
      ],
    );
  }
}
