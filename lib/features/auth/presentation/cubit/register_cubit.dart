import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mangatracker/features/auth/services/auth.service.dart';
import 'package:mangatracker/features/profile/services/gdpr.service.dart';
import 'package:mangatracker/l10n/app_localizations.dart';

import '../../utils/auth_error_mapper.dart';
import 'auth_submission_status.dart';
import 'register_state.dart';

class RegisterCubit extends Cubit<RegisterState> {
  final AuthService _authService;
  final GdprService _gdprService;

  RegisterCubit({
    required AuthService authService,
    required GdprService gdprService,
  })  : _authService = authService,
        _gdprService = gdprService,
        super(const RegisterState());

  /// Toggle case « J'accepte les CGU »
  void setAcceptedTos(bool value) {
    emit(state.copyWith(acceptedTos: value));
  }

  /// Toggle case « J'accepte la Politique de confidentialité »
  void setAcceptedPrivacy(bool value) {
    emit(state.copyWith(acceptedPrivacy: value));
  }

  Future<void> submit({
    required String username,
    required String email,
    required String password,
    required AppLocalizations? l10n,
  }) async {
    if (state.isLoading) return;

    // Garde-fou côté client : ne JAMAIS soumettre sans consentement.
    // Le serveur stocke aussi le consentement post-inscription, mais on ne
    // veut même pas appeler /auth/register sans cases cochées (RGPD article 7).
    if (!state.canSubmit) {
      emit(
        state.copyWith(
          status: AuthSubmissionStatus.failure,
          errorMessage: l10n?.consentRequired ??
              'Vous devez accepter les CGU et la Politique de confidentialité.',
        ),
      );
      return;
    }

    emit(
      state.copyWith(
        status: AuthSubmissionStatus.loading,
        clearErrorMessage: true,
      ),
    );

    try {
      await _authService.attemptSignUp(username, email, password);

      // Connexion automatique après inscription
      await _authService.attemptLogIn(email, password);

      // Enregistrement du consentement éclairé en BDD (article 7 RGPD).
      // Erreur silencieuse : le compte est créé même si l'enregistrement
      // échoue ; un re-prompt sera fait au prochain login via
      // /user/gdpr/consent-status.
      try {
        final versions = await _gdprService.getConsentStatus();
        if (versions != null) {
          await _gdprService.recordConsent(
            tosVersion: versions.currentTosVersion,
            privacyVersion: versions.currentPrivacyVersion,
          );
        }
      } catch (e) {
        debugPrint('⚠️ RegisterCubit: échec enregistrement consentement: $e');
      }

      emit(
        state.copyWith(
          status: AuthSubmissionStatus.success,
          clearErrorMessage: true,
        ),
      );
    } catch (error) {
      emit(
        state.copyWith(
          status: AuthSubmissionStatus.failure,
          errorMessage: AuthErrorMapper.map(error, l10n),
        ),
      );
    }
  }

  /// Réinitialise complètement le state (y compris les consentements).
  void reset() {
    emit(const RegisterState());
  }
}
