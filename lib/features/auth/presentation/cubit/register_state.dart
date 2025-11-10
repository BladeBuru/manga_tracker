import 'package:equatable/equatable.dart';

import 'auth_submission_status.dart';

class RegisterState extends Equatable {
  final AuthSubmissionStatus status;
  final String? errorMessage;

  const RegisterState({
    this.status = AuthSubmissionStatus.initial,
    this.errorMessage,
  });

  bool get isLoading => status == AuthSubmissionStatus.loading;
  bool get isSuccess => status == AuthSubmissionStatus.success;

  RegisterState copyWith({
    AuthSubmissionStatus? status,
    String? errorMessage,
    bool clearErrorMessage = false,
  }) {
    return RegisterState(
      status: status ?? this.status,
      errorMessage:
          clearErrorMessage ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => [status, errorMessage];
}

