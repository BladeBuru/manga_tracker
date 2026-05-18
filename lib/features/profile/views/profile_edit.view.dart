import 'dart:convert';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show PlatformException;
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:mangatracker/core/service_locator/service_locator.dart';
import 'package:mangatracker/core/theme/app_colors.dart';
import 'package:mangatracker/features/profile/dto/user_information.dto.dart';
import 'package:mangatracker/features/profile/services/user.service.dart';
import 'package:mangatracker/features/profile/widgets/profile_edit_rows.dart';
import 'package:mangatracker/features/profile/widgets/profile_edit_sections.dart';
import 'package:mangatracker/features/profile/widgets/profile_edit_widgets.dart';
import 'package:mangatracker/l10n/app_localizations.dart';

/// Page d'édition du profil — Design System V1 « Refined Classic ».
///
/// Source : `.claude-design/manga-tracker/project/profile-v1.jsx`.
///
/// Structure :
///  - AppBar : chevron + "Profil" (gauche) · titre center · "Enregistrer"
///    rouge (droite). Hairline en bas.
///  - Hero avatar : 96px, bg-inset, hairline border, badge caméra rouge.
///  - 4 sections groupées en cards 16px radius + hairline outline :
///    Informations publiques, Compte, À propos de vous, Confidentialité
///  - CTA full-width "Enregistrer" radius 14, height 52, halo rouge.
class ProfileEditView extends StatefulWidget {
  final UserInformationDto currentUser;
  const ProfileEditView({super.key, required this.currentUser});

  @override
  State<ProfileEditView> createState() => _ProfileEditViewState();
}

class _ProfileEditViewState extends State<ProfileEditView> {
  final _formKey = GlobalKey<FormState>();
  final UserService _userService = getIt<UserService>();
  final ImagePicker _picker = ImagePicker();

