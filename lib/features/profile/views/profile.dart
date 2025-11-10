import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mangatracker/l10n/app_localizations.dart';
import 'package:mangatracker/core/service_locator/service_locator.dart';
import 'package:mangatracker/core/services/language_service.dart';
import 'package:mangatracker/core/components/language_selector_button.dart';
import 'package:mangatracker/features/auth/services/auth.service.dart';
import 'package:mangatracker/features/auth/views/login.view.dart';
import 'package:mangatracker/features/profile/services/user.service.dart';
import 'package:mangatracker/core/components/password_fields.dart';
import 'package:mangatracker/core/notifier/notifier.dart';
import 'package:mangatracker/core/theme/app_radius.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../auth/services/validator.service.dart';
import '../dto/user_information.dto.dart';
import '../widgets/profile_header.dart';
import '../widgets/profile_option_tile.dart';
import '../widgets/profile_section.dart';
import '../widgets/changelog_card.dart';

/// Page de profil moderne avec Material 3 et composants réutilisables
class Profile extends StatefulWidget {
  const Profile({super.key});

  @override
  State<Profile> createState() => _ProfileState();
}

class _ProfileState extends State<Profile> {
  final AuthService _authService = getIt<AuthService>();
  final UserService _userService = getIt<UserService>();
  final Notifier _notifier = getIt<Notifier>();
  
  UserInformationDto? _userInfo;
  bool _isLoading = true;
  Locale? _currentLocale;
  bool? _biometricEnabled;
  
  Future<void> _loadLanguageService() async {
    final languageService = await getIt.getAsync<LanguageService>();
    setState(() {
      _currentLocale = languageService.getCurrentLocale();
    });
  }

  @override
  void initState() {
    super.initState();
    _loadUserInformation();
    _loadLanguageService();
    _loadBiometricStatus();
  }

  Future<void> _loadBiometricStatus() async {
    final isEnabled = await _authService.isBiometricEnabled();
    if (mounted) {
      setState(() {
        _biometricEnabled = isEnabled;
      });
    }
  }

  Future<void> _loadUserInformation() async {
    try {
      final userInfo = await _userService.getUserInformation();
      setState(() {
        _userInfo = userInfo;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      // En cas d'erreur, on garde les valeurs par défaut
      if (mounted) {
        final l10n = AppLocalizations.of(context);
        _notifier.error(l10n?.userInfoLoadError ?? 'Impossible de charger les informations utilisateur');
      }
    }
  }

  void _redirectToLoginPage() {
    HapticFeedback.lightImpact();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const LoginView()),
    );
  }

