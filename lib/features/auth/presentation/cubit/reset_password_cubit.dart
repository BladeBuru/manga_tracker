import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mangatracker/features/auth/services/auth.service.dart';
import 'package:mangatracker/features/auth/services/email_auth.service.dart';

import 'auth_submission_status.dart';

/// État du formulaire « Définir un nouveau mot de passe » (reset password
/// confirm). Le token est extrait de l'URL deep link.
class ResetPasswordState extends Equatable {
  final AuthSubmissionStatus status;
  final String? errorMessage;
  final bool tokenExpired;

  const ResetPasswordState({
    this.status = AuthSubmissionStatus.initial,
    this.errorMessage,
    this.tokenExpired = false,
  });

  bool get isLoading => status == AuthSubmissionStatus.loading;
  bool get isSuccess => status == AuthSubmissionStatus.success;

  ResetPasswordState copyWith({
    AuthSubmissionStatus? status,
    String? errorMessage,
    bool clearError = false,
    bool? tokenExpired,
  }) =>
      ResetPasswordState(
        status: status ?? this.status,
        errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
        tokenExpired: tokenExpired ?? this.tokenExpired,
      );

  @override
  List<Object?> get props => [status, errorMessage, tokenExpired];
}

/// Cubit qui consomme un token de reset + un nouveau mot de passe.
/// En cas de succès, persiste les JWT auto-login retournés par l'API
/// via [AuthService.persistTokens] (cf. `auth.service.dart`).
class ResetPasswordCubit extends Cubit<ResetPasswordState> {
  final EmailAuthService _emailAuth;
  final AuthService _authService;

  ResetPasswordCubit({
    required EmailAuthService emailAuth,
    required AuthService authService,
  })  : _emailAuth = emailAuth,
        _authService = authService,
        super(const ResetPasswordState());

  Future<void> submit({
    required String token,
    required String newPassword,
  }) async {
    if (state.isLoading) return;
    emit(state.copyWith(
      status: AuthSubmissionStatus.loading,
      clearError: true,
      tokenExpired: false,
    ));

    try {
      final tokens = await _emailAuth.confirmPasswordReset(
        token: token,
        newPassword: newPassword,
      );
      // Persiste les tokens reçus → l'utilisateur est auto-loggué.
      // Note : ne pas oublier de réinitialiser les BLoCs HomePage/Library
      // côté view après succès (re-login).
      await _authService.persistTokens(
        accessToken: tokens.accessToken,
        refreshToken: tokens.refreshToken,
      );
      emit(state.copyWith(status: AuthSubmissionStatus.success));
    } on InvalidEmailTokenException catch (e) {
      emit(state.copyWith(
        status: AuthSubmissionStatus.failure,
        errorMessage: e.message,
        tokenExpired: true,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: AuthSubmissionStatus.failure,
        errorMessage: 'network_error',
      ));
    }
  }

  void reset() => emit(const ResetPasswordState());
}
