import 'package:flutter/material.dart';
import 'package:mangatracker/core/theme/app_colors.dart';
import 'package:mangatracker/core/theme/app_spacing.dart';

/// Scaffold partagé pour toutes les pages d'auth (login, register,
/// forgot/reset/verify password).
///
/// Applique le fond `dsBg` (off-white en light, gris cool en dark) du
/// design system V1 « Refined Classic » et centre le contenu dans une
/// `ConstrainedBox` max 480px responsive — pattern repris des pages
/// d'édition de profil.
class AuthScaffold extends StatelessWidget {
  final Widget child;

  /// Permet de désactiver le retour arrière physique (PopScope) — utile
  /// pour login/register qui sont des écrans racines de l'auth flow.
  final bool canPop;

  const AuthScaffold({
    super.key,
    required this.child,
    this.canPop = true,
  });

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final body = Scaffold(
      backgroundColor: brightness == Brightness.dark
          ? AppColors.dsBgDark
          : AppColors.dsBgLight,
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final bottomInset = MediaQuery.of(context).viewInsets.bottom;
            final horizontalPadding = _horizontalPadding(constraints.maxWidth);
            return SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                horizontalPadding,
                AppSpacing.s,
                horizontalPadding,
                bottomInset + AppSpacing.m,
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 480),
                  child: child,
                ),
              ),
            );
          },
        ),
      ),
    );

    if (canPop) return body;
    return PopScope(canPop: false, child: body);
  }

  double _horizontalPadding(double maxWidth) {
    if (maxWidth >= 1200) return (maxWidth - 640) / 2;
    if (maxWidth >= 900) return 96;
    if (maxWidth >= 600) return 48;
    return AppSpacing.l;
  }
}
