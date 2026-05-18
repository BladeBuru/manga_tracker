import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:mangatracker/core/theme/app_colors.dart';

/// Case à cocher de consentement RGPD V1 — alignée à gauche, avec un
/// libellé cliquable (la flèche → ouvre la dialog d'aperçu du document
/// légal).
class ConsentCheckbox extends StatelessWidget {
  final bool checked;
  final ValueChanged<bool?> onChanged;
  final String label;
  final VoidCallback onTapLabel;

  const ConsentCheckbox({
    super.key,
    required this.checked,
    required this.onChanged,
    required this.label,
    required this.onTapLabel,
  });

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 22,
            height: 22,
            child: Checkbox(
              value: checked,
              onChanged: onChanged,
              visualDensity: VisualDensity.compact,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
              ),
              activeColor: scheme.primary,
              side: BorderSide(
                color: AppColors.dsBorder(brightness),
                width: 1.5,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: GestureDetector(
              onTap: () => onChanged(!checked),
              behavior: HitTestBehavior.opaque,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: label,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: AppColors.dsText2(brightness),
                          height: 1.4,
                        ),
                      ),
                      TextSpan(
                        text: '  →',
                        style: TextStyle(
                          fontSize: 13,
                          color: scheme.primary,
                          fontWeight: FontWeight.w700,
                        ),
                        recognizer: _TapRecognizer(onTapLabel),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TapRecognizer extends TapGestureRecognizer {
  _TapRecognizer(VoidCallback handler) {
    onTap = handler;
  }
}
