import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mangatracker/features/auth/services/auth.service.dart';
import 'package:mangatracker/l10n/app_localizations.dart';

import '../../utils/auth_error_mapper.dart';
import 'auth_submission_status.dart';
import 'register_state.dart';

class RegisterCubit extends Cubit<RegisterState> {
  final AuthService _authService;

  RegisterCubit({
    required AuthService authService,
  })  : _authService = authService,
        super(const RegisterState());

  Future<void> submit({
    required String username,
    required String email,
    required String password,
    required AppLocalizations? l10n,
  }) async {
    if (state.isLoading) return;

    emit(
      state.copyWith(
        status: AuthSubmissionStatus.loading,
        clearErrorMessage: true,
      ),
    );

    try {
      await _authService.attemptSignUp(
        username,
        email,
        password,
      );

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

  void reset() {
    emit(
      state.copyWith(
        status: AuthSubmissionStatus.initial,
        clearErrorMessage: true,
      ),
    );
  }
}

