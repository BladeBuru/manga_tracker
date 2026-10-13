import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mangatracker/core/router/app_modals.dart';
import 'package:mangatracker/core/theme/app_spacing.dart';
import 'package:mangatracker/features/sharing/services/reading_group_progress_choices.dart';
import 'package:mangatracker/l10n/app_localizations.dart';

/// Fenêtre « Ma progression » d'une lecture partagée : le dernier chapitre
/// TERMINÉ, saisi au clavier, ajusté d'un chapitre (−/+) ou aligné sur un
/// membre en avance. Renvoie la valeur choisie, `null` si annulée.
///
/// Remplace l'ancienne action « Marquer ma progression », qui ne faisait
/// qu'ouvrir la fiche du manga.
class ReadingGroupProgressDialog extends StatefulWidget {
  final int initialChapters;
  final List<ReadingGroupProgressTarget> targets;

  const ReadingGroupProgressDialog({
    super.key,
    required this.initialChapters,
    this.targets = const [],
  });

  static Future<int?> show(
    BuildContext context, {
    required int initialChapters,
    List<ReadingGroupProgressTarget> targets = const [],
  }) {
    return showAppDialog<int>(
      context: context,
      builder: (_) => ReadingGroupProgressDialog(
        initialChapters: initialChapters,
        targets: targets,
      ),
    );
  }

  @override
  State<ReadingGroupProgressDialog> createState() =>
      _ReadingGroupProgressDialogState();
}

class _ReadingGroupProgressDialogState
    extends State<ReadingGroupProgressDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _controller = TextEditingController(
    text: '${widget.initialChapters < 0 ? 0 : widget.initialChapters}',
  );

  int? get _value => int.tryParse(_controller.text.trim());

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _set(int chapters) {
    final text = '${chapters < 0 ? 0 : chapters}';
    _controller.value = TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
    setState(() {});
    _formKey.currentState?.validate();
  }

  void _step(int delta) => _set((_value ?? widget.initialChapters) + delta);

  String? _validate(String? value, AppLocalizations l10n) {
    final parsed = int.tryParse((value ?? '').trim());
    return parsed == null || parsed < 0 ? l10n.readingGroupProgressInvalid : null;
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    Navigator.of(context).pop(_value);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final value = _value;
    return AlertDialog(
      scrollable: true,
      title: Text(l10n.readingGroupProgressDialogTitle),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l10n.readingGroupProgressDialogExplainer,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: AppSpacing.m),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                IconButton.filledTonal(
                  tooltip: l10n.readingGroupProgressDecrease,
                  icon: const Icon(Icons.remove_outlined),
                  onPressed: (value ?? 0) > 0 ? () => _step(-1) : null,
                ),
                const SizedBox(width: AppSpacing.s),
                Expanded(
                  child: TextFormField(
                    controller: _controller,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    textAlign: TextAlign.center,
                    autovalidateMode: AutovalidateMode.onUserInteraction,
                    decoration: InputDecoration(
                      labelText: l10n.readingGroupProgressFieldLabel,
                      border: const OutlineInputBorder(),
                      errorMaxLines: 3,
                    ),
                    validator: (v) => _validate(v, l10n),
                    onChanged: (_) => setState(() {}),
                    onFieldSubmitted: (_) => _submit(),
                  ),
                ),
                const SizedBox(width: AppSpacing.s),
                IconButton.filledTonal(
                  tooltip: l10n.readingGroupProgressIncrease,
                  icon: const Icon(Icons.add_outlined),
                  onPressed: () => _step(1),
                ),
              ],
            ),
            if (widget.targets.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.m),
              Wrap(
                spacing: AppSpacing.s,
                runSpacing: AppSpacing.s,
                children: [
                  for (final target in widget.targets)
                    ActionChip(
                      avatar: const Icon(Icons.group_outlined, size: 18),
                      label: Text(
                        l10n.readingGroupProgressAlignWith(
                          target.name,
                          target.chapter,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      onPressed: () => _set(target.chapter),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.cancel),
        ),
        FilledButton(onPressed: _submit, child: Text(l10n.save)),
      ],
    );
  }
}
