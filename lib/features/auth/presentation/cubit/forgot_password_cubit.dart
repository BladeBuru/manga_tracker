import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mangatracker/features/auth/services/email_auth.service.dart';

import 'auth_submission_status.dart';

/// État du formulaire « Mot de passe oublié ».
///
/// Anti-énumération : `success` est émis dans tous les cas où le serveur
/// répond 200, **même si l'email n'existe pas**. Le message UI est
/// volontairement générique ("Si un compte existe pour cet email…").
class ForgotPasswordState extends Equatable {
  final AuthSubmissionStatus status;
  final String? errorMessage;
  final String submittedEmail;

  const ForgotPasswordState({
    this.status = AuthSubmissionStatus.initial,
    this.errorMessage,
    this.submittedEmail = '',
  });

  bool get isLoading => status == AuthSubmissionStatus.loading;
  bool get isSuccess => status == AuthSubmissionStatus.success;
  bool get isFailure => status == AuthSubmissionStatus.failure;

  ForgotPasswordState copyWith({
    AuthSubmissionStatus? status,
    String? errorMessage,
    bool clearError = false,
    String? submittedEmail,
  }) =>
      ForgotPasswordState(
        status: status ?? this.status,
        errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
        submittedEmail: submittedEmail ?? this.submittedEmail,
      );

  @override
  List<Object?> get props => [status, errorMessage, submittedEmail];
}

class ForgotPasswordCubit extends Cubit<ForgotPasswordState> {
  final EmailAuthService _service;

  ForgotPasswordCubit({required EmailAuthService service})
      : _service = service,
        super(const ForgotPasswordState());

  Future<void> submit(String email) async {
    if (state.isLoading) return;
    final trimmed = email.trim().toLowerCase();
    emit(state.copyWith(
      status: AuthSubmissionStatus.loading,
      clearError: true,
      submittedEmail: trimmed,
    ));

    final ok = await _service.requestPasswordReset(trimmed);
    if (ok) {
      emit(state.copyWith(status: AuthSubmissionStatus.success));
    } else {
      emit(state.copyWith(
        status: AuthSubmissionStatus.failure,
        errorMessage: 'network_error',
      ));
    }
  }

  void reset() => emit(const ForgotPasswordState());
}