  void _showConfirmDeleteAccount() {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.warning_amber_rounded, color: Colors.red, size: 48),
        title: Text(l10n.confirmDeleteAccount),
        content: Text(l10n.confirmDeleteAccountMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              Navigator.of(context).pop();
              try {
                await _userService.deleteAccount();
                _redirectToLoginPage();
                _notifier.success(l10n.accountDeletedSuccess);
              } catch (e) {
                _notifier.error(l10n.accountDeleteError);
              }
            },
            child: Text(l10n.delete),
          ),
        ],
      ),
    );
  }

  void _showChangePasswordDialog() {
    final l10n = AppLocalizations.of(context)!;
    final formKey = GlobalKey<FormState>();
    final passwordController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.changePassword),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: PasswordFields(
              passwordControler: passwordController,
              confirmPasswordControler: TextEditingController(),
              validatorService: getIt<ValidatorService>(),
              update: true,
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;
              
              try {
                await _userService.changePassword(passwordController.text);
                if (context.mounted) {
                  Navigator.of(context).pop();
                  _notifier.success(l10n.passwordChangedSuccess);
                }
              } catch (e) {
                _notifier.error(l10n.passwordChangeError);
              }
            },
            child: Text(l10n.save),
          ),
        ],
      ),
    );
  }

  void _handleLogout() {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.confirmLogout),
        content: Text(l10n.confirmLogoutMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () async {
              await _authService.logout();
              if (context.mounted) {
                Navigator.of(context).pop();
                _redirectToLoginPage();
              }
            },
            child: Text(l10n.logout),
          ),
        ],
      ),
    );
  }

  // Méthode helper pour obtenir l'icône de drapeau (utilisée uniquement pour l'affichage dans ProfileOptionTile)
  Widget _getFlagIconForDisplay(String languageCode) {
    String assetPath;
    switch (languageCode) {
      case 'fr':
        assetPath = 'assets/images/flags/fr.png';
        break;
      case 'en':
        assetPath = 'assets/images/flags/uk.png';
        break;
      case 'de':
        assetPath = 'assets/images/flags/de.png';
        break;
      case 'ja':
        assetPath = 'assets/images/flags/jp.png';
        break;
      case 'ko':
        assetPath = 'assets/images/flags/kr.png';
        break;
      case 'pt':
        assetPath = 'assets/images/flags/pt.png';
        break;
      case 'es':
        assetPath = 'assets/images/flags/sp.png';
        break;
      default:
        return const SizedBox.shrink();
    }
    
    return ClipRRect(
      borderRadius: AppRadius.circularXs,
      child: Image.asset(
        assetPath,
        width: 32,
        height: 24,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          debugPrint('❌ Erreur de chargement du drapeau: $assetPath');
          debugPrint('   Erreur: $error');
          return Container(
            width: 32,
            height: 24,
            decoration: BoxDecoration(
              borderRadius: AppRadius.circularXs,
              color: Colors.grey.withValues(alpha: 0.3),
              border: Border.all(color: Colors.grey.withValues(alpha: 0.3), width: 0.5),
            ),
            child: const Icon(Icons.flag, size: 16, color: Colors.grey),
          );
        },
      ),
    );
  }

  Future<void> _handleBiometricToggle() async {
    final l10n = AppLocalizations.of(context)!;
    final currentStatus = _biometricEnabled ?? false;
    
    if (currentStatus) {
      // Désactiver la biométrie
      await _authService.setBiometricEnabled(false);
      setState(() {
        _biometricEnabled = false;
      });
      _notifier.success(l10n.disableBiometricAuth);
    } else {
      // Activer la biométrie
      // Vérifier si des identifiants sont déjà sauvegardés
      final hasCreds = await _authService.storageService.hasBiometricCredentials();
      
      if (!hasCreds) {
        // Pas d'identifiants disponibles, informer l'utilisateur
        if (mounted) {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: Text(l10n.biometricAuthTitle),
              content: Text(
                l10n.biometricAuthRequiresReconnect,
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(l10n.cancel),
                ),
                FilledButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    _handleLogout();
                  },
                  child: Text(l10n.logout),
                ),
              ],
            ),
          );
        }
      } else {
        // Des identifiants existent, activer directement
        await _authService.setBiometricEnabled(true);
        setState(() {
          _biometricEnabled = true;
        });
        _notifier.success(l10n.enableBiometricAuth);
      }
    }
  }

  Future<void> _showLanguageSelector() async {
    await LanguageSelectorButton.showLanguageSelector(
      context,
      onLanguageChanged: (locale) {
        if (mounted) {
          setState(() {
            _currentLocale = locale;
          });
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final username = _userInfo?.username ?? l10n.user;
    final email = _userInfo?.email ?? '';

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : CustomScrollView(
              slivers: [
                // Header avec informations utilisateur
                SliverToBoxAdapter(
                  child: ProfileHeader(
                    username: username,
                    email: email,
                    onAvatarTap: () {
                      // Possibilité d'ajouter une fonctionnalité de changement d'avatar
                      _notifier.info(l10n.comingSoonAvatar);
                    },
                  ),
                ),

                // Section Changelog/Versions
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 16, bottom: 8),
                    child: const ChangelogCard(),
                  ),
                ),

                // Section Compte
                SliverToBoxAdapter(
                  child: ProfileSection(
                    title: l10n.account,
                    children: [
                      ProfileOptionTile(
                        icon: Icons.lock_outline,
                        title: l10n.changePassword,
                        subtitle: l10n.changePasswordSubtitle,
                        onTap: _showChangePasswordDialog,
                        iconColor: Colors.orange,
                      ),
                      ProfileOptionTile(
                        icon: Icons.info_outline,
                        title: l10n.accountInformation,
                        subtitle: '${l10n.email}: $email',
                        showArrow: false,
                        iconColor: theme.colorScheme.primary,
                      ),
                    ],
                  ),
                ),

                // Section Paramètres (pour futures fonctionnalités)
                SliverToBoxAdapter(
                  child: ProfileSection(
                    title: l10n.settings,
                    children: [
                      Builder(
                        builder: (context) {
                          final languageService = getIt<LanguageService>();
                          final currentLocale = _currentLocale ?? languageService.getCurrentLocale();
                          final languageName = languageService.getLanguageName(currentLocale, context);
                          
                          return ProfileOptionTile(
                            leadingWidget: _getFlagIconForDisplay(currentLocale.languageCode),
                            title: l10n.language,
                            subtitle: languageName,
                            onTap: () async {
                              await _showLanguageSelector();
                              // La mise à jour de _currentLocale est déjà faite dans _showLanguageSelector
                            },
                            iconColor: Colors.green,
                          );
                        },
                      ),
                      ProfileOptionTile(
                        icon: Icons.notifications_outlined,
                        title: l10n.notifications,
                        subtitle: l10n.manageNotifications,
                        onTap: () {
                          _notifier.info(l10n.comingSoon);
                        },
                        iconColor: Colors.blue,
                      ),
                      ProfileOptionTile(
                        icon: Icons.dark_mode_outlined,
                        title: l10n.theme,
                        subtitle: l10n.lightMode,
                        onTap: () {
                          _notifier.info(l10n.comingSoon);
                        },
                        iconColor: Colors.indigo,
                      ),
                      FutureBuilder<bool>(
                        future: _authService.biometricService.hasBiometricSupport(),
                        builder: (context, snapshot) {
                          if (snapshot.hasData && snapshot.data == true) {
                            return ProfileOptionTile(
                              icon: Icons.fingerprint,
                              title: l10n.biometricAuthTitle,
                              subtitle: _biometricEnabled == true
                                  ? l10n.biometricAuthEnabled
                                  : l10n.biometricAuthDisabled,
                              onTap: () async {
                                await _handleBiometricToggle();
                              },
                              iconColor: Colors.purple,
                              trailing: Switch(
                                value: _biometricEnabled ?? false,
                                onChanged: (value) async {
                                  await _handleBiometricToggle();
                                },
                              ),
                            );
                          }
                          return const SizedBox.shrink();
                        },
                      ),
                    ],
                  ),
                ),

                // Section Actions
                SliverToBoxAdapter(
                  child: ProfileSection(
                    title: l10n.actions,
                    children: [
                      ProfileOptionTile(
                        icon: Icons.logout,
                        title: l10n.logout,
                        subtitle: l10n.logoutSubtitle,
                        onTap: _handleLogout,
                        iconColor: Colors.grey,
                        backgroundColor: Colors.grey.withValues(alpha: 0.1),
                      ),
                      ProfileOptionTile(
                        icon: Icons.delete_outline,
                        title: l10n.deleteAccount,
                        subtitle: l10n.deleteAccountSubtitle,
                        onTap: _showConfirmDeleteAccount,
                        iconColor: Colors.red,
                        backgroundColor: Colors.red.withValues(alpha: 0.1),
                      ),
                    ],
                  ),
                ),

                // Section Nous contacter
                SliverToBoxAdapter(
                  child: ProfileSection(
                    title: l10n.contactUs,
                    children: [
                      ProfileOptionTile(
                        icon: Icons.chat,
                        title: l10n.joinDiscord,
                        subtitle: l10n.joinDiscordSubtitle,
                        onTap: () async {
                          final uri = Uri.parse('https://discord.gg/X6sBgFY7');
                          if (await canLaunchUrl(uri)) {
                            await launchUrl(uri, mode: LaunchMode.externalApplication);
                          } else {
                            _notifier.error(l10n.discordLinkError);
                          }
                        },
                        iconColor: Colors.indigo,
                      ),
                    ],
                  ),
                ),

                // Espacement en bas
                const SliverToBoxAdapter(
                  child: SizedBox(height: 24),
                ),
              ],
            ),
    );
  }
}

