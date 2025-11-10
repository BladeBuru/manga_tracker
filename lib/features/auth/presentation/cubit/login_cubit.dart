import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mangatracker/features/auth/services/auth.service.dart';
import 'package:mangatracker/l10n/app_localizations.dart';

import '../../utils/auth_error_mapper.dart';
import 'auth_submission_status.dart';
import 'login_state.dart';

class LoginCubit extends Cubit<LoginState> {
  final AuthService _authService;

  LoginCubit({
    required AuthService authService,
  })  : _authService = authService,
        super(const LoginState());

  Future<void> submit(
    String email,
    String password,
    AppLocalizations? l10n,
  ) async {
    if (state.isLoading) return;

    emit(
      state.copyWith(
        status: AuthSubmissionStatus.loading,
        clearErrorMessage: true,
        requiresBiometricPrompt: false,
        pendingEmail: null,
        pendingPassword: null,
        clearPendingCredentials: true,
      ),
    );

    try {
      await _authService.attemptLogIn(email, password);

      final hasPreference = await _authService.hasBiometricPreference();
      final hasSupport =
          await _authService.biometricService.hasBiometricSupport();

      emit(
        state.copyWith(
          status: AuthSubmissionStatus.success,
          requiresBiometricPrompt: !hasPreference && hasSupport,
          pendingEmail: email,
          pendingPassword: password,
        ),
      );
    } catch (error) {
      emit(
        state.copyWith(
          status: AuthSubmissionStatus.failure,
          errorMessage: AuthErrorMapper.map(error, l10n),
          requiresBiometricPrompt: false,
          clearPendingCredentials: true,
        ),
      );
    }
  }

  Future<void> completeBiometricPrompt(bool enable) async {
    if (!state.requiresBiometricPrompt) return;
    final email = state.pendingEmail;
    final password = state.pendingPassword;

    if (enable && email != null && password != null) {
      await _authService.setBiometricEnabled(
        true,
        email: email,
        password: password,
      );
    } else {
      await _authService.setBiometricEnabled(false);
    }

    emit(
      state.copyWith(
        requiresBiometricPrompt: false,
        clearPendingCredentials: true,
      ),
    );
  }

  void reset() {
    emit(
      state.copyWith(
        status: AuthSubmissionStatus.initial,
        clearErrorMessage: true,
        requiresBiometricPrompt: false,
        clearPendingCredentials: true,
      ),
    );
  }
}

