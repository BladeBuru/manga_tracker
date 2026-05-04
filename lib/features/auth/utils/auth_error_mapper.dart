import 'dart:async';

import 'package:mangatracker/core/network/network_compat.dart';
import 'package:mangatracker/features/auth/exceptions/auth_server.exception.dart';
import 'package:mangatracker/features/auth/exceptions/email_already_used.exception.dart';
import 'package:mangatracker/features/auth/exceptions/invalid_credentials.exception.dart';
import 'package:mangatracker/l10n/app_localizations.dart';

class AuthErrorMapper {
  const AuthErrorMapper._();

  static String map(Object error, AppLocalizations? l10n) {
    if (error is InvalidCredentialsException) {
      return l10n?.invalidCredentials ?? 'Identifiants invalides';
    }

    if (error is EmailAlreadyUsedException) {
      return l10n?.emailAlreadyUsed ?? 'Cette adresse e-mail est déjà utilisée';
    }

    if (error is SocketException) {
      return l10n?.networkError ?? 'Veuillez vérifier votre connexion internet';
    }

    if (error is TimeoutException) {
      return l10n?.timeoutError ??
          'Le serveur met trop de temps à répondre. Veuillez réessayer.';
    }

    if (error is AuthServerException) {
      return error.message ??
          '${l10n?.unknownError ?? 'Erreur inconnue'} (${error.statusCode})';
    }

    return l10n?.unknownError ?? 'Erreur inconnue';
  }
}

