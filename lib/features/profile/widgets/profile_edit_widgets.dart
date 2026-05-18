import 'package:flutter/material.dart';
import 'package:mangatracker/core/components/app_avatar.dart';
import 'package:mangatracker/core/theme/app_colors.dart';
import 'package:mangatracker/features/profile/dto/user_information.dto.dart';
import 'package:mangatracker/l10n/app_localizations.dart';

// ╔═══════════════════════════════════════════════════════════════════════╗
// ║  Design System V1 « Refined Classic » — Hero + GenderChips + CTA.     ║
// ║  Pas de gradient ring, pas de halo : avatar simple sur bg-inset avec  ║
// ║  bordure hairline et badge caméra rouge. Confirmé par l'utilisateur   ║
// ║  dans le chat handoff (chat1.md).                                     ║
// ╚═══════════════════════════════════════════════════════════════════════╝

// ─────────────────────────────────────────────────────────────────────────────
// ProfileEditHero — avatar 96px, bg-inset, hairline border, badge caméra.
// ─────────────────────────────────────────────────────────────────────────────

class ProfileEditHero extends StatelessWidget {
  final String? url;
  final String fallback;
  final VoidCallback onPick;

  const ProfileEditHero({
    super.key,
    required this.url,
    required this.fallback,
    required this.onPick,
  });

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final scheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;
    final scaffoldBg = Theme.of(context).scaffoldBackgroundColor;
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 24, 0, 16),
      child: Column(
        children: [
          GestureDetector(
            onTap: onPick,
            behavior: HitTestBehavior.opaque,
            child: SizedBox(
              width: 96,
              height: 96,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: 96,
                    height: 96,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.dsBgInset(brightness),
                      border: Border.all(
                        color: AppColors.dsHairline(brightness),
                        width: 1,
                      ),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: AppAvatar(
                      url: url,
                      fallback: fallback,
                      size: AppAvatarSize.hero,
                    ),
                  ),
                  Positioned(
                    right: -2,
                    bottom: -2,
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: scheme.primary,
                        shape: BoxShape.circle,
                        border: Border.all(color: scaffoldBg, width: 3),
                      ),
                      alignment: Alignment.center,
                      child: Icon(
                        Icons.camera_alt_outlined,
                        size: 14,
                        color: scheme.onPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: onPick,
            child: Text(
              l10n.profileChangePhoto,
              style: TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.135, // 0.01em * 13.5
                color: scheme.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// ProfileEditGenderChips — chips height 34, radius 999, border hairline.
// Actif : bg red-soft, border red, text red 600, check icon.
// ─────────────────────────────────────────────────────────────────────────────

class ProfileEditGenderChips extends StatelessWidget {
  final String sectionLabel;
  final UserGender? gender;
  final ValueChanged<UserGender?> onChanged;

  const ProfileEditGenderChips({
    super.key,
    required this.sectionLabel,
    required this.gender,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final l10n = AppLocalizations.of(context)!;
    final chips = <(UserGender, String)>[
      (UserGender.male, l10n.profileGenderMale),
      (UserGender.female, l10n.profileGenderFemale),
      (UserGender.nonBinary, l10n.profileGenderNonBinary),
      (UserGender.preferNotToSay, l10n.profileGenderPreferNotToSay),
    ];
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            sectionLabel.toUpperCase(),
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.63,
              color: AppColors.dsText3(brightness),
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: chips
                .map((e) => _GenderChip(
                      value: e.$1,
                      label: e.$2,
                      selected: gender == e.$1,
                      onTap: () => onChanged(gender == e.$1 ? null : e.$1),
                    ))
                .toList(),
          ),
        ],
      ),
    );
  }
}

class _GenderChip extends StatelessWidget {
  final UserGender value;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _GenderChip({
    required this.value,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final scheme = Theme.of(context).colorScheme;
    final bg = selected
        ? AppColors.dsRedSoft(brightness)
        : (brightness == Brightness.dark ? AppColors.dsSurfaceDark : Colors.white);
    final borderColor = selected ? scheme.primary : AppColors.dsBorder(brightness);
    final textColor = selected ? scheme.primary : AppColors.dsText2(brightness);
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        height: 34,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: borderColor, width: 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (selected) ...[
              Icon(Icons.check, size: 14, color: scheme.primary),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 13.5,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                color: textColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// ProfileEditSaveButton — CTA pleine largeur, radius 14, height 52, halo rouge.
// Box shadow `0 8px 20px -8px red` du design HTML.
// ─────────────────────────────────────────────────────────────────────────────

class ProfileEditSaveButton extends StatelessWidget {
  final bool saving;
  final VoidCallback onSave;

  const ProfileEditSaveButton({
    super.key,
    required this.saving,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: scheme.primary.withAlpha(saving ? 30 : 95),
            blurRadius: 20,
            spreadRadius: -8,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: FilledButton(
        onPressed: saving ? null : onSave,
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.15, // 0.01em
          ),
        ),
        child: saving
            ? SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2.4,
                  color: scheme.onPrimary,
                ),
              )
            : Text(l10n.save),
      ),
    );
  }
}
