import 'package:equatable/equatable.dart';
import 'auth_submission_status.dart';

class LoginState extends Equatable {
  final AuthSubmissionStatus status;
  final String? errorMessage;
  final bool requiresBiometricPrompt;
  final String? pendingEmail;
  final String? pendingPassword;

  const LoginState({
    this.status = AuthSubmissionStatus.initial,
    this.errorMessage,
    this.requiresBiometricPrompt = false,
    this.pendingEmail,
    this.pendingPassword,
  });

  bool get isLoading => status == AuthSubmissionStatus.loading;
  bool get isSuccess => status == AuthSubmissionStatus.success;

  LoginState copyWith({
    AuthSubmissionStatus? status,
    String? errorMessage,
    bool? requiresBiometricPrompt,
    String? pendingEmail,
    String? pendingPassword,
    bool clearErrorMessage = false,
    bool clearPendingCredentials = false,
  }) {
    return LoginState(
      status: status ?? this.status,
      errorMessage: clearErrorMessage
          ? null
          : (errorMessage ?? this.errorMessage),
      requiresBiometricPrompt:
          requiresBiometricPrompt ?? this.requiresBiometricPrompt,
      pendingEmail:
          clearPendingCredentials ? null : (pendingEmail ?? this.pendingEmail),
      pendingPassword: clearPendingCredentials
          ? null
          : (pendingPassword ?? this.pendingPassword),
    );
  }

  @override
  List<Object?> get props => [
        status,
        errorMessage,
        requiresBiometricPrompt,
        pendingEmail,
        pendingPassword,
      ];
}

