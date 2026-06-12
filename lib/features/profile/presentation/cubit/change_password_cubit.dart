import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mangatracker/features/auth/presentation/cubit/auth_submission_status.dart';
import 'package:mangatracker/features/auth/services/auth.service.dart';
import 'package:mangatracker/features/profile/services/change_password.service.dart';

/// Erreurs typées du formulaire de changement de mot de passe, mappées vers
/// les clés l10n par la view (aucun texte dans le Cubit).
enum ChangePasswordError { wrongCurrentPassword, socialAccount, network }

/// État du formulaire « Changer mon mot de passe » (utilisateur connecté).
class ChangePasswordState extends Equatable {
  final AuthSubmissionStatus status;
  final ChangePasswordError? error;

  const ChangePasswordState({
    this.status = AuthSubmissionStatus.initial,
    this.error,
  });

  bool get isLoading => status == AuthSubmissionStatus.loading;
  bool get isSuccess => status == AuthSubmissionStatus.success;

  ChangePasswordState copyWith({
    AuthSubmissionStatus? status,
    ChangePasswordError? error,
    bool clearError = false,
  }) =>
      ChangePasswordState(
        status: status ?? this.status,
        error: clearError ? null : (error ?? this.error),
      );

  @override
  List<Object?> get props => [status, error];
}

/// Cubit qui consomme `PUT /user/password` (mot de passe actuel + nouveau).
///
/// L'API révoque TOUTES les sessions puis retourne un nouveau couple JWT :
/// en cas de succès, on persiste ces tokens via [AuthService.persistTokens]
/// — l'appareil courant reste connecté, les autres sont déconnectés.
class ChangePasswordCubit extends Cubit<ChangePasswordState> {
  final ChangePasswordService _changePasswordService;
  final AuthService _authService;

  ChangePasswordCubit({
    required ChangePasswordService changePasswordService,
    required AuthService authService,
  })  : _changePasswordService = changePasswordService,
        _authService = authService,
        super(const ChangePasswordState());

  Future<void> submit({
    required String currentPassword,
    required String newPassword,
  }) async {
    if (state.isLoading) return;
    emit(state.copyWith(
      status: AuthSubmissionStatus.loading,
      clearError: true,
    ));

    try {
      final tokens = await _changePasswordService.changePassword(
        currentPassword: currentPassword,
        newPassword: newPassword,
      );
      // Les anciennes sessions sont mortes côté serveur : sans cette
      // persistance, le prochain refresh échouerait → logout forcé.
      await _authService.persistTokens(
        accessToken: tokens.accessToken,
        refreshToken: tokens.refreshToken,
      );
      emit(state.copyWith(status: AuthSubmissionStatus.success));
    } on WrongCurrentPasswordException {
      emit(state.copyWith(
        status: AuthSubmissionStatus.failure,
        error: ChangePasswordError.wrongCurrentPassword,
      ));
    } on SocialAccountPasswordException {
      emit(state.copyWith(
        status: AuthSubmissionStatus.failure,
        error: ChangePasswordError.socialAccount,
      ));
    } catch (_) {
      emit(state.copyWith(
        status: AuthSubmissionStatus.failure,
        error: ChangePasswordError.network,
      ));
    }
  }

  void reset() => emit(const ChangePasswordState());
}
