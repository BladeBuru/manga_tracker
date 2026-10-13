import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mangatracker/core/components/app_empty_state.dart';
import 'package:mangatracker/core/router/auth_redirect.dart';
import 'package:mangatracker/l10n/app_localizations.dart';

/// Adresse inconnue (lien périmé, faute de frappe dans l'URL).
class RouteNotFoundPage extends StatelessWidget {
  const RouteNotFoundPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n?.routeNotFoundTitle ?? '')),
      body: AppEmptyState(
        icon: Icons.explore_off_outlined,
        title: l10n?.routeNotFoundTitle ?? '',
        subtitle: l10n?.routeNotFoundMessage,
        actionLabel: l10n?.backToHome,
        onAction: () => context.go(homeLocation),
      ),
    );
  }
}
