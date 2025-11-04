import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mangatracker/l10n/app_localizations.dart';
import 'package:mangatracker/core/service_locator/service_locator.dart';
import 'package:mangatracker/core/services/language_service.dart';
import 'package:mangatracker/features/auth/services/auth.service.dart';
import 'package:mangatracker/features/auth/views/login.view.dart';
import 'package:mangatracker/features/profile/services/user.service.dart';
import 'package:mangatracker/core/components/password_fields.dart';
import 'package:mangatracker/core/notifier/notifier.dart';
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
            onPressed: () {
              _authService.logout();
              Navigator.of(context).pop();
              _redirectToLoginPage();
            },
            child: Text(l10n.logout),
          ),
        ],
      ),
    );
  }

  Widget _getFlagIcon(String languageCode) {
    String assetPath;
    switch (languageCode) {
      case 'fr':
        assetPath = 'assets/images/flags/fr.png';
        break;
      case 'en':
        assetPath = 'assets/images/flags/uk.png';
        break;
      default:
        return const SizedBox.shrink();
    }
    
    return ClipRRect(
      borderRadius: BorderRadius.circular(4),
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
              borderRadius: BorderRadius.circular(4),
              color: Colors.grey.withValues(alpha: 0.3),
              border: Border.all(color: Colors.grey.withValues(alpha: 0.3), width: 0.5),
            ),
            child: const Icon(Icons.flag, size: 16, color: Colors.grey),
          );
        },
      ),
    );
  }

  Future<void> _showLanguageSelector() async {
    final l10n = AppLocalizations.of(context)!;
    final languageService = await getIt.getAsync<LanguageService>();
    final currentLocale = languageService.getCurrentLocale();
    final supportedLocales = languageService.getSupportedLocales();

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Container(
          width: MediaQuery.of(context).size.width * 0.85,
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Titre
              Text(
                l10n.selectLanguage,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 16),
              // Options de langue
              ...supportedLocales.map((locale) {
                final isSelected = locale.languageCode == currentLocale.languageCode;
                return Container(
                  margin: const EdgeInsets.symmetric(vertical: 6),
                  decoration: BoxDecoration(
                    color: isSelected 
                        ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.08)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected 
                          ? Theme.of(context).colorScheme.primary
                          : Colors.grey.withValues(alpha: 0.2),
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: InkWell(
                    onTap: () async {
                      await languageService.setLanguage(locale);
                      if (mounted) {
                        setState(() {
                          _currentLocale = locale;
                        });
                      }
                      Navigator.of(context).pop();
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      child: Row(
                        children: [
                          _getFlagIcon(locale.languageCode),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Text(
                              languageService.getLanguageName(locale, context),
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                                color: isSelected 
                                    ? Theme.of(context).colorScheme.primary
                                    : null,
                              ),
                            ),
                          ),
                          if (isSelected)
                            Icon(
                              Icons.check_circle,
                              color: Theme.of(context).colorScheme.primary,
                              size: 20,
                            ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
              const SizedBox(height: 8),
              // Bouton annuler
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(
                  l10n.cancel,
                  style: TextStyle(
                    fontSize: 14,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
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
                            leadingWidget: _getFlagIcon(currentLocale.languageCode),
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

                // Espacement en bas
                const SliverToBoxAdapter(
                  child: SizedBox(height: 24),
                ),
              ],
            ),
    );
  }
}

