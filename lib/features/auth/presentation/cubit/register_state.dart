import 'package:equatable/equatable.dart';

import 'auth_submission_status.dart';

/// État de l'inscription utilisateur.
///
/// Inclut les flags de consentement RGPD (CGU + Politique de confidentialité)
/// qui DOIVENT être cochés avant de pouvoir soumettre le formulaire.
class RegisterState extends Equatable {
  final AuthSubmissionStatus status;
  final String? errorMessage;

  /// L'utilisateur a coché « J'accepte les CGU ».
  final bool acceptedTos;

  /// L'utilisateur a coché « J'accepte la Politique de confidentialité ».
  final bool acceptedPrivacy;

  const RegisterState({
    this.status = AuthSubmissionStatus.initial,
    this.errorMessage,
    this.acceptedTos = false,
    this.acceptedPrivacy = false,
  });

  bool get isLoading => status == AuthSubmissionStatus.loading;
  bool get isSuccess => status == AuthSubmissionStatus.success;

  /// `true` quand l'utilisateur a coché les deux consentements obligatoires.
  bool get canSubmit => acceptedTos && acceptedPrivacy;

  RegisterState copyWith({
    AuthSubmissionStatus? status,
    String? errorMessage,
    bool clearErrorMessage = false,
    bool? acceptedTos,
    bool? acceptedPrivacy,
  }) {
    return RegisterState(
      status: status ?? this.status,
      errorMessage:
          clearErrorMessage ? null : (errorMessage ?? this.errorMessage),
      acceptedTos: acceptedTos ?? this.acceptedTos,
      acceptedPrivacy: acceptedPrivacy ?? this.acceptedPrivacy,
    );
  }

  @override
  List<Object?> get props =>
      [status, errorMessage, acceptedTos, acceptedPrivacy];
}

