import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mangatracker/core/service_locator/service_locator.dart';
import 'package:mangatracker/core/theme/app_colors.dart';
import 'package:mangatracker/core/theme/app_spacing.dart';
import 'package:mangatracker/features/auth/services/auth.service.dart';
import 'package:mangatracker/features/auth/services/email_auth.service.dart';
import 'package:mangatracker/features/auth/widgets/auth_scaffold.dart';
import 'package:mangatracker/features/auth/widgets/auth_submit_button.dart';
import 'package:mangatracker/features/home/bloc/homepage_bloc.dart';
import 'package:mangatracker/features/home/bloc/homepage_event.dart';
import 'package:mangatracker/features/profile/services/user.service.dart';
import 'package:mangatracker/l10n/app_localizations.dart';

/// Vue intermédiaire qui consomme le token reçu dans le mail de
/// vérification — design V1.
///
/// Atteignable via deep link `https://bladeburu.com/auth/verify?token=XXX`.
/// 3 états : chargement → succès (redirection auto) ou erreur
/// (bouton « retour à la connexion »).
class VerifyEmailView extends StatefulWidget {
  final String token;

  const VerifyEmailView({super.key, required this.token});

  @override
  State<VerifyEmailView> createState() => _VerifyEmailViewState();
}

class _VerifyEmailViewState extends State<VerifyEmailView> {
  late Future<bool> _verifyFuture;

  @override
  void initState() {
    super.initState();
    _verifyFuture = _verify();
  }

  Future<bool> _verify() async {
    try {
      final emailAuth = getIt<EmailAuthService>();
      final auth = getIt<AuthService>();
      final tokens = await emailAuth.verifyEmail(widget.token);
      await auth.persistTokens(
        accessToken: tokens.accessToken,
        refreshToken: tokens.refreshToken,
      );
      try {
        final userService = getIt<UserService>();
        await userService.getUserInformation(forceRefresh: true);
      } catch (_) {/* Cache refresh non bloquant */}
      try {
        if (getIt.isRegistered<HomePageBloc>()) {
          getIt<HomePageBloc>().add(const RefreshHomePage());
        }
      } catch (_) {}
      return true;
    } on InvalidEmailTokenException {
      return false;
    } catch (_) {
      return false;
    }
  }

  void _goHome() => context.go('/home');
  void _goLogin() => context.go('/login');

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      child: FutureBuilder<bool>(
        future: _verifyFuture,
        builder: (context, snapshot) {
          final l10n = AppLocalizations.of(context);
          if (snapshot.connectionState != ConnectionState.done) {
            return _VerifyEmailStatus(
              iconColor: Theme.of(context).colorScheme.primary,
              showProgress: true,
              title: l10n?.verifyingEmail ?? 'Vérification en cours…',
            );
          }
          if (snapshot.data == true) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              Future.delayed(const Duration(milliseconds: 800), _goHome);
            });
            return _VerifyEmailStatus(
              icon: Icons.check_circle_outline,
              iconColor: Theme.of(context).colorScheme.primary,
              title: l10n?.emailVerifiedSuccess ?? 'Email vérifié !',
              message: l10n?.emailVerifiedHint ?? 'Connexion en cours…',
            );
          }
          return _VerifyEmailStatus(
            icon: Icons.error_outline,
            iconColor: Theme.of(context).colorScheme.error,
            title:
                l10n?.emailVerifyFailedTitle ?? 'Lien invalide ou expiré',
            message: l10n?.emailVerifyFailedHint ?? '',
            actionLabel: l10n?.backToLogin ?? 'Retour à la connexion',
            onAction: _goLogin,
          );
        },
      ),
    );
  }
}

class _VerifyEmailStatus extends StatelessWidget {
  final IconData? icon;
  final Color iconColor;
  final bool showProgress;
  final String title;
  final String? message;
  final String? actionLabel;
  final VoidCallback? onAction;

  const _VerifyEmailStatus({
    this.icon,
    required this.iconColor,
    this.showProgress = false,
    required this.title,
    this.message,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final scheme = Theme.of(context).colorScheme;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const SizedBox(height: AppSpacing.jumbo),
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.dsRedSoft(brightness),
            border: Border.all(
              color: AppColors.dsHairline(brightness),
              width: 1,
            ),
          ),
          child: showProgress
              ? Center(
                  child: SizedBox(
                    width: 28,
                    height: 28,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: iconColor,
                    ),
                  ),
                )
              : Icon(icon, size: 40, color: iconColor),
        ),
        const SizedBox(height: AppSpacing.l),
        Text(
          title,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
            color: scheme.onSurface,
          ),
        ),
        if (message != null && message!.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.s),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.m),
            child: Text(
              message!,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: AppColors.dsText2(brightness),
                height: 1.5,
              ),
            ),
          ),
        ],
        if (actionLabel != null && onAction != null) ...[
          const SizedBox(height: AppSpacing.xl),
          AuthSubmitButton(text: actionLabel!, onPressed: onAction),
        ],
      ],
    );
  }
}
