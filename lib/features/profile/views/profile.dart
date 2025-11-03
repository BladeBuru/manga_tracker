import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mangatracker/core/service_locator/service_locator.dart';
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

  @override
  void initState() {
    super.initState();
    _loadUserInformation();
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
        _notifier.error('Impossible de charger les informations utilisateur');
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
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.warning_amber_rounded, color: Colors.red, size: 48),
        title: const Text('Supprimer le compte'),
        content: const Text(
          'Cette action est irréversible. Toutes vos données seront définitivement supprimées et ne pourront pas être récupérées.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Annuler'),
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
                _notifier.success('Compte supprimé avec succès');
              } catch (e) {
                _notifier.error('Erreur lors de la suppression du compte');
              }
            },
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
  }

  void _showChangePasswordDialog() {
    final formKey = GlobalKey<FormState>();
    final passwordController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Modifier le mot de passe'),
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
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;
              
              try {
                await _userService.changePassword(passwordController.text);
                if (context.mounted) {
                  Navigator.of(context).pop();
                  _notifier.success('Mot de passe modifié avec succès');
                }
              } catch (e) {
                _notifier.error('Erreur lors de la modification du mot de passe');
              }
            },
            child: const Text('Enregistrer'),
          ),
        ],
      ),
    );
  }

  void _handleLogout() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Se déconnecter'),
        content: const Text('Êtes-vous sûr de vouloir vous déconnecter ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () {
              _authService.logout();
              Navigator.of(context).pop();
              _redirectToLoginPage();
            },
            child: const Text('Déconnecter'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final username = _userInfo?.username ?? 'Utilisateur';
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
                      _notifier.info('Fonctionnalité à venir : changement d\'avatar');
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
                    title: 'Compte',
                    children: [
                      ProfileOptionTile(
                        icon: Icons.lock_outline,
                        title: 'Modifier le mot de passe',
                        subtitle: 'Changez votre mot de passe de connexion',
                        onTap: _showChangePasswordDialog,
                        iconColor: Colors.orange,
                      ),
                      ProfileOptionTile(
                        icon: Icons.info_outline,
                        title: 'Informations du compte',
                        subtitle: 'Email: $email',
                        showArrow: false,
                        iconColor: theme.colorScheme.primary,
                      ),
                    ],
                  ),
                ),

                // Section Paramètres (pour futures fonctionnalités)
                SliverToBoxAdapter(
                  child: ProfileSection(
                    title: 'Paramètres',
                    children: [
                      ProfileOptionTile(
                        icon: Icons.notifications_outlined,
                        title: 'Notifications',
                        subtitle: 'Gérer les notifications',
                        onTap: () {
                          _notifier.info('Fonctionnalité à venir');
                        },
                        iconColor: Colors.blue,
                      ),
                      ProfileOptionTile(
                        icon: Icons.dark_mode_outlined,
                        title: 'Thème',
                        subtitle: 'Mode clair',
                        onTap: () {
                          _notifier.info('Fonctionnalité à venir');
                        },
                        iconColor: Colors.indigo,
                      ),
                    ],
                  ),
                ),

                // Section Actions
                SliverToBoxAdapter(
                  child: ProfileSection(
                    title: 'Actions',
                    children: [
                      ProfileOptionTile(
                        icon: Icons.logout,
                        title: 'Se déconnecter',
                        subtitle: 'Déconnectez-vous de votre compte',
                        onTap: _handleLogout,
                        iconColor: Colors.grey,
                        backgroundColor: Colors.grey.withValues(alpha: 0.1),
                      ),
                      ProfileOptionTile(
                        icon: Icons.delete_outline,
                        title: 'Supprimer le compte',
                        subtitle: 'Action irréversible',
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
