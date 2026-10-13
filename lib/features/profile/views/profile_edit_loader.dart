import 'package:flutter/material.dart';
import 'package:mangatracker/core/components/app_back_button.dart';
import 'package:mangatracker/core/components/app_error_state.dart';
import 'package:mangatracker/core/service_locator/service_locator.dart';
import 'package:mangatracker/features/profile/dto/user_information.dto.dart';
import 'package:mangatracker/features/profile/services/user.service.dart';
import 'package:mangatracker/features/profile/views/profile_edit.view.dart';
import 'package:mangatracker/l10n/app_localizations.dart';

/// `/profile/edit` reconstructible depuis son URL seule.
///
/// Ouvert depuis le profil, le formulaire reçoit l'utilisateur déjà chargé
/// ([initialUser]). Par lien direct, F5 ou retour du navigateur, il n'y a
/// pas d'extra : on recharge le profil (cache compris, cf. `UserService`)
/// au lieu de l'ancien écran « Données utilisateur manquantes ».
class ProfileEditLoader extends StatefulWidget {
  final UserInformationDto? initialUser;

  const ProfileEditLoader({super.key, this.initialUser});

  @override
  State<ProfileEditLoader> createState() => _ProfileEditLoaderState();
}

class _ProfileEditLoaderState extends State<ProfileEditLoader> {
  Future<UserInformationDto>? _user;

  @override
  void initState() {
    super.initState();
    if (widget.initialUser == null) _load();
  }

  void _load() {
    setState(() => _user = getIt<UserService>().getUserInformation());
  }

  @override
  Widget build(BuildContext context) {
    final initial = widget.initialUser;
    if (initial != null) return ProfileEditView(currentUser: initial);
    return FutureBuilder<UserInformationDto>(
      future: _user,
      builder: (context, snapshot) {
        final user = snapshot.data;
        if (user != null) return ProfileEditView(currentUser: user);
        final l10n = AppLocalizations.of(context);
        return Scaffold(
          appBar: AppBar(
            leading: const AppBackButton(fallback: '/profile'),
            title: Text(l10n?.profileEditTitle ?? ''),
          ),
          body: snapshot.hasError
              ? AppErrorState(
                  message: l10n?.userInfoLoadError ?? '',
                  retryLabel: l10n?.retry,
                  onRetry: _load,
                )
              : const Center(child: CircularProgressIndicator()),
        );
      },
    );
  }
}