  late final TextEditingController _displayNameCtrl;
  late final TextEditingController _bioCtrl;
  String? _avatarUrl; // data:image/... ou https://...
  DateTime? _dateOfBirth;
  UserGender? _gender;
  bool _isProfilePublic = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _displayNameCtrl =
        TextEditingController(text: widget.currentUser.displayName ?? '');
    _bioCtrl = TextEditingController(text: widget.currentUser.bio ?? '');
    _avatarUrl = widget.currentUser.avatarUrl;
    _dateOfBirth = widget.currentUser.dateOfBirth != null
        ? DateTime.tryParse(widget.currentUser.dateOfBirth!)
        : null;
    _gender = widget.currentUser.gender;
    _isProfilePublic = widget.currentUser.isProfilePublic;
  }

  @override
  void dispose() {
    _displayNameCtrl.dispose();
    _bioCtrl.dispose();
    super.dispose();
  }

  String? get _validAvatarUrl {
    final v = _avatarUrl;
    if (v == null || v.isEmpty) {
      return null;
    }
    if (v.startsWith('http://') ||
        v.startsWith('https://') ||
        v.startsWith('data:image/')) {
      return v;
    }
    return null;
  }

  Future<bool> _ensureGalleryPermission() async {
    if (kIsWeb) return true;
    final Permission perm;
    if (Platform.isAndroid || Platform.isIOS) {
      perm = Permission.photos;
    } else {
      return true; // Desktop : pas de permission OS pour la galerie
    }
    var status = await perm.status;
    if (status.isGranted || status.isLimited) return true;
    if (status.isPermanentlyDenied) {
      if (!mounted) return false;
      await showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          title:
              Text(AppLocalizations.of(ctx)!.profileEditPhotoPickFailed),
          content: const Text(
            'Accès à la galerie refusé. Active la permission dans les paramètres système.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('OK'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(ctx).pop();
                openAppSettings();
              },
              child: const Text('Paramètres'),
            ),
          ],
        ),
      );
      return false;
    }
    status = await perm.request();
    return status.isGranted || status.isLimited;
  }

  Future<void> _pickFromGallery() async {
    final granted = await _ensureGalleryPermission();
    if (!granted) return;
    try {
      final XFile? picked = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 75,
      );
      if (picked == null) return;
      final bytes = await picked.readAsBytes();
      final ext = picked.name.toLowerCase();
      final mime = ext.endsWith('.png')
          ? 'png'
          : ext.endsWith('.webp')
              ? 'webp'
              : 'jpeg';
      if (!mounted) return;
      setState(() =>
          _avatarUrl = 'data:image/$mime;base64,${base64Encode(bytes)}');
    } on PlatformException catch (e) {
      if (!mounted) return;
      final msg = switch (e.code) {
        'photo_access_denied' || 'camera_access_denied' =>
          'Accès à la galerie refusé. Vérifie les permissions.',
        'multiple_request' => 'Une sélection est déjà en cours.',
        _ => '${AppLocalizations.of(context)!.profileEditPhotoPickFailed} (${e.code})',
      };
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(msg),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${AppLocalizations.of(context)!.profileEditPhotoPickFailed}: $e',
          ),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dateOfBirth ?? DateTime(2000),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null && mounted) setState(() => _dateOfBirth = picked);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      await _userService.updateProfile(
        displayName: _displayNameCtrl.text.trim(),
        bio: _bioCtrl.text.trim(),
        avatarUrl: _validAvatarUrl,
        dateOfBirth: _dateOfBirth?.toIso8601String().split('T').first,
        gender: _gender?.value,
        isProfilePublic: _isProfilePublic,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.profileSaved)),
      );
      context.pop(true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${AppLocalizations.of(context)!.profileSaveFailed}: $e',
          ),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final brightness = Theme.of(context).brightness;
    final scheme = Theme.of(context).colorScheme;
    final bg = brightness == Brightness.dark
        ? AppColors.dsBgDark
        : AppColors.dsBgLight;
    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        shape: Border(
          bottom: BorderSide(
            color: AppColors.dsHairline(brightness),
            width: 1,
          ),
        ),
        title: Text(
          l10n.profileEditTitle,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: scheme.onSurface,
          ),
        ),
        centerTitle: true,
        leading: TextButton(
          onPressed: () => context.pop(),
          style: TextButton.styleFrom(
            foregroundColor: scheme.primary,
            padding: const EdgeInsets.symmetric(horizontal: 4),
            minimumSize: const Size(64, 40),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.chevron_left, size: 22, color: scheme.primary),
              Text(
                l10n.profileEditBackLabel,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: scheme.primary,
                ),
              ),
            ],
          ),
        ),
        leadingWidth: 90,
        actions: [
          if (_saving)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else
            TextButton(
              onPressed: _submit,
              child: Text(
                l10n.save,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: scheme.primary,
                ),
              ),
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final hPad = constraints.maxWidth >= 600 ? 32.0 : 16.0;
            return ListView(
              padding: EdgeInsets.fromLTRB(hPad, 0, hPad, 24),
              children: [
                ProfileEditHero(
                  url: _validAvatarUrl,
                  fallback: widget.currentUser.username,
                  onPick: _pickFromGallery,
                ),
                const SizedBox(height: 8),
                ProfileEditSection(
                  label: l10n.profileSectionPublicInfo,
                  children: [
                    ProfileEditField(
                      label: l10n.profileFieldDisplayName,
                      controller: _displayNameCtrl,
                      maxLength: 80,
                      onChanged: (_) => setState(() {}),
                    ),
                    ProfileEditField(
                      label: l10n.profileFieldBio,
                      controller: _bioCtrl,
                      maxLines: 4,
                      maxLength: 500,
                      keyboardType: TextInputType.multiline,
                      onChanged: (_) => setState(() {}),
                    ),
                  ],
                ),
                const SizedBox(height: 22),
                ProfileEditSection(
                  label: l10n.profileSectionAccount,
                  children: [
                    ProfileEditReadonlyField(
                      label: l10n.profileFieldUsername,
                      value: '@${widget.currentUser.username}',
                    ),
                    ProfileEditReadonlyField(
                      label: l10n.profileFieldEmail,
                      value: widget.currentUser.email,
                    ),
                  ],
                ),
                const SizedBox(height: 22),
                ProfileEditSection(
                  label: l10n.profileSectionAbout,
                  children: [
                    ProfileEditDateField(
                      value: _dateOfBirth,
                      onPick: _pickDate,
                      onClear: () => setState(() => _dateOfBirth = null),
                    ),
                    ProfileEditGenderChips(
                      sectionLabel: l10n.profileFieldGender,
                      gender: _gender,
                      onChanged: (g) => setState(() => _gender = g),
                    ),
                  ],
                ),
                const SizedBox(height: 22),
                ProfileEditSection(
                  label: l10n.profileSectionPrivacy,
                  children: [
                    ProfileEditPrivacyRow(
                      isPublic: _isProfilePublic,
                      onToggle: (v) => setState(() => _isProfilePublic = v),
                    ),
                  ],
                ),
                const SizedBox(height: 22),
                ProfileEditSaveButton(saving: _saving, onSave: _submit),
              ],
            );
          },
        ),
      ),
    );
  }
}
