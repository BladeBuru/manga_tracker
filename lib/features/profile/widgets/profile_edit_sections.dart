import 'package:flutter/material.dart';
import 'package:mangatracker/core/theme/app_colors.dart';
import 'package:mangatracker/l10n/app_localizations.dart';

// ╔═══════════════════════════════════════════════════════════════════════╗
// ║  Design System V1 « Refined Classic » — sections groupées en cards.   ║
// ║  Source : .claude-design/manga-tracker/project/profile-v1.jsx +       ║
// ║           tokens.css. Voir AppColors.ds* pour les couleurs converties ║
// ║           depuis oklch → hex.                                          ║
// ╚═══════════════════════════════════════════════════════════════════════╝

// ─────────────────────────────────────────────────────────────────────────────
// ProfileEditSection — label uppercase tracké + card blanche avec hairline.
// Le card a juste un drop shadow ultra-subtil + un outline 1px hairline (équiv.
// du `0 0 0 1px var(--hairline)` du CSS).
// ─────────────────────────────────────────────────────────────────────────────

class ProfileEditSection extends StatelessWidget {
  final String label;
  final List<Widget> children;

  const ProfileEditSection({
    super.key,
    required this.label,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final isDark = brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 10),
          child: Text(
            label.toUpperCase(),
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.88, // 0.08em * 11px
              color: AppColors.dsText2(brightness),
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
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
                      color: Color(0x0A140A0A), // rgba(20,10,10,0.04)
                      blurRadius: 2,
                      offset: Offset(0, 1),
                    ),
                  ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (int i = 0; i < children.length; i++) ...[
                children[i],
                if (i < children.length - 1)
                  Padding(
                    padding: const EdgeInsets.only(left: 16),
                    child: Container(
                      height: 1,
                      color: AppColors.dsHairline(brightness),
                    ),
                  ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// ProfileEditField — TextField inline avec label uppercase au-dessus.
// Focused state: bg subtil + barre verticale rouge 3px à gauche (style HTML).
// ─────────────────────────────────────────────────────────────────────────────

class ProfileEditField extends StatefulWidget {
  final String label;
  final TextEditingController controller;
  final String? hintText;
  final int maxLines;
  final int? maxLength;
  final TextInputType keyboardType;
  final ValueChanged<String>? onChanged;

  const ProfileEditField({
    super.key,
    required this.label,
    required this.controller,
    this.hintText,
    this.maxLines = 1,
    this.maxLength,
    this.keyboardType = TextInputType.text,
    this.onChanged,
  });

  @override
  State<ProfileEditField> createState() => _ProfileEditFieldState();
}

class _ProfileEditFieldState extends State<ProfileEditField> {
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final scheme = Theme.of(context).colorScheme;
    final focused = _focusNode.hasFocus;
    final hasCounter = widget.maxLength != null;
    final length = widget.controller.text.characters.length;

    return Stack(
      children: [
        // Barre verticale rouge à gauche quand focused
        if (focused)
          Positioned(
            top: 6,
            bottom: 6,
            left: 0,
            child: Container(
              width: 3,
              decoration: BoxDecoration(
                color: scheme.primary,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
        AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          color: focused ? AppColors.dsBgInset(brightness) : Colors.transparent,
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.label.toUpperCase(),
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.63, // 0.06em * 10.5
                  color: AppColors.dsText3(brightness),
                ),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: widget.controller,
                focusNode: _focusNode,
                maxLines: widget.maxLines,
                maxLength: widget.maxLength,
                keyboardType: widget.keyboardType,
                onChanged: (v) {
                  if (hasCounter) setState(() {}); // re-render counter
                  widget.onChanged?.call(v);
                },
                buildCounter: (_, {required currentLength, required isFocused, maxLength}) => null,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  letterSpacing: -0.075,
                  color: scheme.onSurface,
                  height: widget.maxLines > 1 ? 1.5 : null,
                ),
                decoration: InputDecoration(
                  hintText: widget.hintText,
                  hintStyle: TextStyle(
                    color: AppColors.dsText3(brightness),
                    fontWeight: FontWeight.w500,
                  ),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.zero,
                  isDense: true,
                ),
              ),
              if (hasCounter)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    '$length / ${widget.maxLength}',
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      fontFamily: 'JetBrainsMono',
                      fontFeatures: const [FontFeature.tabularFigures()],
                      fontSize: 11,
                      color: AppColors.dsText3(brightness),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// ProfileEditReadonlyField — valeur grisée + badge "Non modifiable" en haut à
// droite. opacity 0.75 sur la valeur (style HTML `locked`).
// ─────────────────────────────────────────────────────────────────────────────

class ProfileEditReadonlyField extends StatelessWidget {
  final String label;
  final String value;

  const ProfileEditReadonlyField({
    super.key,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label.toUpperCase(),
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.63,
                  color: AppColors.dsText3(brightness),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.dsBgInset(brightness),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  l10n.profileFieldReadOnly,
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.42, // 0.04em
                    color: AppColors.dsText3(brightness),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Opacity(
            opacity: 0.75,
            child: Text(
              value,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: AppColors.dsText2(brightness),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Note : ProfileEditDateField + ProfileEditPrivacyRow ont été déplacés dans
// profile_edit_rows.dart pour rester sous la limite 400 lignes par fichier
// (CLAUDE.md). Importer ce fichier en plus dans la view si nécessaire.
