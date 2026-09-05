import 'package:flutter/material.dart';
import 'package:mangatracker/core/components/offline_banner.dart';
import 'package:mangatracker/core/components/session_rejected_banner.dart';
import 'package:mangatracker/core/components/verify_email_banner.dart';
import 'package:mangatracker/core/components/welcome_header.dart';
import 'package:mangatracker/core/theme/app_spacing.dart';

/// Haut de l'accueil : salutation, bandeaux d'etat (hors ligne / session
/// rejetee) et rappel de verification d'e-mail. Conserve a l'identique ce
/// qui existait avant la refonte catalogue (2026-09-05).
class HomeHeaderBlock extends StatelessWidget {
  final String? username;

  /// `false` tant que l'e-mail n'est pas verifie → bandeau affiche.
  final bool emailVerified;
  final bool isOffline;
  final int pendingActions;

  /// Session rejetee par le serveur : invitation non bloquante, jamais de
  /// redirection forcee (cf. `failure_classifier.dart`).
  final bool requiresReauth;
  final VoidCallback onReconnect;

  const HomeHeaderBlock({
    super.key,
    required this.username,
    required this.emailVerified,
    required this.isOffline,
    required this.pendingActions,
    required this.requiresReauth,
    required this.onReconnect,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        WelcomeHeader(username: username),
        if (requiresReauth)
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.s + AppSpacing.xs),
            child: SessionRejectedBanner(onReconnect: onReconnect),
          )
        else if (isOffline)
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.s + AppSpacing.xs),
            child: OfflineBanner(pendingActions: pendingActions),
          ),
        VerifyEmailBanner(visible: !emailVerified),
      ],
    );
  }
}
