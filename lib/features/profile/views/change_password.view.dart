import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:mangatracker/core/service_locator/service_locator.dart';
import 'package:mangatracker/core/theme/app_colors.dart';
import 'package:mangatracker/core/theme/app_spacing.dart';
import 'package:mangatracker/features/auth/services/auth.service.dart';
import 'package:mangatracker/features/auth/services/validator.service.dart';
import 'package:mangatracker/features/auth/widgets/auth_form_card.dart';
import 'package:mangatracker/features/auth/widgets/auth_hero.dart';
import 'package:mangatracker/features/auth/widgets/auth_password_field.dart';
import 'package:mangatracker/features/auth/widgets/auth_password_section.dart';
import 'package:mangatracker/features/auth/widgets/auth_scaffold.dart';
import 'package:mangatracker/features/auth/widgets/auth_submit_button.dart';
import 'package:mangatracker/features/auth/widgets/auth_top_bar.dart';
import 'package:mangatracker/features/profile/presentation/cubit/change_password_cubit.dart';
import 'package:mangatracker/features/profile/services/change_password.service.dart';
import 'package:mangatracker/l10n/app_localizations.dart';

/// Vue « Changer mon mot de passe » — design V1, utilisateur connecté.
///
/// Demande le mot de passe ACTUEL + le nouveau (avec confirmation). Après
/// succès, l'API a révoqué toutes les sessions et retourné un nouveau couple
/// JWT (persisté par le Cubit) : l'appareil courant reste connecté, les
/// autres appareils sont déconnectés.
class ChangePasswordView extends StatefulWidget {
  const ChangePasswordView({super.key});

  @override
  State<ChangePasswordView> createState() => _ChangePasswordViewState();
}

class _ChangePasswordViewState extends State<ChangePasswordView> {
  final _formKey = GlobalKey<FormState>();
  final _currentController = TextEditingController();
  final _newController = TextEditingController();
  final _confirmController = TextEditingController();
  late final ChangePasswordCubit _cubit;
  late final ValidatorService _validator;

  @override
  void initState() {
    super.initState();
    _cubit = ChangePasswordCubit(
      changePasswordService: getIt<ChangePasswordService>(),
      authService: getIt<AuthService>(),
    );
    _validator = getIt<ValidatorService>();
  }

  @override
  void dispose() {
    _cubit.close();
    _currentController.dispose();
    _newController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    FocusManager.instance.primaryFocus?.unfocus();
    _cubit.submit(
      currentPassword: _currentController.text,
      newPassword: _newController.text,
    );
  }

  void _goBack() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      child: BlocProvider<ChangePasswordCubit>.value(
        value: _cubit,
        child: BlocConsumer<ChangePasswordCubit, ChangePasswordState>(
          listener: (context, state) {
            if (state.isSuccess) {
              Future.delayed(const Duration(milliseconds: 800), () {
                if (mounted) _goBack();
              });
            }
          },
          builder: (context, state) {
            final l10n = AppLocalizations.of(context);
            if (state.isSuccess) return _ChangePasswordSuccess(l10n: l10n);
            return Form(
              key: _formKey,
              child: _ChangePasswordForm(
                state: state,
                currentController: _currentController,
                newController: _newController,
                confirmController: _confirmController,
                validator: _validator,
                onSubmit: _submit,
                onBack: _goBack,
                l10n: l10n,
              ),
            );
          },
        ),
      ),
    );
  }
}

class _ChangePasswordForm extends StatelessWidget {
  final ChangePasswordState state;
  final TextEditingController currentController;
  final TextEditingController newController;
  final TextEditingController confirmController;
  final ValidatorService validator;
  final VoidCallback onSubmit;
  final VoidCallback onBack;
  final AppLocalizations? l10n;

  const _ChangePasswordForm({
    required this.state,
    required this.currentController,
    required this.newController,
    required this.confirmController,
    required this.validator,
    required this.onSubmit,
    required this.onBack,
    required this.l10n,
  });

  String? _errorText(ChangePasswordError? error) {
    switch (error) {
      case ChangePasswordError.wrongCurrentPassword:
        return l10n?.changePasswordWrongCurrent ??
            'Le mot de passe actuel est incorrect';
      case ChangePasswordError.socialAccount:
        return l10n?.changePasswordSocialAccount ??
            'Ce compte utilise la connexion Google : il n\'a pas de mot de passe à modifier';
      case ChangePasswordError.network:
        return l10n?.networkError ?? 'Erreur réseau. Réessayez plus tard.';
      case null:
        return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final errorText = _errorText(state.error);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        AuthTopBar(onBack: onBack, backTooltip: l10n?.back ?? 'Retour'),
        const SizedBox(height: AppSpacing.s),
        AuthHero(
          title: l10n?.changePasswordTitle ?? 'Changer mon mot de passe',
          subtitle: l10n?.changePasswordIntro,
          logoSemanticLabel: l10n?.appTitle ?? 'MangaTracker',
        ),
        const SizedBox(height: AppSpacing.xl),
        AuthFormCard(
          children: [
            AuthPasswordField(
              label: l10n?.currentPasswordLabel ?? 'Mot de passe actuel',
              controller: currentController,
              // Pas de règle de complexité sur l'ANCIEN mot de passe (il peut
              // prédater la politique actuelle) — seulement requis.
              validator: (v) => (v == null || v.isEmpty)
                  ? (l10n?.validationPasswordRequired ??
                      'Veuillez entrer votre mot de passe')
                  : null,
              textInputAction: TextInputAction.next,
            ),
            AuthPasswordSection(
              passwordController: newController,
              confirmController: confirmController,
              validatorService: validator,
              isUpdate: true,
              passwordLabel: l10n?.newPasswordLabel,
              confirmLabel: l10n?.confirmNewPasswordLabel,
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.l),
        AuthSubmitButton(
          text: l10n?.changePassword ?? 'Modifier le mot de passe',
          onPressed: state.isLoading ? null : onSubmit,
          isLoading: state.isLoading,
        ),
        if (errorText != null) ...[
          const SizedBox(height: AppSpacing.s),
          Text(
            errorText,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: scheme.error,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
        const SizedBox(height: AppSpacing.l),
      ],
    );
  }
}

class _ChangePasswordSuccess extends StatelessWidget {
  final AppLocalizations? l10n;

  const _ChangePasswordSuccess({required this.l10n});

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
          child: Icon(
            Icons.check_circle_outline,
            size: 40,
            color: scheme.primary,
          ),
        ),
        const SizedBox(height: AppSpacing.l),
        Text(
          l10n?.changePasswordSuccess ?? 'Mot de passe modifié',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
            color: scheme.onSurface,
          ),
        ),
        const SizedBox(height: AppSpacing.s),
        Text(
          l10n?.changePasswordSuccessHint ??
              'Vos autres appareils ont été déconnectés. Retour au profil…',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 14,
            color: AppColors.dsText2(brightness),
            height: 1.5,
          ),
        ),
      ],
    );
  }
}
