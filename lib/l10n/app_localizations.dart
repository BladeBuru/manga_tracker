import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_de.dart';
import 'app_localizations_en.dart';
import 'app_localizations_es.dart';
import 'app_localizations_fr.dart';
import 'app_localizations_ja.dart';
import 'app_localizations_ko.dart';
import 'app_localizations_pt.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('de'),
    Locale('en'),
    Locale('es'),
    Locale('fr'),
    Locale('ja'),
    Locale('ko'),
    Locale('pt'),
  ];

  /// Le titre de l'application
  ///
  /// In fr, this message translates to:
  /// **'MangaTracker'**
  String get appTitle;

  /// Message de bienvenue sur la page de connexion
  ///
  /// In fr, this message translates to:
  /// **'Content de vous revoir'**
  String get welcomeBack;

  /// Label pour le champ email
  ///
  /// In fr, this message translates to:
  /// **'Adresse e-mail'**
  String get emailAddress;

  /// Label pour le champ mot de passe
  ///
  /// In fr, this message translates to:
  /// **'Mot de passe'**
  String get password;

  /// Lien pour réinitialiser le mot de passe
  ///
  /// In fr, this message translates to:
  /// **'Mot de passe oublié ?'**
  String get forgotPassword;

  /// Bouton de connexion
  ///
  /// In fr, this message translates to:
  /// **'Se connecter'**
  String get login;

  /// Message d'erreur quand la connexion Google échoue
  ///
  /// In fr, this message translates to:
  /// **'Échec de la connexion avec Google'**
  String get googleLoginFailed;

  /// Erreur quand le SDK Google refuse la configuration de l'app (OAuth client Android / SHA-1 manquant dans la console GCP)
  ///
  /// In fr, this message translates to:
  /// **'Connexion Google indisponible (erreur de configuration de l\'application)'**
  String get googleLoginConfigError;

  /// Web uniquement : le navigateur a bloqué la popup OAuth Google (window.open null)
  ///
  /// In fr, this message translates to:
  /// **'Fenêtre de connexion bloquée par le navigateur — autorisez les pop-ups pour ce site puis réessayez'**
  String get googlePopupBlocked;

  /// Bouton connexion Google
  ///
  /// In fr, this message translates to:
  /// **'Se connecter avec Google'**
  String get loginWithGoogle;

  /// Libellé pour retourner en arrière
  ///
  /// In fr, this message translates to:
  /// **'Retour'**
  String get back;

  /// Bouton d'inscription
  ///
  /// In fr, this message translates to:
  /// **'S\'inscrire'**
  String get signUp;

  /// Message d'erreur pour des identifiants incorrects
  ///
  /// In fr, this message translates to:
  /// **'Identifiants invalides'**
  String get invalidCredentials;

  /// Message d'erreur générique
  ///
  /// In fr, this message translates to:
  /// **'Erreur inconnue'**
  String get unknownError;

  /// Titre de la section tendances
  ///
  /// In fr, this message translates to:
  /// **'Tendances'**
  String get trending;

  /// Filtre pour afficher les mangas populaires
  ///
  /// In fr, this message translates to:
  /// **'Populaires'**
  String get popular;

  /// Label pour les nouveaux mangas
  ///
  /// In fr, this message translates to:
  /// **'Nouveau'**
  String get newMangas;

  /// Indicateur de mode hors ligne
  ///
  /// In fr, this message translates to:
  /// **'Mode hors ligne'**
  String get offlineMode;

  /// Message quand il n'y a pas de données en cache
  ///
  /// In fr, this message translates to:
  /// **'Mode hors ligne - Aucune donnée en cache'**
  String get offlineModeNoCache;

  /// Message quand une action est en file d'attente
  ///
  /// In fr, this message translates to:
  /// **'Mode hors ligne - Action en queue'**
  String get offlineModeActionQueued;

  /// Nombre d'actions en attente
  ///
  /// In fr, this message translates to:
  /// **'{count} action{count, plural, =0{s} =1{} other{s}} en attente'**
  String pendingActions(int count);

  /// Bouton pour réessayer une action
  ///
  /// In fr, this message translates to:
  /// **'Réessayer'**
  String get retry;

  /// État vide de la page de recherche
  ///
  /// In fr, this message translates to:
  /// **'Aucun résultat trouvé'**
  String get searchNoResults;

  /// Compteur de résultats de recherche (totalHits)
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =1{1 résultat} other{{count} résultats}}'**
  String searchResultsCount(int count);

  /// Erreur de chargement de la première page de résultats
  ///
  /// In fr, this message translates to:
  /// **'La recherche a échoué'**
  String get searchLoadFailed;

  /// Erreur de chargement de la page suivante (scroll infini)
  ///
  /// In fr, this message translates to:
  /// **'Impossible de charger la suite des résultats'**
  String get searchLoadMoreFailed;

  /// Label pour les erreurs
  ///
  /// In fr, this message translates to:
  /// **'Erreur'**
  String get error;

  /// Label pour la bibliothèque
  ///
  /// In fr, this message translates to:
  /// **'Bibliothèque'**
  String get library;

  /// Label pour la recherche
  ///
  /// In fr, this message translates to:
  /// **'Recherche'**
  String get search;

  /// Label pour le profil
  ///
  /// In fr, this message translates to:
  /// **'Mon compte'**
  String get profile;

  /// Section compte dans le profil
  ///
  /// In fr, this message translates to:
  /// **'Compte'**
  String get account;

  /// Section paramètres dans le profil
  ///
  /// In fr, this message translates to:
  /// **'Paramètres'**
  String get settings;

  /// Section actions dans le profil
  ///
  /// In fr, this message translates to:
  /// **'Actions'**
  String get actions;

  /// Option pour modifier le mot de passe
  ///
  /// In fr, this message translates to:
  /// **'Modifier le mot de passe'**
  String get changePassword;

  /// Sous-titre pour modifier le mot de passe
  ///
  /// In fr, this message translates to:
  /// **'Changez votre mot de passe de connexion'**
  String get changePasswordSubtitle;

  /// Titre de la page de changement de mot de passe
  ///
  /// In fr, this message translates to:
  /// **'Changer mon mot de passe'**
  String get changePasswordTitle;

  /// Texte d'introduction de la page de changement de mot de passe
  ///
  /// In fr, this message translates to:
  /// **'Saisissez votre mot de passe actuel puis choisissez-en un nouveau. Vos autres appareils seront déconnectés.'**
  String get changePasswordIntro;

  /// Label du champ mot de passe actuel
  ///
  /// In fr, this message translates to:
  /// **'Mot de passe actuel'**
  String get currentPasswordLabel;

  /// Label du champ nouveau mot de passe
  ///
  /// In fr, this message translates to:
  /// **'Nouveau mot de passe'**
  String get newPasswordLabel;

  /// Label du champ de confirmation du nouveau mot de passe
  ///
  /// In fr, this message translates to:
  /// **'Confirmer le nouveau mot de passe'**
  String get confirmNewPasswordLabel;

  /// Message de succès après changement de mot de passe
  ///
  /// In fr, this message translates to:
  /// **'Mot de passe modifié'**
  String get changePasswordSuccess;

  /// Précision affichée sous le message de succès du changement de mot de passe
  ///
  /// In fr, this message translates to:
  /// **'Vos autres appareils ont été déconnectés. Retour au profil…'**
  String get changePasswordSuccessHint;

  /// Erreur quand le mot de passe actuel saisi est faux
  ///
  /// In fr, this message translates to:
  /// **'Le mot de passe actuel est incorrect'**
  String get changePasswordWrongCurrent;

  /// Erreur pour les comptes Google sans mot de passe local
  ///
  /// In fr, this message translates to:
  /// **'Ce compte utilise la connexion Google : il n\'a pas de mot de passe à modifier'**
  String get changePasswordSocialAccount;

  /// Option pour voir les informations du compte
  ///
  /// In fr, this message translates to:
  /// **'Informations du compte'**
  String get accountInformation;

  /// Label pour l'email
  ///
  /// In fr, this message translates to:
  /// **'Email'**
  String get email;

  /// Option pour gérer les notifications
  ///
  /// In fr, this message translates to:
  /// **'Notifications'**
  String get notifications;

  /// Titre pour les notifications de nouveaux chapitres
  ///
  /// In fr, this message translates to:
  /// **'Notifications nouveaux chapitres'**
  String get newChapterNotifications;

  /// Texte indiquant que les notifications sont activées
  ///
  /// In fr, this message translates to:
  /// **'Activées'**
  String get newChapterNotificationsEnabled;

  /// Texte indiquant que les notifications sont désactivées
  ///
  /// In fr, this message translates to:
  /// **'Désactivées'**
  String get newChapterNotificationsDisabled;

  /// Sous-titre pour gérer les notifications
  ///
  /// In fr, this message translates to:
  /// **'Gérer les notifications'**
  String get manageNotifications;

  /// No description provided for @notifSectionApp.
  ///
  /// In fr, this message translates to:
  /// **'Notifications de l\'application'**
  String get notifSectionApp;

  /// No description provided for @notifSectionInfo.
  ///
  /// In fr, this message translates to:
  /// **'Informations'**
  String get notifSectionInfo;

  /// No description provided for @notifNewChaptersTitle.
  ///
  /// In fr, this message translates to:
  /// **'Nouveaux chapitres'**
  String get notifNewChaptersTitle;

  /// No description provided for @notifNewChaptersSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Soyez alerté quand vos mangas suivis publient de nouveaux chapitres'**
  String get notifNewChaptersSubtitle;

  /// No description provided for @notifFriendReqTitle.
  ///
  /// In fr, this message translates to:
  /// **'Demandes d\'ami'**
  String get notifFriendReqTitle;

  /// No description provided for @notifFriendReqSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Quelqu\'un veut vous ajouter en ami'**
  String get notifFriendReqSubtitle;

  /// No description provided for @notifSharesTitle.
  ///
  /// In fr, this message translates to:
  /// **'Recommandations reçues'**
  String get notifSharesTitle;

  /// No description provided for @notifSharesSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Un ami vous partage un manga'**
  String get notifSharesSubtitle;

  /// No description provided for @notifPermissionExplanation.
  ///
  /// In fr, this message translates to:
  /// **'Les notifications s\'affichent uniquement quand l\'application a la permission système. Si vous n\'en recevez aucune, activez-les depuis les réglages de votre téléphone.'**
  String get notifPermissionExplanation;

  /// No description provided for @notifOpenSystemSettings.
  ///
  /// In fr, this message translates to:
  /// **'Ouvrir les réglages système'**
  String get notifOpenSystemSettings;

  /// No description provided for @pushNotifFriendRequestTitle.
  ///
  /// In fr, this message translates to:
  /// **'Nouvelle demande d\'ami'**
  String get pushNotifFriendRequestTitle;

  /// No description provided for @pushNotifFriendRequestBody.
  ///
  /// In fr, this message translates to:
  /// **'{senderUsername} veut vous ajouter en ami'**
  String pushNotifFriendRequestBody(String senderUsername);

  /// No description provided for @pushNotifShareTitle.
  ///
  /// In fr, this message translates to:
  /// **'Nouveau manga partagé'**
  String get pushNotifShareTitle;

  /// No description provided for @pushNotifShareBody.
  ///
  /// In fr, this message translates to:
  /// **'{senderUsername} vous recommande {mangaTitle}'**
  String pushNotifShareBody(String senderUsername, String mangaTitle);

  /// Option pour gérer le thème
  ///
  /// In fr, this message translates to:
  /// **'Thème'**
  String get theme;

  /// Label pour le mode clair
  ///
  /// In fr, this message translates to:
  /// **'Mode clair'**
  String get lightMode;

  /// Label pour le mode sombre
  ///
  /// In fr, this message translates to:
  /// **'Mode sombre'**
  String get darkMode;

  /// Label pour le mode système (utilise les préférences du téléphone)
  ///
  /// In fr, this message translates to:
  /// **'Système'**
  String get systemMode;

  /// Option pour choisir la langue
  ///
  /// In fr, this message translates to:
  /// **'Langue'**
  String get language;

  /// Sous-titre pour sélectionner la langue
  ///
  /// In fr, this message translates to:
  /// **'Sélectionner la langue'**
  String get selectLanguage;

  /// Nom de la langue française
  ///
  /// In fr, this message translates to:
  /// **'Français'**
  String get french;

  /// Nom de la langue anglaise
  ///
  /// In fr, this message translates to:
  /// **'Anglais'**
  String get english;

  /// Option pour se déconnecter
  ///
  /// In fr, this message translates to:
  /// **'Se déconnecter'**
  String get logout;

  /// Sous-titre pour se déconnecter
  ///
  /// In fr, this message translates to:
  /// **'Déconnectez-vous de votre compte'**
  String get logoutSubtitle;

  /// Titre de la confirmation de déconnexion
  ///
  /// In fr, this message translates to:
  /// **'Se déconnecter'**
  String get confirmLogout;

  /// Message de confirmation de déconnexion
  ///
  /// In fr, this message translates to:
  /// **'Êtes-vous sûr de vouloir vous déconnecter ?'**
  String get confirmLogoutMessage;

  /// Option pour supprimer le compte
  ///
  /// In fr, this message translates to:
  /// **'Supprimer le compte'**
  String get deleteAccount;

  /// Sous-titre pour supprimer le compte
  ///
  /// In fr, this message translates to:
  /// **'Action irréversible'**
  String get deleteAccountSubtitle;

  /// Titre de la confirmation de suppression
  ///
  /// In fr, this message translates to:
  /// **'Supprimer le compte'**
  String get confirmDeleteAccount;

  /// Message de confirmation de suppression de compte
  ///
  /// In fr, this message translates to:
  /// **'Cette action est irréversible. Toutes vos données seront définitivement supprimées et ne pourront pas être récupérées.'**
  String get confirmDeleteAccountMessage;

  /// Bouton pour annuler
  ///
  /// In fr, this message translates to:
  /// **'Annuler'**
  String get cancel;

  /// Bouton d'enregistrement
  ///
  /// In fr, this message translates to:
  /// **'Enregistrer'**
  String get save;

  /// Bouton pour supprimer
  ///
  /// In fr, this message translates to:
  /// **'Supprimer'**
  String get delete;

  /// Message de succès pour le changement de mot de passe
  ///
  /// In fr, this message translates to:
  /// **'Mot de passe modifié avec succès'**
  String get passwordChangedSuccess;

  /// Message d'erreur pour le changement de mot de passe
  ///
  /// In fr, this message translates to:
  /// **'Erreur lors de la modification du mot de passe'**
  String get passwordChangeError;

  /// Message de succès pour la suppression de compte
  ///
  /// In fr, this message translates to:
  /// **'Compte supprimé avec succès'**
  String get accountDeletedSuccess;

  /// Message d'erreur pour la suppression de compte
  ///
  /// In fr, this message translates to:
  /// **'Erreur lors de la suppression du compte'**
  String get accountDeleteError;

  /// Message d'erreur pour le chargement des informations utilisateur
  ///
  /// In fr, this message translates to:
  /// **'Impossible de charger les informations utilisateur'**
  String get userInfoLoadError;

  /// Nom par défaut de l'utilisateur
  ///
  /// In fr, this message translates to:
  /// **'Utilisateur'**
  String get user;

  /// Message pour les fonctionnalités à venir
  ///
  /// In fr, this message translates to:
  /// **'Fonctionnalité à venir'**
  String get comingSoon;

  /// Message pour le changement d'avatar
  ///
  /// In fr, this message translates to:
  /// **'Fonctionnalité à venir : changement d\'avatar'**
  String get comingSoonAvatar;

  /// Titre du changelog
  ///
  /// In fr, this message translates to:
  /// **'Quoi de neuf ?'**
  String get whatsNew;

  /// Label pour la version
  ///
  /// In fr, this message translates to:
  /// **'Version'**
  String get version;

  /// Message pour les nouvelles fonctionnalités
  ///
  /// In fr, this message translates to:
  /// **'Nouvelles fonctionnalités disponibles'**
  String get newFeaturesAvailable;

  /// Label pour la version actuelle
  ///
  /// In fr, this message translates to:
  /// **'Version actuelle'**
  String get currentVersion;

  /// Bouton de confirmation
  ///
  /// In fr, this message translates to:
  /// **'Super !'**
  String get great;

  /// Titre pour l'autorisation requise
  ///
  /// In fr, this message translates to:
  /// **'Autorisation requise'**
  String get authorizationRequired;

  /// Action pour modifier un lien
  ///
  /// In fr, this message translates to:
  /// **'Modifier le lien'**
  String get modifyLink;

  /// Action pour supprimer un lien
  ///
  /// In fr, this message translates to:
  /// **'Supprimer le lien'**
  String get removeLink;

  /// Titre pour le saut de chapitres
  ///
  /// In fr, this message translates to:
  /// **'Saut de chapitres'**
  String get chapterSkip;

  /// Titre pour valider la lecture
  ///
  /// In fr, this message translates to:
  /// **'Valider la lecture'**
  String get validateReading;

  /// Action pour ajouter un manga à la bibliothèque
  ///
  /// In fr, this message translates to:
  /// **'Ajouter à la bibliothèque'**
  String get addToLibrary;

  /// Action pour retirer de la bibliothèque
  ///
  /// In fr, this message translates to:
  /// **'Retirer de la bibliothèque'**
  String get removeFromLibrary;

  /// Action pour mettre à jour le statut
  ///
  /// In fr, this message translates to:
  /// **'Mettre à jour le statut'**
  String get updateStatus;

  /// Statut de lecture : en cours
  ///
  /// In fr, this message translates to:
  /// **'En cours'**
  String get reading;

  /// Statut de lecture : terminé
  ///
  /// In fr, this message translates to:
  /// **'Terminé'**
  String get completed;

  /// Statut de lecture : en pause
  ///
  /// In fr, this message translates to:
  /// **'En pause'**
  String get onHold;

  /// Statut de lecture : abandonné
  ///
  /// In fr, this message translates to:
  /// **'Abandonné'**
  String get dropped;

  /// Statut de lecture : prévu
  ///
  /// In fr, this message translates to:
  /// **'Prévu'**
  String get planToRead;

  /// Statut de lecture : relecture
  ///
  /// In fr, this message translates to:
  /// **'Relecture'**
  String get reReading;

  /// Label pour les chapitres
  ///
  /// In fr, this message translates to:
  /// **'Chapitres'**
  String get chapters;

  /// Label pour les chapitres lus
  ///
  /// In fr, this message translates to:
  /// **'Chapitres lus'**
  String get readChapters;

  /// Label pour le total de chapitres
  ///
  /// In fr, this message translates to:
  /// **'Total de chapitres'**
  String get totalChapters;

  /// Titre pour la section des noms associés du manga
  ///
  /// In fr, this message translates to:
  /// **'Noms associés'**
  String get associatedNames;

  /// Nombre de noms associés
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =0{Aucun nom} =1{{count} nom} other{{count} noms}}'**
  String associatedNamesCount(num count);

  /// Action pour enregistrer la progression
  ///
  /// In fr, this message translates to:
  /// **'Enregistrer la progression'**
  String get saveProgress;

  /// Label pour la description
  ///
  /// In fr, this message translates to:
  /// **'Description'**
  String get description;

  /// Label pour les auteurs
  ///
  /// In fr, this message translates to:
  /// **'Auteurs'**
  String get authors;

  /// Label pour les genres
  ///
  /// In fr, this message translates to:
  /// **'Genres'**
  String get genres;

  /// Label pour les recommandations
  ///
  /// In fr, this message translates to:
  /// **'Recommandations'**
  String get recommendations;

  /// Message de chargement
  ///
  /// In fr, this message translates to:
  /// **'Chargement...'**
  String get loading;

  /// Message quand il n'y a pas de données
  ///
  /// In fr, this message translates to:
  /// **'Aucune donnée disponible'**
  String get noData;

  /// Message quand il n'y a pas de résultats
  ///
  /// In fr, this message translates to:
  /// **'Aucun résultat'**
  String get noResults;

  /// Message pour rediriger vers l'inscription
  ///
  /// In fr, this message translates to:
  /// **'Vous n\'avez pas de compte ?'**
  String get noAccount;

  /// Label pour la page d'accueil
  ///
  /// In fr, this message translates to:
  /// **'Accueil'**
  String get home;

  /// Label pour la page de profil
  ///
  /// In fr, this message translates to:
  /// **'Mon compte'**
  String get myAccount;

  /// Message pour le mode offline avec données en cache
  ///
  /// In fr, this message translates to:
  /// **'Mode hors ligne - Données en cache'**
  String get offlineModeCached;

  /// Message d'erreur pour l'authentification biométrique
  ///
  /// In fr, this message translates to:
  /// **'Échec de l\'authentification biométrique'**
  String get biometricAuthFailed;

  /// Label pour la connexion biométrique
  ///
  /// In fr, this message translates to:
  /// **'Connexion biométrique'**
  String get biometricAuth;

  /// Action pour ajouter un lien personnalisé
  ///
  /// In fr, this message translates to:
  /// **'Ajouter un lien'**
  String get addLink;

  /// Titre pour ajouter ou modifier un lien
  ///
  /// In fr, this message translates to:
  /// **'Ajouter ou modifier un lien'**
  String get addOrModifyLink;

  /// Placeholder pour l'URL du lien
  ///
  /// In fr, this message translates to:
  /// **'https://exemple.com'**
  String get linkUrlPlaceholder;

  /// Bouton de validation
  ///
  /// In fr, this message translates to:
  /// **'Valider'**
  String get validate;

  /// Message d'erreur pour un lien invalide
  ///
  /// In fr, this message translates to:
  /// **'Lien invalide. Le lien doit commencer par http:// ou https://'**
  String get invalidLink;

  /// Message de succès pour la sauvegarde d'un lien
  ///
  /// In fr, this message translates to:
  /// **'Lien enregistré !'**
  String get linkSaved;

  /// Message de succès pour la suppression d'un lien
  ///
  /// In fr, this message translates to:
  /// **'Lien supprimé !'**
  String get linkRemoved;

  /// Action pour lire en ligne
  ///
  /// In fr, this message translates to:
  /// **'Lire en ligne'**
  String get readOnline;

  /// Tooltip pour gérer le lien
  ///
  /// In fr, this message translates to:
  /// **'Gérer le lien'**
  String get manageLink;

  /// Titre pour les mangas recommandés
  ///
  /// In fr, this message translates to:
  /// **'Mangas recommandés'**
  String get recommendedMangas;

  /// Message quand il n'y a pas de recommandations
  ///
  /// In fr, this message translates to:
  /// **'Aucune recommandation disponible.'**
  String get noRecommendationsAvailable;

  /// Bouton pour fermer
  ///
  /// In fr, this message translates to:
  /// **'Fermer'**
  String get close;

  /// Titre pour changer le statut de lecture
  ///
  /// In fr, this message translates to:
  /// **'Changer le statut'**
  String get changeStatus;

  /// Message de succès pour l'ajout à la bibliothèque
  ///
  /// In fr, this message translates to:
  /// **'Manga ajouté à la bibliothèque'**
  String get mangaAddedToLibrary;

  /// Message pour le statut de lecture
  ///
  /// In fr, this message translates to:
  /// **'Manga marqué comme'**
  String get mangaMarkedAs;

  /// Statut de lecture : à lire plus tard
  ///
  /// In fr, this message translates to:
  /// **'À lire plus tard'**
  String get readLater;

  /// Statut de lecture : à jour
  ///
  /// In fr, this message translates to:
  /// **'À jour'**
  String get upToDate;

  /// Action pour ajouter à la liste de lecture
  ///
  /// In fr, this message translates to:
  /// **'Ajouter à \"À lire plus tard\"'**
  String get addToReadLater;

  /// Message de succès pour le retrait de la bibliothèque
  ///
  /// In fr, this message translates to:
  /// **'Manga retiré de la bibliothèque'**
  String get mangaRemovedFromLibrary;

  /// Placeholder pour la barre de recherche
  ///
  /// In fr, this message translates to:
  /// **'Rechercher Mangas, Manwhas, ...'**
  String get searchPlaceholder;

  /// Label pour l'année
  ///
  /// In fr, this message translates to:
  /// **'Année'**
  String get year;

  /// Label pour le statut
  ///
  /// In fr, this message translates to:
  /// **'Statut'**
  String get status;

  /// Label pour l'auteur
  ///
  /// In fr, this message translates to:
  /// **'Auteur'**
  String get author;

  /// Label pour l'artiste
  ///
  /// In fr, this message translates to:
  /// **'Artiste'**
  String get artist;

  /// Label pour le synopsis
  ///
  /// In fr, this message translates to:
  /// **'Synopsis'**
  String get synopsis;

  /// Bouton pour voir plus de contenu
  ///
  /// In fr, this message translates to:
  /// **'Voir plus'**
  String get seeMore;

  /// Bouton pour voir moins de contenu
  ///
  /// In fr, this message translates to:
  /// **'Voir moins'**
  String get seeLess;

  /// Filtre pour afficher tous les mangas
  ///
  /// In fr, this message translates to:
  /// **'Tous'**
  String get all;

  /// Filtre pour afficher les nouveautés
  ///
  /// In fr, this message translates to:
  /// **'Nouveautés'**
  String get newReleases;

  /// Label pour un chapitre
  ///
  /// In fr, this message translates to:
  /// **'Chapitre'**
  String get chapter;

  /// Nombre de chapitres avec pluralisation
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =0{Aucun chapitre} =1{{count} chapitre} other{{count} chapitres}}'**
  String chaptersCount(num count);

  /// Message de succès pour la sauvegarde d'un chapitre
  ///
  /// In fr, this message translates to:
  /// **'Chapitre {chapter} enregistré'**
  String chapterSaved(String chapter);

  /// Statut d'un chapitre lu
  ///
  /// In fr, this message translates to:
  /// **'lu'**
  String get chapterRead;

  /// Statut d'un chapitre non lu
  ///
  /// In fr, this message translates to:
  /// **'non lu'**
  String get chapterUnread;

  /// Message de succès pour l'ajout à la bibliothèque
  ///
  /// In fr, this message translates to:
  /// **'{title} a été ajouté à la bibliothèque !'**
  String mangaAddedToLibrarySuccess(String title);

  /// Message d'erreur pour l'ajout à la bibliothèque
  ///
  /// In fr, this message translates to:
  /// **'Erreur lors de l\'ajout à la bibliothèque.'**
  String get errorAddingToLibrary;

  /// Message d'erreur pour la mise à jour d'un chapitre
  ///
  /// In fr, this message translates to:
  /// **'Erreur lors de la mise à jour du chapitre.'**
  String get errorUpdatingChapter;

  /// Message d'erreur pour l'ouverture d'un lien
  ///
  /// In fr, this message translates to:
  /// **'Impossible d\'ouvrir le lien : {url}'**
  String cannotOpenLink(String url);

  /// Titre pour l'historique de recherche
  ///
  /// In fr, this message translates to:
  /// **'Historique de recherche'**
  String get searchHistoryTitle;

  /// Message pour l'état vide de la recherche
  ///
  /// In fr, this message translates to:
  /// **'Recherchez un manga, manhwa ou manhua'**
  String get searchEmptyStateMessage;

  /// Bouton pour effacer l'historique de recherche
  ///
  /// In fr, this message translates to:
  /// **'Effacer'**
  String get clear;

  /// Titre de la page Recherche
  ///
  /// In fr, this message translates to:
  /// **'Rechercher'**
  String get searchTitle;

  /// Message affiché quand l'historique de recherche est vide
  ///
  /// In fr, this message translates to:
  /// **'Aucune recherche récente'**
  String get searchEmptyHistory;

  /// Titre de la section des genres populaires sur la page Recherche
  ///
  /// In fr, this message translates to:
  /// **'Genres populaires'**
  String get searchPopularGenres;

  /// Titre pour l'authentification biométrique
  ///
  /// In fr, this message translates to:
  /// **'Authentification biométrique'**
  String get biometricAuthTitle;

  /// Sous-titre pour l'authentification biométrique
  ///
  /// In fr, this message translates to:
  /// **'Utiliser l\'empreinte digitale ou le Face ID pour se connecter rapidement'**
  String get biometricAuthSubtitle;

  /// Message de succès pour l'activation de la biométrie
  ///
  /// In fr, this message translates to:
  /// **'Activer l\'authentification biométrique'**
  String get enableBiometricAuth;

  /// Message de succès pour la désactivation de la biométrie
  ///
  /// In fr, this message translates to:
  /// **'Authentification biométrique désactivée'**
  String get disableBiometricAuth;

  /// Statut activé pour la biométrie
  ///
  /// In fr, this message translates to:
  /// **'Activée'**
  String get biometricAuthEnabled;

  /// Statut désactivé pour la biométrie
  ///
  /// In fr, this message translates to:
  /// **'Désactivée'**
  String get biometricAuthDisabled;

  /// Titre de la dialog de première activation
  ///
  /// In fr, this message translates to:
  /// **'Activer l\'authentification biométrique ?'**
  String get biometricAuthFirstTimeTitle;

  /// Message de la dialog de première activation
  ///
  /// In fr, this message translates to:
  /// **'Souhaitez-vous utiliser votre empreinte digitale ou Face ID pour vous connecter rapidement à l\'avenir ?'**
  String get biometricAuthFirstTimeMessage;

  /// Message quand la biométrie n'est pas disponible
  ///
  /// In fr, this message translates to:
  /// **'L\'authentification biométrique n\'est pas disponible sur cet appareil'**
  String get biometricAuthNotAvailable;

  /// Message quand il faut se reconnecter pour activer la biométrie
  ///
  /// In fr, this message translates to:
  /// **'Pour activer l\'authentification biométrique, veuillez vous reconnecter'**
  String get biometricAuthRequiresReconnect;

  /// Séparateur entre connexion classique et OAuth
  ///
  /// In fr, this message translates to:
  /// **'Ou'**
  String get or;

  /// Message d'accueil sur la page d'inscription
  ///
  /// In fr, this message translates to:
  /// **'Commencez à suivre votre lecture maintenant'**
  String get startTrackingNow;

  /// Label pour le champ nom d'utilisateur
  ///
  /// In fr, this message translates to:
  /// **'Nom d\'utilisateur'**
  String get username;

  /// Label pour le champ de confirmation de mot de passe
  ///
  /// In fr, this message translates to:
  /// **'Confirmation'**
  String get confirmPassword;

  /// Message pour rediriger vers la page de connexion
  ///
  /// In fr, this message translates to:
  /// **'Vous avez déjà un compte ?'**
  String get alreadyHaveAccount;

  /// Label pour le champ nouveau mot de passe
  ///
  /// In fr, this message translates to:
  /// **'Nouveau mot de passe'**
  String get newPassword;

  /// Message d'erreur quand l'email est vide
  ///
  /// In fr, this message translates to:
  /// **'Veuillez entrer votre adresse e-mail'**
  String get validationEmailRequired;

  /// Message d'erreur quand l'email est invalide
  ///
  /// In fr, this message translates to:
  /// **'Veuillez entrer une adresse e-mail valide'**
  String get validationEmailInvalid;

  /// Message d'erreur quand le mot de passe est vide
  ///
  /// In fr, this message translates to:
  /// **'Veuillez entrer votre mot de passe'**
  String get validationPasswordRequired;

  /// Message d'erreur pour la longueur du mot de passe
  ///
  /// In fr, this message translates to:
  /// **'Votre mot de passe doit comporter entre 8 et 64 caractères'**
  String get validationPasswordLength;

  /// Message d'erreur pour la complexité du mot de passe
  ///
  /// In fr, this message translates to:
  /// **'Votre mot de passe doit contenir au moins une lettre minuscule, une lettre majuscule et un caractère spécial'**
  String get validationPasswordComplexity;

  /// Message d'erreur quand la confirmation de mot de passe est vide
  ///
  /// In fr, this message translates to:
  /// **'Veuillez confirmer votre mot de passe'**
  String get validationConfirmPasswordRequired;

  /// Message d'erreur quand les mots de passe ne correspondent pas
  ///
  /// In fr, this message translates to:
  /// **'Les mots de passe ne correspondent pas'**
  String get validationPasswordsDoNotMatch;

  /// Libellé pour afficher le mot de passe
  ///
  /// In fr, this message translates to:
  /// **'Afficher le mot de passe'**
  String get showPassword;

  /// Libellé pour masquer le mot de passe
  ///
  /// In fr, this message translates to:
  /// **'Masquer le mot de passe'**
  String get hidePassword;

  /// No description provided for @emailAlreadyUsed.
  ///
  /// In fr, this message translates to:
  /// **'Cette adresse e-mail est déjà utilisée'**
  String get emailAlreadyUsed;

  /// No description provided for @networkError.
  ///
  /// In fr, this message translates to:
  /// **'Veuillez vérifier votre connexion internet'**
  String get networkError;

  /// No description provided for @timeoutError.
  ///
  /// In fr, this message translates to:
  /// **'Le serveur met trop de temps à répondre. Veuillez réessayer.'**
  String get timeoutError;

  /// Libellé pour indiquer la robustesse du mot de passe
  ///
  /// In fr, this message translates to:
  /// **'Robustesse du mot de passe'**
  String get passwordStrengthLabel;

  /// No description provided for @passwordStrengthWeak.
  ///
  /// In fr, this message translates to:
  /// **'Faible'**
  String get passwordStrengthWeak;

  /// No description provided for @passwordStrengthMedium.
  ///
  /// In fr, this message translates to:
  /// **'Moyen'**
  String get passwordStrengthMedium;

  /// No description provided for @passwordStrengthStrong.
  ///
  /// In fr, this message translates to:
  /// **'Fort'**
  String get passwordStrengthStrong;

  /// Bouton de confirmation positive
  ///
  /// In fr, this message translates to:
  /// **'Oui'**
  String get yes;

  /// Bouton de confirmation négative
  ///
  /// In fr, this message translates to:
  /// **'Non'**
  String get no;

  /// Bouton pour valider la lecture
  ///
  /// In fr, this message translates to:
  /// **'Oui, valider'**
  String get yesValidate;

  /// Message pour le saut de chapitres
  ///
  /// In fr, this message translates to:
  /// **'Vous passez du chapitre {prev} au {next}.\nMarquer {prev} comme lu ?'**
  String chapterSkipMessage(String prev, String next);

  /// Message pour valider la lecture
  ///
  /// In fr, this message translates to:
  /// **'Avez-vous fini le chapitre {chapter} ?'**
  String validateReadingMessage(String chapter);

  /// Indice pour la validation de lecture
  ///
  /// In fr, this message translates to:
  /// **'Votre progression sera sauvegardée automatiquement.'**
  String get validateReadingHint;

  /// Titre de la popup du bloqueur de pub
  ///
  /// In fr, this message translates to:
  /// **'Bloqueur de publicités'**
  String get adBlockerTitle;

  /// Description du bloqueur de pub
  ///
  /// In fr, this message translates to:
  /// **'Le bloqueur de publicités bloque automatiquement les publicités sur les sites de lecture.\n\nSi vous souhaitez ajouter des liens ou suggérer des améliorations pour le blocage de publicités, rejoignez notre serveur Discord !'**
  String get adBlockerDescription;

  /// Tooltip pour l'icône d'info du bloqueur
  ///
  /// In fr, this message translates to:
  /// **'Informations sur le bloqueur de pub'**
  String get adBlockerTooltip;

  /// Bouton pour rejoindre Discord
  ///
  /// In fr, this message translates to:
  /// **'Rejoindre Discord'**
  String get joinDiscord;

  /// Sous-titre pour rejoindre Discord
  ///
  /// In fr, this message translates to:
  /// **'Partagez vos suggestions et signalez des problèmes'**
  String get joinDiscordSubtitle;

  /// Section nous contacter
  ///
  /// In fr, this message translates to:
  /// **'Nous contacter'**
  String get contactUs;

  /// Titre de la section téléchargements
  ///
  /// In fr, this message translates to:
  /// **'Téléchargements'**
  String get downloads;

  /// Titre pour gérer les téléchargements
  ///
  /// In fr, this message translates to:
  /// **'Gérer les téléchargements'**
  String get manageDownloads;

  /// Sous-titre pour gérer les téléchargements
  ///
  /// In fr, this message translates to:
  /// **'Voir et supprimer les chapitres téléchargés'**
  String get manageDownloadsSubtitle;

  /// Erreur lors de l'ouverture du lien Discord
  ///
  /// In fr, this message translates to:
  /// **'Impossible d\'ouvrir le lien Discord'**
  String get discordLinkError;

  /// Message de succès pour la copie d'URL
  ///
  /// In fr, this message translates to:
  /// **'URL copiée dans le presse-papiers'**
  String get urlCopied;

  /// Message d'erreur pour la copie d'URL
  ///
  /// In fr, this message translates to:
  /// **'Erreur lors de la copie de l\'URL'**
  String get urlCopyError;

  /// Tooltip pour le bouton de copie d'URL
  ///
  /// In fr, this message translates to:
  /// **'Copier l\'URL'**
  String get copyUrl;

  /// Message de succès pour la mise à jour de progression
  ///
  /// In fr, this message translates to:
  /// **'Progression mise à jour'**
  String get progressUpdated;

  /// Message d'erreur pour une URL invalide
  ///
  /// In fr, this message translates to:
  /// **'URL invalide'**
  String get invalidUrl;

  /// Titre pour le mode web de suivi de progression
  ///
  /// In fr, this message translates to:
  /// **'Mode Web - Suivi de progression'**
  String get webModeProgressTracking;

  /// Description pour le mode web de suivi de progression
  ///
  /// In fr, this message translates to:
  /// **'Pour suivre votre progression, collez l\'URL du chapitre que vous êtes en train de lire.'**
  String get webModeProgressDescription;

  /// Label pour le champ URL du chapitre
  ///
  /// In fr, this message translates to:
  /// **'URL du chapitre'**
  String get chapterUrlLabel;

  /// Bouton pour mettre à jour la progression
  ///
  /// In fr, this message translates to:
  /// **'Mettre à jour la progression'**
  String get updateProgress;

  /// Bouton pour ouvrir dans un nouvel onglet
  ///
  /// In fr, this message translates to:
  /// **'Ouvrir dans un nouvel onglet'**
  String get openInNewTab;

  /// Label pour le champ URL du lien
  ///
  /// In fr, this message translates to:
  /// **'URL du site de scan'**
  String get linkUrlLabel;

  /// Titre pour l'information sur le format de chapitre
  ///
  /// In fr, this message translates to:
  /// **'Format de chapitre requis'**
  String get linkFormatInfo;

  /// Description des formats de chapitre acceptés
  ///
  /// In fr, this message translates to:
  /// **'Incluez le numéro de chapitre dans l\'URL pour permettre la sauvegarde automatique de progression.\n\nFormats acceptés :\n• /chapitre-23/ ou /chapter-23/\n• /c23/ ou /ch23/\n• /ep-23/ ou /episode-23/\n• ?chapter=23 ou ?num=24'**
  String get linkFormatDescription;

  /// Avertissement quand aucun format de chapitre n'est détecté
  ///
  /// In fr, this message translates to:
  /// **'Aucun format de chapitre détecté. Le lien redirigera vers la page du manga (pas un chapitre spécifique).'**
  String get linkFormatWarning;

  /// Message de confirmation quand un format de chapitre est détecté
  ///
  /// In fr, this message translates to:
  /// **'Format de chapitre détecté ! La progression sera sauvegardée automatiquement.'**
  String get linkFormatDetected;

  /// Lien pour ajouter un pattern personnalisé
  ///
  /// In fr, this message translates to:
  /// **'Ajouter un pattern personnalisé pour ce format'**
  String get linkAddCustomPattern;

  /// Titre pour la section des sélecteurs personnalisés
  ///
  /// In fr, this message translates to:
  /// **'Sélecteurs personnalisés'**
  String get customSelectors;

  /// Option pour gérer les sélecteurs personnalisés
  ///
  /// In fr, this message translates to:
  /// **'Gérer les sélecteurs'**
  String get manageCustomSelectors;

  /// Sous-titre pour gérer les sélecteurs
  ///
  /// In fr, this message translates to:
  /// **'Ajoutez des sélecteurs CSS personnalisés pour bloquer des publicités ou identifier le contenu'**
  String get manageCustomSelectorsSubtitle;

  /// Titre pour ajouter un sélecteur
  ///
  /// In fr, this message translates to:
  /// **'Ajouter un sélecteur'**
  String get addCustomSelector;

  /// Label pour le champ domaine
  ///
  /// In fr, this message translates to:
  /// **'Domaine (ex: exemple.com)'**
  String get selectorDomainLabel;

  /// Label pour le champ sélecteur CSS
  ///
  /// In fr, this message translates to:
  /// **'Sélecteur CSS'**
  String get selectorCssLabel;

  /// Label pour le type de sélecteur
  ///
  /// In fr, this message translates to:
  /// **'Type de sélecteur'**
  String get selectorTypeLabel;

  /// Type de sélecteur : pattern d'URL
  ///
  /// In fr, this message translates to:
  /// **'Pattern d\'URL'**
  String get selectorTypeUrlPattern;

  /// Label pour le champ pattern d'URL
  ///
  /// In fr, this message translates to:
  /// **'Pattern d\'URL (regex)'**
  String get selectorUrlPatternLabel;

  /// Hint pour le champ pattern d'URL
  ///
  /// In fr, this message translates to:
  /// **'Exemple : /chapter-(\\d+)/ pour détecter /chapter-22'**
  String get selectorUrlPatternHint;

  /// Titre pour les exemples de patterns d'URL
  ///
  /// In fr, this message translates to:
  /// **'Exemples de patterns d\'URL :'**
  String get selectorExamplesUrlPattern;

  /// Titre de l'exemple pattern d'URL
  ///
  /// In fr, this message translates to:
  /// **'Exemple : /chapter-22'**
  String get selectorExampleUrlPattern;

  /// Explication de l'exemple pattern d'URL
  ///
  /// In fr, this message translates to:
  /// **'Si votre site utilise \"/chapter-22\" dans l\'URL et que le système ne le détecte pas automatiquement :'**
  String get selectorExampleUrlPatternExplanation;

  /// Description détaillée de l'exemple pattern d'URL
  ///
  /// In fr, this message translates to:
  /// **'Utilisez une expression régulière (regex) avec (\\d+) pour capturer le numéro du chapitre.\n\nCe pattern sera appliqué à TOUS les sites.\n\nExemples de patterns :\n• /chapter-(\\d+)/ → détecte /chapter-22\n• /chapppter-(\\d+)/ → détecte /chapppter-22 (avec 3 p)\n• /manga/chapter-(\\d+)/ → détecte /manga/chapter-22\n• /episode-(\\d+)/ → détecte /episode-22'**
  String get selectorUrlPatternExampleDesc;

  /// Message expliquant que le pattern est global
  ///
  /// In fr, this message translates to:
  /// **'ℹ️ Le pattern sera appliqué à TOUS les sites. Pas besoin de spécifier un domaine.'**
  String get selectorUrlPatternGlobal;

  /// Type de sélecteur : bloqueur de pub
  ///
  /// In fr, this message translates to:
  /// **'Bloqueur de publicités'**
  String get selectorTypeAdBlocker;

  /// Type de sélecteur : contenu du chapitre
  ///
  /// In fr, this message translates to:
  /// **'Contenu du chapitre'**
  String get selectorTypeChapterContent;

  /// Label pour la description du sélecteur
  ///
  /// In fr, this message translates to:
  /// **'Description (optionnel)'**
  String get selectorDescriptionLabel;

  /// Placeholder pour la description
  ///
  /// In fr, this message translates to:
  /// **'Description du sélecteur'**
  String get selectorDescriptionHint;

  /// Message d'erreur pour les champs requis
  ///
  /// In fr, this message translates to:
  /// **'Tous les champs sont requis'**
  String get selectorRequiredFields;

  /// Message de succès pour l'ajout d'un sélecteur
  ///
  /// In fr, this message translates to:
  /// **'Sélecteur ajouté'**
  String get selectorAdded;

  /// Titre pour supprimer un sélecteur
  ///
  /// In fr, this message translates to:
  /// **'Supprimer le sélecteur'**
  String get deleteSelector;

  /// Message de confirmation pour supprimer un sélecteur
  ///
  /// In fr, this message translates to:
  /// **'Êtes-vous sûr de vouloir supprimer ce sélecteur ?'**
  String get deleteSelectorConfirm;

  /// Message de succès pour la suppression d'un sélecteur
  ///
  /// In fr, this message translates to:
  /// **'Sélecteur supprimé'**
  String get selectorDeleted;

  /// Message de succès pour l'export des sélecteurs
  ///
  /// In fr, this message translates to:
  /// **'Sélecteurs exportés dans le presse-papiers'**
  String get selectorsExported;

  /// Titre pour importer des sélecteurs
  ///
  /// In fr, this message translates to:
  /// **'Importer des sélecteurs'**
  String get importSelectors;

  /// Label pour le champ JSON
  ///
  /// In fr, this message translates to:
  /// **'JSON des sélecteurs'**
  String get selectorsJsonLabel;

  /// Bouton pour importer
  ///
  /// In fr, this message translates to:
  /// **'Importer'**
  String get import;

  /// Message de succès pour l'import des sélecteurs
  ///
  /// In fr, this message translates to:
  /// **'{count} sélecteur(s) importé(s)'**
  String selectorsImported(String count);

  /// Message pour le partage des sélecteurs
  ///
  /// In fr, this message translates to:
  /// **'Sélecteurs prêts à être partagés ! Collez le JSON dans Discord.'**
  String get selectorsReadyToShare;

  /// Bouton pour exporter
  ///
  /// In fr, this message translates to:
  /// **'Exporter'**
  String get exportSelectors;

  /// Bouton pour partager
  ///
  /// In fr, this message translates to:
  /// **'Partager'**
  String get shareSelectors;

  /// Message quand il n'y a pas de sélecteurs
  ///
  /// In fr, this message translates to:
  /// **'Aucun sélecteur personnalisé'**
  String get noCustomSelectors;

  /// Message pour ajouter le premier sélecteur
  ///
  /// In fr, this message translates to:
  /// **'Ajoutez votre premier sélecteur pour commencer'**
  String get addFirstSelector;

  /// Titre pour la section d'exemples
  ///
  /// In fr, this message translates to:
  /// **'Exemples'**
  String get selectorExamples;

  /// Titre pour les exemples de bloqueur de pub
  ///
  /// In fr, this message translates to:
  /// **'Exemples pour bloquer des publicités :'**
  String get selectorExamplesAdBlocker;

  /// Exemple 1 pour bloqueur de pub
  ///
  /// In fr, this message translates to:
  /// **'Bannière publicitaire'**
  String get selectorExampleAd1;

  /// Exemple 2 pour bloqueur de pub
  ///
  /// In fr, this message translates to:
  /// **'Publicité par ID'**
  String get selectorExampleAd2;

  /// Exemple 3 pour bloqueur de pub
  ///
  /// In fr, this message translates to:
  /// **'Iframe publicitaire'**
  String get selectorExampleAd3;

  /// Exemple 4 pour bloqueur de pub
  ///
  /// In fr, this message translates to:
  /// **'Script publicitaire'**
  String get selectorExampleAd4;

  /// Titre pour les exemples de contenu de chapitre
  ///
  /// In fr, this message translates to:
  /// **'Exemples pour identifier le contenu du chapitre :'**
  String get selectorExamplesChapter;

  /// Exemple 1 pour contenu de chapitre
  ///
  /// In fr, this message translates to:
  /// **'Conteneur de chapitre'**
  String get selectorExampleChapter1;

  /// Exemple 2 pour contenu de chapitre
  ///
  /// In fr, this message translates to:
  /// **'Lecteur de manga'**
  String get selectorExampleChapter2;

  /// Exemple 3 pour contenu de chapitre
  ///
  /// In fr, this message translates to:
  /// **'Images du chapitre'**
  String get selectorExampleChapter3;

  /// Exemple 4 pour contenu de chapitre
  ///
  /// In fr, this message translates to:
  /// **'Contenu de lecture'**
  String get selectorExampleChapter4;

  /// Exemple 5 pour contenu de chapitre avec format manga/chapitre
  ///
  /// In fr, this message translates to:
  /// **'Format manga/chapitre-22'**
  String get selectorExampleChapter5;

  /// Explication de l'exemple manga/chapitre-22
  ///
  /// In fr, this message translates to:
  /// **'Exemple concret : Si votre URL est \"monsite.com/manga/chapitre-22\"'**
  String get selectorExampleChapter5Explanation;

  /// Message expliquant que le format URL est déjà détecté
  ///
  /// In fr, this message translates to:
  /// **'✅ BONNE NOUVELLE : Le format \"/manga/chapitre-22\" dans l\'URL est déjà détecté automatiquement par le système !\n\nVous n\'avez PAS besoin d\'ajouter un sélecteur CSS si votre site utilise uniquement ce format dans l\'URL.'**
  String get selectorUrlFormatDetected;

  /// Titre pour expliquer quand ajouter un sélecteur
  ///
  /// In fr, this message translates to:
  /// **'Quand ajouter un sélecteur CSS ?'**
  String get selectorWhenNeeded;

  /// Titre pour l'exemple pratique
  ///
  /// In fr, this message translates to:
  /// **'Exemple pratique :'**
  String get selectorPracticalExample;

  /// Scénario d'exemple avec format non détecté
  ///
  /// In fr, this message translates to:
  /// **'Cas : Votre site utilise \"/chapppter-22\" (avec 3 p) au lieu de \"/chapter-22\"'**
  String get selectorExampleScenario;

  /// Étape 1 de l'exemple
  ///
  /// In fr, this message translates to:
  /// **'Ouvrez la page du chapitre dans votre navigateur'**
  String get selectorStep1;

  /// Étape 2 de l'exemple
  ///
  /// In fr, this message translates to:
  /// **'Appuyez sur F12 pour ouvrir les outils de développement'**
  String get selectorStep2;

  /// Étape 3 de l'exemple
  ///
  /// In fr, this message translates to:
  /// **'Cliquez sur l\'icône \"Inspecter\" (ou Ctrl+Shift+C)'**
  String get selectorStep3;

  /// Étape 4 de l'exemple
  ///
  /// In fr, this message translates to:
  /// **'Cliquez sur le conteneur qui contient les images du chapitre'**
  String get selectorStep4;

  /// Étape 5 de l'exemple
  ///
  /// In fr, this message translates to:
  /// **'Dans le code HTML, trouvez la classe ou l\'ID du conteneur'**
  String get selectorStep5;

  /// Titre pour remplir le formulaire
  ///
  /// In fr, this message translates to:
  /// **'Remplissez le formulaire :'**
  String get selectorFillForm;

  /// Description expliquant quand ajouter un sélecteur CSS
  ///
  /// In fr, this message translates to:
  /// **'⚠️ UNIQUEMENT si votre site a besoin d\'un sélecteur spécifique pour identifier le contenu HTML de la page.\n\nSi le système détecte déjà bien votre chapitre via l\'URL, vous n\'avez PAS besoin d\'ajouter un sélecteur CSS.\n\nAjoutez un sélecteur CSS SEULEMENT si :\n• Le système ne détecte pas correctement le contenu du chapitre\n• Vous voulez bloquer des publicités spécifiques à ce site\n• Le site utilise des classes/IDs particuliers pour le contenu\n\nPour trouver le sélecteur : Ouvrez la page (F12 → Inspecter), trouvez le conteneur des images du chapitre, et utilisez sa classe ou ID (ex: .manga-content, #chapter-images)'**
  String get selectorCssWhenNeededDesc;

  /// No description provided for @selectorDomainExampleDesc.
  ///
  /// In fr, this message translates to:
  /// **'Mettez uniquement le nom de domaine (sans http://, sans www, sans le chemin /manga/chapitre-22)'**
  String get selectorDomainExampleDesc;

  /// Titre pour les autres exemples
  ///
  /// In fr, this message translates to:
  /// **'Autres exemples courants :'**
  String get selectorOtherExamples;

  /// Description détaillée de l'exemple manga/chapitre-22
  ///
  /// In fr, this message translates to:
  /// **'Pour les sites utilisant le format manga/chapitre-22 dans leurs URLs. Exemple : si votre URL est \"site.com/manga/chapitre-22\", utilisez ces sélecteurs pour identifier le contenu.'**
  String get selectorExampleChapter5Desc;

  /// Astuce pour trouver les sélecteurs CSS
  ///
  /// In fr, this message translates to:
  /// **'Astuce : Utilisez les outils de développement de votre navigateur (F12) pour inspecter les éléments et trouver les sélecteurs CSS appropriés.'**
  String get selectorExamplesHint;

  /// Message quand un captcha est détecté
  ///
  /// In fr, this message translates to:
  /// **'Captcha détecté - Le bloqueur de pub a été temporairement désactivé'**
  String get captchaDetected;

  /// Message quand un captcha est résolu
  ///
  /// In fr, this message translates to:
  /// **'Captcha résolu - Le bloqueur de pub a été réactivé'**
  String get captchaResolved;

  /// Message de confirmation pour la sauvegarde de la position de scroll
  ///
  /// In fr, this message translates to:
  /// **'Position de scroll sauvegardée'**
  String get scrollPositionSaved;

  /// Message de confirmation pour la sauvegarde de progression
  ///
  /// In fr, this message translates to:
  /// **'Progression du chapitre sauvegardée'**
  String get chapterProgressSaved;

  /// Titre pour la lecture hors ligne
  ///
  /// In fr, this message translates to:
  /// **'Lecture hors ligne'**
  String get readingOffline;

  /// Message indiquant qu'un chapitre est téléchargé
  ///
  /// In fr, this message translates to:
  /// **'Chapitre téléchargé'**
  String get chapterDownloaded;

  /// Description du mode lecture hors ligne
  ///
  /// In fr, this message translates to:
  /// **'Mode lecture hors ligne'**
  String get offlineReadingMode;

  /// Titre de la boîte de dialogue pour supprimer un chapitre
  ///
  /// In fr, this message translates to:
  /// **'Supprimer le chapitre'**
  String get deleteChapterTitle;

  /// Message de confirmation pour supprimer un chapitre
  ///
  /// In fr, this message translates to:
  /// **'Voulez-vous vraiment supprimer le chapitre {chapterNumber} ?'**
  String deleteChapterMessage(int chapterNumber);

  /// Titre de la boîte de dialogue pour supprimer tous les chapitres d'un manga
  ///
  /// In fr, this message translates to:
  /// **'Supprimer tous les chapitres'**
  String get deleteAllChaptersTitle;

  /// Message de confirmation pour supprimer tous les chapitres d'un manga
  ///
  /// In fr, this message translates to:
  /// **'Voulez-vous vraiment supprimer tous les chapitres téléchargés pour ce manga ?'**
  String get deleteAllChaptersMessage;

  /// Titre de la boîte de dialogue pour supprimer tous les téléchargements
  ///
  /// In fr, this message translates to:
  /// **'Supprimer tous les téléchargements'**
  String get deleteAllDownloadsTitle;

  /// Message de confirmation pour supprimer tous les téléchargements
  ///
  /// In fr, this message translates to:
  /// **'Voulez-vous vraiment supprimer TOUS les téléchargements ? Cette action est irréversible.'**
  String get deleteAllDownloadsMessage;

  /// Bouton pour tout supprimer
  ///
  /// In fr, this message translates to:
  /// **'Supprimer tout'**
  String get deleteAll;

  /// Message de succès après suppression d'un chapitre
  ///
  /// In fr, this message translates to:
  /// **'Chapitre supprimé'**
  String get chapterDeleted;

  /// Message de succès après suppression de tous les chapitres d'un manga
  ///
  /// In fr, this message translates to:
  /// **'Tous les chapitres supprimés'**
  String get allChaptersDeleted;

  /// Message de succès après suppression de tous les téléchargements
  ///
  /// In fr, this message translates to:
  /// **'Tous les téléchargements supprimés'**
  String get allDownloadsDeleted;

  /// Message affiché quand aucun chapitre n'est téléchargé
  ///
  /// In fr, this message translates to:
  /// **'Aucun chapitre téléchargé'**
  String get noChaptersDownloaded;

  /// Nombre de chapitres téléchargés
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =0{Aucun chapitre téléchargé} =1{1 chapitre téléchargé} other{{count} chapitres téléchargés}}'**
  String chaptersDownloadedCount(int count);

  /// Bouton pour lire un chapitre
  ///
  /// In fr, this message translates to:
  /// **'Lire'**
  String get readChapter;

  /// Action pour supprimer tous les chapitres d'un manga
  ///
  /// In fr, this message translates to:
  /// **'Supprimer tous les chapitres'**
  String get deleteAllChaptersAction;

  /// Tooltip pour le bouton de suppression de tous les téléchargements
  ///
  /// In fr, this message translates to:
  /// **'Supprimer tous les téléchargements'**
  String get deleteAllDownloadsTooltip;

  /// Section de recommandations personnalisées de manga
  ///
  /// In fr, this message translates to:
  /// **'Recommandé pour toi'**
  String get recommendedForYou;

  /// Message affiché dans la section recommandations quand la bibliothèque est vide
  ///
  /// In fr, this message translates to:
  /// **'Ajoutez des mangas à votre bibliothèque\npour obtenir des recommandations personnalisées.'**
  String get recommendedForYouEmpty;

  /// Sous-titre indiquant le nombre de mangas recommandés
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =1{1 manga} other{{count} mangas}}'**
  String recommendedForYouCount(int count);

  /// Indicateur affiché quand les recommandations affichées proviennent du cache offline
  ///
  /// In fr, this message translates to:
  /// **'Recommandations en cache (mode hors ligne)'**
  String get recommendedForYouCached;

  /// Préfixe générique d'erreur avec un message technique
  ///
  /// In fr, this message translates to:
  /// **'Erreur : {message}'**
  String errorWithMessage(String message);

  /// Explication d'une recommandation, listant les mangas sources
  ///
  /// In fr, this message translates to:
  /// **'Parce que vous avez aimé {titles}'**
  String recommendedBecauseOf(String titles);

  /// Label affiché à côté du widget de notation utilisateur dans le détail manga
  ///
  /// In fr, this message translates to:
  /// **'Votre note'**
  String get yourRating;

  /// No description provided for @myDataTitle.
  ///
  /// In fr, this message translates to:
  /// **'Mes données'**
  String get myDataTitle;

  /// No description provided for @myDataSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Voir, exporter ou supprimer mes données (RGPD)'**
  String get myDataSubtitle;

  /// No description provided for @gdprIntro.
  ///
  /// In fr, this message translates to:
  /// **'Conformément au RGPD, vous disposez de droits sur vos données personnelles. Cette page vous permet de les exercer simplement.'**
  String get gdprIntro;

  /// No description provided for @gdprAccessTitle.
  ///
  /// In fr, this message translates to:
  /// **'Voir mes données'**
  String get gdprAccessTitle;

  /// No description provided for @gdprAccessSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Article 15 — résumé des informations stockées'**
  String get gdprAccessSubtitle;

  /// No description provided for @gdprExportTitle.
  ///
  /// In fr, this message translates to:
  /// **'Exporter mes données'**
  String get gdprExportTitle;

  /// No description provided for @gdprExportSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Article 20 — JSON complet copié dans le presse-papier'**
  String get gdprExportSubtitle;

  /// No description provided for @gdprLegalDocs.
  ///
  /// In fr, this message translates to:
  /// **'Documents légaux'**
  String get gdprLegalDocs;

  /// No description provided for @gdprDeleteHint.
  ///
  /// In fr, this message translates to:
  /// **'Pour supprimer définitivement votre compte, rendez-vous dans Profil → Supprimer mon compte. Cette action est irréversible.'**
  String get gdprDeleteHint;

  /// No description provided for @privacyPolicyTitle.
  ///
  /// In fr, this message translates to:
  /// **'Politique de confidentialité'**
  String get privacyPolicyTitle;

  /// No description provided for @termsOfServiceTitle.
  ///
  /// In fr, this message translates to:
  /// **'Conditions d\'utilisation'**
  String get termsOfServiceTitle;

  /// No description provided for @myDataInfoBanner.
  ///
  /// In fr, this message translates to:
  /// **'Conformément au RGPD, vous avez le droit d\'accéder à vos données, de les exporter et de demander leur suppression.'**
  String get myDataInfoBanner;

  /// No description provided for @myDataSectionPersonalData.
  ///
  /// In fr, this message translates to:
  /// **'Données personnelles'**
  String get myDataSectionPersonalData;

  /// No description provided for @myDataSectionMyRights.
  ///
  /// In fr, this message translates to:
  /// **'Mes droits'**
  String get myDataSectionMyRights;

  /// No description provided for @myDataSectionDeletion.
  ///
  /// In fr, this message translates to:
  /// **'Suppression'**
  String get myDataSectionDeletion;

  /// No description provided for @myDataSummaryTitle.
  ///
  /// In fr, this message translates to:
  /// **'Résumé de mes données'**
  String get myDataSummaryTitle;

  /// No description provided for @myDataSummarySubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Voir un aperçu de mes données stockées'**
  String get myDataSummarySubtitle;

  /// No description provided for @myDataExportSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Télécharger un fichier JSON complet (article 20)'**
  String get myDataExportSubtitle;

  /// No description provided for @privacyPolicySubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Lire le document complet'**
  String get privacyPolicySubtitle;

  /// No description provided for @termsOfServiceSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Voir les CGU'**
  String get termsOfServiceSubtitle;

  /// No description provided for @myDataDeleteAccountSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Action irréversible'**
  String get myDataDeleteAccountSubtitle;

  /// No description provided for @gdprExportSuccessSnack.
  ///
  /// In fr, this message translates to:
  /// **'Vos données ont été copiées dans le presse-papier (JSON).'**
  String get gdprExportSuccessSnack;

  /// No description provided for @gdprExportFailedSnack.
  ///
  /// In fr, this message translates to:
  /// **'Échec de l\'export'**
  String get gdprExportFailedSnack;

  /// No description provided for @gdprSummaryLoadFailed.
  ///
  /// In fr, this message translates to:
  /// **'Erreur de chargement'**
  String get gdprSummaryLoadFailed;

  /// No description provided for @myDataBackLabel.
  ///
  /// In fr, this message translates to:
  /// **'Profil'**
  String get myDataBackLabel;

  /// No description provided for @tosShortVersion.
  ///
  /// In fr, this message translates to:
  /// **'Manga Tracker est fourni en l\'état, sans garantie. L\'éditeur décline toute responsabilité pour l\'utilisation non conforme par l\'utilisateur (contenu illégal, scraping, etc.).\n\nDocument complet sur le site officiel.'**
  String get tosShortVersion;

  /// No description provided for @privacyShortVersion.
  ///
  /// In fr, this message translates to:
  /// **'Données collectées : email, mot de passe (hashé), bibliothèque manga, préférences. Aucune donnée n\'est vendue à des tiers. Vous pouvez exporter ou supprimer vos données à tout moment.\n\nDocument complet sur le site officiel.'**
  String get privacyShortVersion;

  /// No description provided for @iAcceptTos.
  ///
  /// In fr, this message translates to:
  /// **'J\'accepte les Conditions d\'utilisation'**
  String get iAcceptTos;

  /// No description provided for @iAcceptPrivacy.
  ///
  /// In fr, this message translates to:
  /// **'J\'accepte la Politique de confidentialité'**
  String get iAcceptPrivacy;

  /// No description provided for @iAccept.
  ///
  /// In fr, this message translates to:
  /// **'Accepter'**
  String get iAccept;

  /// No description provided for @consentRequired.
  ///
  /// In fr, this message translates to:
  /// **'Vous devez accepter les CGU et la Politique de confidentialité.'**
  String get consentRequired;

  /// No description provided for @consentRefreshTitle.
  ///
  /// In fr, this message translates to:
  /// **'Mise à jour de nos conditions'**
  String get consentRefreshTitle;

  /// No description provided for @consentRefreshIntro.
  ///
  /// In fr, this message translates to:
  /// **'Nos conditions d\'utilisation et notre politique de confidentialité ont été mises à jour. Veuillez les accepter pour continuer.'**
  String get consentRefreshIntro;

  /// No description provided for @refuseAndLogout.
  ///
  /// In fr, this message translates to:
  /// **'Refuser et se déconnecter'**
  String get refuseAndLogout;

  /// No description provided for @versionLabel.
  ///
  /// In fr, this message translates to:
  /// **'Version'**
  String get versionLabel;

  /// Titre de la hero sur la page de login
  ///
  /// In fr, this message translates to:
  /// **'Bienvenue !'**
  String get welcomeTitle;

  /// Sous-titre de la hero sur la page de login
  ///
  /// In fr, this message translates to:
  /// **'Connectez-vous à votre compte'**
  String get loginSubtitle;

  /// Titre de la hero sur la page d'inscription
  ///
  /// In fr, this message translates to:
  /// **'Créer un compte'**
  String get createAccountTitle;

  /// Sous-titre de la hero sur la page d'inscription
  ///
  /// In fr, this message translates to:
  /// **'Commencez à suivre vos lectures'**
  String get registerSubtitle;

  /// Texte du séparateur avant les boutons OAuth sur la page de login
  ///
  /// In fr, this message translates to:
  /// **'ou se connecter avec'**
  String get orLoginWith;

  /// Texte du séparateur avant les boutons OAuth sur la page d'inscription
  ///
  /// In fr, this message translates to:
  /// **'ou s\'inscrire avec'**
  String get orSignUpWith;

  /// Label du bouton de connexion Apple
  ///
  /// In fr, this message translates to:
  /// **'Continuer avec Apple'**
  String get continueWithApple;

  /// Label affiché sur la page de démarrage pendant le chargement
  ///
  /// In fr, this message translates to:
  /// **'Chargement…'**
  String get loadingApp;

  /// No description provided for @forgotPasswordTitle.
  ///
  /// In fr, this message translates to:
  /// **'Mot de passe oublié'**
  String get forgotPasswordTitle;

  /// No description provided for @forgotPasswordIntro.
  ///
  /// In fr, this message translates to:
  /// **'Entrez votre email. Si un compte existe, vous recevrez un lien pour définir un nouveau mot de passe.'**
  String get forgotPasswordIntro;

  /// No description provided for @sendResetLink.
  ///
  /// In fr, this message translates to:
  /// **'Envoyer le lien'**
  String get sendResetLink;

  /// No description provided for @resetEmailSentTitle.
  ///
  /// In fr, this message translates to:
  /// **'Vérifiez votre boîte mail'**
  String get resetEmailSentTitle;

  /// No description provided for @resetEmailSentMessage.
  ///
  /// In fr, this message translates to:
  /// **'Si un compte existe pour {email}, un email contenant un lien pour définir un nouveau mot de passe vient d\'être envoyé.\n\nLe lien expire dans 30 minutes.'**
  String resetEmailSentMessage(String email);

  /// No description provided for @resetPasswordTitle.
  ///
  /// In fr, this message translates to:
  /// **'Nouveau mot de passe'**
  String get resetPasswordTitle;

  /// No description provided for @resetPasswordIntro.
  ///
  /// In fr, this message translates to:
  /// **'Définissez un nouveau mot de passe pour votre compte. Une fois validé, vous serez automatiquement connecté.'**
  String get resetPasswordIntro;

  /// No description provided for @confirmReset.
  ///
  /// In fr, this message translates to:
  /// **'Confirmer'**
  String get confirmReset;

  /// No description provided for @resetTokenExpired.
  ///
  /// In fr, this message translates to:
  /// **'Lien invalide ou expiré. Refaites une demande.'**
  String get resetTokenExpired;

  /// No description provided for @resetPasswordSuccess.
  ///
  /// In fr, this message translates to:
  /// **'Mot de passe modifié'**
  String get resetPasswordSuccess;

  /// No description provided for @resetPasswordSuccessHint.
  ///
  /// In fr, this message translates to:
  /// **'Vous êtes maintenant connecté. Redirection en cours…'**
  String get resetPasswordSuccessHint;

  /// No description provided for @verifyingEmail.
  ///
  /// In fr, this message translates to:
  /// **'Vérification en cours…'**
  String get verifyingEmail;

  /// No description provided for @emailVerifiedSuccess.
  ///
  /// In fr, this message translates to:
  /// **'Email vérifié !'**
  String get emailVerifiedSuccess;

  /// No description provided for @emailVerifiedHint.
  ///
  /// In fr, this message translates to:
  /// **'Connexion en cours…'**
  String get emailVerifiedHint;

  /// No description provided for @emailVerifyFailedTitle.
  ///
  /// In fr, this message translates to:
  /// **'Lien invalide ou expiré'**
  String get emailVerifyFailedTitle;

  /// No description provided for @emailVerifyFailedHint.
  ///
  /// In fr, this message translates to:
  /// **'Le lien que vous avez utilisé n\'est plus valide. Connectez-vous et demandez un nouveau lien depuis votre profil.'**
  String get emailVerifyFailedHint;

  /// No description provided for @backToLogin.
  ///
  /// In fr, this message translates to:
  /// **'Retour à la connexion'**
  String get backToLogin;

  /// No description provided for @verifyEmailBannerMessage.
  ///
  /// In fr, this message translates to:
  /// **'Vérifiez votre adresse email pour activer toutes les fonctionnalités.'**
  String get verifyEmailBannerMessage;

  /// No description provided for @emailSentShort.
  ///
  /// In fr, this message translates to:
  /// **'Envoyé'**
  String get emailSentShort;

  /// No description provided for @resendEmailShort.
  ///
  /// In fr, this message translates to:
  /// **'Renvoyer'**
  String get resendEmailShort;

  /// Titre du carrousel court de recommandations sur la home
  ///
  /// In fr, this message translates to:
  /// **'Recommandés pour vous'**
  String get recommendedForYouHome;

  /// Bouton sur la home qui ouvre la page de recommandations par genre
  ///
  /// In fr, this message translates to:
  /// **'Voir plus par genre'**
  String get seeMoreByGenre;

  /// Titre de la page listant les recommandations regroupées par genre
  ///
  /// In fr, this message translates to:
  /// **'Recommandations par genre'**
  String get recommendationsByGenreTitle;

  /// Message d'état vide sur la page de recommandations par genre
  ///
  /// In fr, this message translates to:
  /// **'Pas encore de recommandations. Ajoutez des mangas à votre bibliothèque pour en obtenir.'**
  String get recommendationsByGenreEmpty;

  /// Titre de la page paginée listant toutes les recommandations
  ///
  /// In fr, this message translates to:
  /// **'Toutes les recommandations'**
  String get recommendationsAllTitle;

  /// Message d'état vide sur la page paginée des recommandations
  ///
  /// In fr, this message translates to:
  /// **'Pas encore de recommandations pour vous.'**
  String get recommendationsAllEmpty;

  /// Bouton sur la home qui ouvre la page paginée des recommandations
  ///
  /// In fr, this message translates to:
  /// **'Tout voir'**
  String get seeAllRecommendations;

  /// Action AppBar de la page paginée qui ouvre la vue par genre
  ///
  /// In fr, this message translates to:
  /// **'Par genre'**
  String get browseByGenre;

  /// No description provided for @recommendationsTabAll.
  ///
  /// In fr, this message translates to:
  /// **'Tout'**
  String get recommendationsTabAll;

  /// No description provided for @recommendationsTabByGenre.
  ///
  /// In fr, this message translates to:
  /// **'Par genre'**
  String get recommendationsTabByGenre;

  /// Titre de la page Statistiques (Phase 2)
  ///
  /// In fr, this message translates to:
  /// **'Mes statistiques'**
  String get statsTitle;

  /// Label sous le compteur total de mangas
  ///
  /// In fr, this message translates to:
  /// **'mangas dans votre bibliothèque'**
  String get statsTotalMangas;

  /// Date de création du compte
  ///
  /// In fr, this message translates to:
  /// **'Membre depuis {date}'**
  String statsMemberSince(String date);

  /// No description provided for @statsTotalChapters.
  ///
  /// In fr, this message translates to:
  /// **'Chapitres lus'**
  String get statsTotalChapters;

  /// No description provided for @statsReadingTime.
  ///
  /// In fr, this message translates to:
  /// **'Temps de lecture estimé'**
  String get statsReadingTime;

  /// No description provided for @statsCompletionRate.
  ///
  /// In fr, this message translates to:
  /// **'Taux de complétion'**
  String get statsCompletionRate;

  /// No description provided for @statsLastRead.
  ///
  /// In fr, this message translates to:
  /// **'Dernière lecture'**
  String get statsLastRead;

  /// No description provided for @statsByStatusTitle.
  ///
  /// In fr, this message translates to:
  /// **'Répartition par statut'**
  String get statsByStatusTitle;

  /// No description provided for @statsByStatusEmpty.
  ///
  /// In fr, this message translates to:
  /// **'Aucun manga dans votre bibliothèque pour le moment.'**
  String get statsByStatusEmpty;

  /// No description provided for @statsTopGenresTitle.
  ///
  /// In fr, this message translates to:
  /// **'Genres préférés'**
  String get statsTopGenresTitle;

  /// No description provided for @statsTopGenresEmpty.
  ///
  /// In fr, this message translates to:
  /// **'Ajoutez des mangas pour découvrir vos genres préférés.'**
  String get statsTopGenresEmpty;

  /// No description provided for @statsMinutesShort.
  ///
  /// In fr, this message translates to:
  /// **'{count} min'**
  String statsMinutesShort(int count);

  /// No description provided for @statsHoursAndMinutesShort.
  ///
  /// In fr, this message translates to:
  /// **'{hours} h {minutes} min'**
  String statsHoursAndMinutesShort(int hours, int minutes);

  /// No description provided for @statsDaysAndHoursShort.
  ///
  /// In fr, this message translates to:
  /// **'{days} j {hours} h'**
  String statsDaysAndHoursShort(int days, int hours);

  /// No description provided for @statusReadLater.
  ///
  /// In fr, this message translates to:
  /// **'À lire'**
  String get statusReadLater;

  /// No description provided for @statusReading.
  ///
  /// In fr, this message translates to:
  /// **'En cours'**
  String get statusReading;

  /// No description provided for @statusCaughtUp.
  ///
  /// In fr, this message translates to:
  /// **'À jour'**
  String get statusCaughtUp;

  /// No description provided for @statusCompleted.
  ///
  /// In fr, this message translates to:
  /// **'Terminé'**
  String get statusCompleted;

  /// Titre section résumé chiffré (page Stats V1)
  ///
  /// In fr, this message translates to:
  /// **'Vue d\'ensemble'**
  String get statsSectionOverview;

  /// Titre section répartition par statut (page Stats V1)
  ///
  /// In fr, this message translates to:
  /// **'Mangas par statut'**
  String get statsSectionBreakdown;

  /// Titre section genres préférés (page Stats V1)
  ///
  /// In fr, this message translates to:
  /// **'Genres préférés'**
  String get statsSectionGenres;

  /// Label ligne total de mangas (page Stats V1)
  ///
  /// In fr, this message translates to:
  /// **'Mangas dans la bibliothèque'**
  String get statsLibraryTotal;

  /// Texte hero indiquant l'ancienneté du compte en mois
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =0{Membre depuis moins d\'\'un mois} =1{Membre depuis 1 mois} other{Membre depuis {count} mois}}'**
  String statsMonthsSinceJoin(int count);

  /// Badge à droite du hero (page Stats V1)
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =1{1 manga} other{{count} mangas}}'**
  String statsHeroBadge(int count);

  /// Bouton accédant à la page Stats depuis Profile
  ///
  /// In fr, this message translates to:
  /// **'Mes statistiques'**
  String get profileMyStats;

  /// No description provided for @profileEditTitle.
  ///
  /// In fr, this message translates to:
  /// **'Modifier mon profil'**
  String get profileEditTitle;

  /// No description provided for @profileEditBackLabel.
  ///
  /// In fr, this message translates to:
  /// **'Profil'**
  String get profileEditBackLabel;

  /// No description provided for @profileEditMenuTitle.
  ///
  /// In fr, this message translates to:
  /// **'Modifier le profil'**
  String get profileEditMenuTitle;

  /// No description provided for @profileEditMenuSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Photo, pseudo, bio, confidentialité'**
  String get profileEditMenuSubtitle;

  /// No description provided for @profileFieldAvatarUrl.
  ///
  /// In fr, this message translates to:
  /// **'URL de l\'avatar'**
  String get profileFieldAvatarUrl;

  /// No description provided for @profileFieldDisplayName.
  ///
  /// In fr, this message translates to:
  /// **'Nom à afficher'**
  String get profileFieldDisplayName;

  /// No description provided for @profileFieldBio.
  ///
  /// In fr, this message translates to:
  /// **'Bio'**
  String get profileFieldBio;

  /// No description provided for @profileFieldDateOfBirth.
  ///
  /// In fr, this message translates to:
  /// **'Date de naissance'**
  String get profileFieldDateOfBirth;

  /// No description provided for @profileFieldGender.
  ///
  /// In fr, this message translates to:
  /// **'Genre'**
  String get profileFieldGender;

  /// No description provided for @profileGenderNotSet.
  ///
  /// In fr, this message translates to:
  /// **'Non renseigné'**
  String get profileGenderNotSet;

  /// No description provided for @profileGenderMale.
  ///
  /// In fr, this message translates to:
  /// **'Homme'**
  String get profileGenderMale;

  /// No description provided for @profileGenderFemale.
  ///
  /// In fr, this message translates to:
  /// **'Femme'**
  String get profileGenderFemale;

  /// No description provided for @profileGenderNonBinary.
  ///
  /// In fr, this message translates to:
  /// **'Non-binaire'**
  String get profileGenderNonBinary;

  /// No description provided for @profileGenderPreferNotToSay.
  ///
  /// In fr, this message translates to:
  /// **'Préfère ne pas dire'**
  String get profileGenderPreferNotToSay;

  /// No description provided for @profileFieldIsPublic.
  ///
  /// In fr, this message translates to:
  /// **'Profil public'**
  String get profileFieldIsPublic;

  /// No description provided for @profileFieldIsPublicSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Visible par les autres utilisateurs'**
  String get profileFieldIsPublicSubtitle;

  /// No description provided for @profileSaved.
  ///
  /// In fr, this message translates to:
  /// **'Profil enregistré'**
  String get profileSaved;

  /// No description provided for @profileSaveFailed.
  ///
  /// In fr, this message translates to:
  /// **'Échec de l\'enregistrement'**
  String get profileSaveFailed;

  /// No description provided for @friendsTitle.
  ///
  /// In fr, this message translates to:
  /// **'Amis'**
  String get friendsTitle;

  /// No description provided for @friendsTabAccepted.
  ///
  /// In fr, this message translates to:
  /// **'Amis'**
  String get friendsTabAccepted;

  /// No description provided for @friendsTabPending.
  ///
  /// In fr, this message translates to:
  /// **'Demandes'**
  String get friendsTabPending;

  /// No description provided for @friendsSearchLabel.
  ///
  /// In fr, this message translates to:
  /// **'Trouver un ami'**
  String get friendsSearchLabel;

  /// No description provided for @friendsSearchHint.
  ///
  /// In fr, this message translates to:
  /// **'Tapez un pseudo (min 2 caractères)'**
  String get friendsSearchHint;

  /// No description provided for @friendsAddRequest.
  ///
  /// In fr, this message translates to:
  /// **'Envoyer une demande'**
  String get friendsAddRequest;

  /// No description provided for @friendsAccept.
  ///
  /// In fr, this message translates to:
  /// **'Accepter'**
  String get friendsAccept;

  /// No description provided for @friendsReject.
  ///
  /// In fr, this message translates to:
  /// **'Refuser'**
  String get friendsReject;

  /// No description provided for @friendsRemove.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer'**
  String get friendsRemove;

  /// No description provided for @friendsRequestSent.
  ///
  /// In fr, this message translates to:
  /// **'Demande envoyée'**
  String get friendsRequestSent;

  /// No description provided for @friendsError.
  ///
  /// In fr, this message translates to:
  /// **'Erreur'**
  String get friendsError;

  /// No description provided for @friendsEmptyAccepted.
  ///
  /// In fr, this message translates to:
  /// **'Aucun ami pour l\'instant'**
  String get friendsEmptyAccepted;

  /// No description provided for @friendsEmptyAcceptedSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Recherche des utilisateurs pour les ajouter.'**
  String get friendsEmptyAcceptedSubtitle;

  /// No description provided for @friendsEmptyPending.
  ///
  /// In fr, this message translates to:
  /// **'Aucune demande en attente'**
  String get friendsEmptyPending;

  /// No description provided for @friendsEmptyPendingSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Les demandes reçues s\'afficheront ici.'**
  String get friendsEmptyPendingSubtitle;

  /// No description provided for @friendsSectionAccepted.
  ///
  /// In fr, this message translates to:
  /// **'Mes amis'**
  String get friendsSectionAccepted;

  /// No description provided for @friendsSectionPending.
  ///
  /// In fr, this message translates to:
  /// **'Demandes reçues'**
  String get friendsSectionPending;

  /// No description provided for @friendsSearchClear.
  ///
  /// In fr, this message translates to:
  /// **'Effacer'**
  String get friendsSearchClear;

  /// No description provided for @friendsSearchResults.
  ///
  /// In fr, this message translates to:
  /// **'Résultats'**
  String get friendsSearchResults;

  /// No description provided for @friendsSearchEmpty.
  ///
  /// In fr, this message translates to:
  /// **'Aucun utilisateur trouvé.'**
  String get friendsSearchEmpty;

  /// No description provided for @profileMyFriends.
  ///
  /// In fr, this message translates to:
  /// **'Mes amis'**
  String get profileMyFriends;

  /// No description provided for @commentsTitle.
  ///
  /// In fr, this message translates to:
  /// **'Commentaires'**
  String get commentsTitle;

  /// No description provided for @commentsEmpty.
  ///
  /// In fr, this message translates to:
  /// **'Aucun commentaire pour le moment. Soyez le premier !'**
  String get commentsEmpty;

  /// No description provided for @commentsSortRecent.
  ///
  /// In fr, this message translates to:
  /// **'Récent'**
  String get commentsSortRecent;

  /// No description provided for @commentsSortTop.
  ///
  /// In fr, this message translates to:
  /// **'Populaire'**
  String get commentsSortTop;

  /// No description provided for @commentsInputHint.
  ///
  /// In fr, this message translates to:
  /// **'Partagez votre avis (3-2000 caractères)'**
  String get commentsInputHint;

  /// No description provided for @commentsPost.
  ///
  /// In fr, this message translates to:
  /// **'Publier'**
  String get commentsPost;

  /// No description provided for @commentsDelete.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer'**
  String get commentsDelete;

  /// No description provided for @commentsLoadMore.
  ///
  /// In fr, this message translates to:
  /// **'Voir plus'**
  String get commentsLoadMore;

  /// No description provided for @commentsReplyCount.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =1{1 réponse} other{{count} réponses}}'**
  String commentsReplyCount(int count);

  /// No description provided for @timeJustNow.
  ///
  /// In fr, this message translates to:
  /// **'à l\'instant'**
  String get timeJustNow;

  /// No description provided for @timeMinutesAgo.
  ///
  /// In fr, this message translates to:
  /// **'il y a {count} min'**
  String timeMinutesAgo(int count);

  /// No description provided for @timeHoursAgo.
  ///
  /// In fr, this message translates to:
  /// **'il y a {count} h'**
  String timeHoursAgo(int count);

  /// No description provided for @timeDaysAgo.
  ///
  /// In fr, this message translates to:
  /// **'il y a {count} j'**
  String timeDaysAgo(int count);

  /// No description provided for @shareTitle.
  ///
  /// In fr, this message translates to:
  /// **'Partager ce manga'**
  String get shareTitle;

  /// No description provided for @shareMessageHint.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter un message (optionnel)'**
  String get shareMessageHint;

  /// No description provided for @shareCancel.
  ///
  /// In fr, this message translates to:
  /// **'Annuler'**
  String get shareCancel;

  /// No description provided for @shareSend.
  ///
  /// In fr, this message translates to:
  /// **'Envoyer'**
  String get shareSend;

  /// No description provided for @shareSuccess.
  ///
  /// In fr, this message translates to:
  /// **'Manga partagé'**
  String get shareSuccess;

  /// No description provided for @shareFailed.
  ///
  /// In fr, this message translates to:
  /// **'Échec du partage'**
  String get shareFailed;

  /// No description provided for @shareLoadError.
  ///
  /// In fr, this message translates to:
  /// **'Impossible de charger vos amis'**
  String get shareLoadError;

  /// No description provided for @shareNoFriends.
  ///
  /// In fr, this message translates to:
  /// **'Vous n\'avez pas encore d\'amis avec qui partager. Ajoutez-en depuis la page Amis.'**
  String get shareNoFriends;

  /// No description provided for @inboxTitle.
  ///
  /// In fr, this message translates to:
  /// **'Recommandations reçues'**
  String get inboxTitle;

  /// No description provided for @inboxEmpty.
  ///
  /// In fr, this message translates to:
  /// **'Aucune recommandation pour l\'instant.'**
  String get inboxEmpty;

  /// No description provided for @inboxBadgeNew.
  ///
  /// In fr, this message translates to:
  /// **'NOUVEAU'**
  String get inboxBadgeNew;

  /// No description provided for @inboxSenderRecommends.
  ///
  /// In fr, this message translates to:
  /// **'{sender} vous recommande'**
  String inboxSenderRecommends(String sender);

  /// No description provided for @inboxSharedYouLabel.
  ///
  /// In fr, this message translates to:
  /// **'{sender} vous a partagé'**
  String inboxSharedYouLabel(String sender);

  /// No description provided for @inboxFilterAll.
  ///
  /// In fr, this message translates to:
  /// **'Toutes'**
  String get inboxFilterAll;

  /// No description provided for @inboxFilterUnread.
  ///
  /// In fr, this message translates to:
  /// **'Non lues'**
  String get inboxFilterUnread;

  /// No description provided for @inboxFilterRead.
  ///
  /// In fr, this message translates to:
  /// **'Lues'**
  String get inboxFilterRead;

  /// No description provided for @inboxGroupToday.
  ///
  /// In fr, this message translates to:
  /// **'Aujourd\'hui'**
  String get inboxGroupToday;

  /// No description provided for @inboxGroupYesterday.
  ///
  /// In fr, this message translates to:
  /// **'Hier'**
  String get inboxGroupYesterday;

  /// No description provided for @inboxGroupThisWeek.
  ///
  /// In fr, this message translates to:
  /// **'Cette semaine'**
  String get inboxGroupThisWeek;

  /// No description provided for @inboxGroupOlder.
  ///
  /// In fr, this message translates to:
  /// **'Plus tôt'**
  String get inboxGroupOlder;

  /// No description provided for @inboxEmptyTitle.
  ///
  /// In fr, this message translates to:
  /// **'Aucune recommandation'**
  String get inboxEmptyTitle;

  /// No description provided for @inboxEmptySubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Demande à tes amis de te partager leurs lectures préférées.'**
  String get inboxEmptySubtitle;

  /// No description provided for @inboxEmptyFilteredUnread.
  ///
  /// In fr, this message translates to:
  /// **'Aucune recommandation non lue.'**
  String get inboxEmptyFilteredUnread;

  /// No description provided for @inboxEmptyFilteredRead.
  ///
  /// In fr, this message translates to:
  /// **'Aucune recommandation lue.'**
  String get inboxEmptyFilteredRead;

  /// No description provided for @profileMyInbox.
  ///
  /// In fr, this message translates to:
  /// **'Recommandations reçues'**
  String get profileMyInbox;

  /// No description provided for @readingGroupsTitle.
  ///
  /// In fr, this message translates to:
  /// **'Lectures à deux'**
  String get readingGroupsTitle;

  /// No description provided for @readingGroupsEmpty.
  ///
  /// In fr, this message translates to:
  /// **'Aucun groupe de lecture pour le moment. Crée-en un depuis la fiche d\'un manga.'**
  String get readingGroupsEmpty;

  /// No description provided for @readingGroupDetailTitle.
  ///
  /// In fr, this message translates to:
  /// **'Groupe de lecture'**
  String get readingGroupDetailTitle;

  /// No description provided for @readingGroupMembersTitle.
  ///
  /// In fr, this message translates to:
  /// **'Membres'**
  String get readingGroupMembersTitle;

  /// No description provided for @readingGroupOwnerBadge.
  ///
  /// In fr, this message translates to:
  /// **'OWNER'**
  String get readingGroupOwnerBadge;

  /// No description provided for @readingGroupOpenManga.
  ///
  /// In fr, this message translates to:
  /// **'Ouvrir le manga'**
  String get readingGroupOpenManga;

  /// No description provided for @readingGroupNotStarted.
  ///
  /// In fr, this message translates to:
  /// **'Pas commencé'**
  String get readingGroupNotStarted;

  /// No description provided for @readingGroupChaptersRead.
  ///
  /// In fr, this message translates to:
  /// **'Chap. {count}'**
  String readingGroupChaptersRead(int count);

  /// No description provided for @readingGroupChaptersReadLabel.
  ///
  /// In fr, this message translates to:
  /// **'lus'**
  String get readingGroupChaptersReadLabel;

  /// No description provided for @readingGroupMembersCount.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =1{1 membre} other{{count} membres}}'**
  String readingGroupMembersCount(int count);

  /// No description provided for @profileMyReadingGroups.
  ///
  /// In fr, this message translates to:
  /// **'Lectures à deux'**
  String get profileMyReadingGroups;

  /// No description provided for @profileSectionPublicInfo.
  ///
  /// In fr, this message translates to:
  /// **'Informations publiques'**
  String get profileSectionPublicInfo;

  /// No description provided for @profileSectionAbout.
  ///
  /// In fr, this message translates to:
  /// **'À propos de vous'**
  String get profileSectionAbout;

  /// No description provided for @profileSectionPrivacy.
  ///
  /// In fr, this message translates to:
  /// **'Confidentialité'**
  String get profileSectionPrivacy;

  /// No description provided for @profileNotSet.
  ///
  /// In fr, this message translates to:
  /// **'Non renseigné'**
  String get profileNotSet;

  /// No description provided for @profileSectionAvatar.
  ///
  /// In fr, this message translates to:
  /// **'Avatar'**
  String get profileSectionAvatar;

  /// No description provided for @profileEditAvatarHeroHint.
  ///
  /// In fr, this message translates to:
  /// **'L\'aperçu se met à jour quand tu colles une URL d\'image.'**
  String get profileEditAvatarHeroHint;

  /// No description provided for @profileEditPickPhoto.
  ///
  /// In fr, this message translates to:
  /// **'Choisir une photo'**
  String get profileEditPickPhoto;

  /// No description provided for @profileEditClearAvatar.
  ///
  /// In fr, this message translates to:
  /// **'Effacer'**
  String get profileEditClearAvatar;

  /// No description provided for @profileEditPhotoPickFailed.
  ///
  /// In fr, this message translates to:
  /// **'Impossible de sélectionner la photo'**
  String get profileEditPhotoPickFailed;

  /// No description provided for @profileGenderClear.
  ///
  /// In fr, this message translates to:
  /// **'Effacer'**
  String get profileGenderClear;

  /// No description provided for @avatarUrlLabel.
  ///
  /// In fr, this message translates to:
  /// **'URL de l\'avatar'**
  String get avatarUrlLabel;

  /// No description provided for @avatarUrlInvalid.
  ///
  /// In fr, this message translates to:
  /// **'L\'URL doit commencer par http:// ou https://'**
  String get avatarUrlInvalid;

  /// No description provided for @profileSectionAccount.
  ///
  /// In fr, this message translates to:
  /// **'Compte'**
  String get profileSectionAccount;

  /// No description provided for @profileFieldUsername.
  ///
  /// In fr, this message translates to:
  /// **'Nom d\'utilisateur'**
  String get profileFieldUsername;

  /// No description provided for @profileFieldEmail.
  ///
  /// In fr, this message translates to:
  /// **'Adresse e-mail'**
  String get profileFieldEmail;

  /// No description provided for @profileFieldReadOnly.
  ///
  /// In fr, this message translates to:
  /// **'Non modifiable'**
  String get profileFieldReadOnly;

  /// No description provided for @profileChangePhoto.
  ///
  /// In fr, this message translates to:
  /// **'Modifier la photo'**
  String get profileChangePhoto;

  /// No description provided for @changelogCardTitle.
  ///
  /// In fr, this message translates to:
  /// **'Notes de version'**
  String get changelogCardTitle;

  /// No description provided for @readingGroupCreateTitle.
  ///
  /// In fr, this message translates to:
  /// **'Lire à deux'**
  String get readingGroupCreateTitle;

  /// No description provided for @readingGroupCreateNameLabel.
  ///
  /// In fr, this message translates to:
  /// **'Nom du groupe (optionnel)'**
  String get readingGroupCreateNameLabel;

  /// No description provided for @readingGroupCreateNameHint.
  ///
  /// In fr, this message translates to:
  /// **'ex: Berserk avec Léa'**
  String get readingGroupCreateNameHint;

  /// No description provided for @readingGroupCreateInviteSection.
  ///
  /// In fr, this message translates to:
  /// **'Inviter des amis'**
  String get readingGroupCreateInviteSection;

  /// No description provided for @readingGroupCreateConfirm.
  ///
  /// In fr, this message translates to:
  /// **'Créer le groupe'**
  String get readingGroupCreateConfirm;

  /// No description provided for @readingGroupCreateFailed.
  ///
  /// In fr, this message translates to:
  /// **'Création du groupe échouée'**
  String get readingGroupCreateFailed;

  /// No description provided for @readingGroupCreateInviteRequired.
  ///
  /// In fr, this message translates to:
  /// **'Sélectionne au moins un ami pour créer le groupe'**
  String get readingGroupCreateInviteRequired;

  /// No description provided for @readingGroupDelete.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer le groupe'**
  String get readingGroupDelete;

  /// No description provided for @readingGroupDeleteConfirmTitle.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer ce groupe ?'**
  String get readingGroupDeleteConfirmTitle;

  /// No description provided for @readingGroupDeleteConfirm.
  ///
  /// In fr, this message translates to:
  /// **'Cette action est irréversible. Tous les membres perdront l\'accès au groupe.'**
  String get readingGroupDeleteConfirm;

  /// No description provided for @readingGroupDeleteSuccess.
  ///
  /// In fr, this message translates to:
  /// **'Groupe supprimé'**
  String get readingGroupDeleteSuccess;

  /// No description provided for @readingGroupDeleteFailed.
  ///
  /// In fr, this message translates to:
  /// **'Suppression du groupe échouée'**
  String get readingGroupDeleteFailed;

  /// No description provided for @readingGroupSharedReading.
  ///
  /// In fr, this message translates to:
  /// **'Lecture partagée'**
  String get readingGroupSharedReading;

  /// No description provided for @readingGroupViewGroup.
  ///
  /// In fr, this message translates to:
  /// **'Voir le groupe'**
  String get readingGroupViewGroup;

  /// No description provided for @readingGroupChapterShort.
  ///
  /// In fr, this message translates to:
  /// **'ch.'**
  String get readingGroupChapterShort;

  /// No description provided for @profileHighlightTitle.
  ///
  /// In fr, this message translates to:
  /// **'Nouvelles fonctionnalités'**
  String get profileHighlightTitle;

  /// No description provided for @profileNewBadge.
  ///
  /// In fr, this message translates to:
  /// **'Nouveau'**
  String get profileNewBadge;

  /// No description provided for @profileFooterBrand.
  ///
  /// In fr, this message translates to:
  /// **'MANGA TRACKER'**
  String get profileFooterBrand;

  /// No description provided for @readingGroupListSectionTitle.
  ///
  /// In fr, this message translates to:
  /// **'Mes groupes'**
  String get readingGroupListSectionTitle;

  /// No description provided for @readingGroupWithLabel.
  ///
  /// In fr, this message translates to:
  /// **'Avec {name}'**
  String readingGroupWithLabel(String name);

  /// No description provided for @readingGroupYouLabel.
  ///
  /// In fr, this message translates to:
  /// **'Toi'**
  String get readingGroupYouLabel;

  /// No description provided for @readingGroupProgressYouVsFriend.
  ///
  /// In fr, this message translates to:
  /// **'Toi : ch. {you} · {friend} : ch. {their}'**
  String readingGroupProgressYouVsFriend(
    String you,
    String friend,
    String their,
  );

  /// No description provided for @readingGroupChapterDash.
  ///
  /// In fr, this message translates to:
  /// **'—'**
  String get readingGroupChapterDash;

  /// No description provided for @readingGroupSectionHero.
  ///
  /// In fr, this message translates to:
  /// **'Lecture en cours'**
  String get readingGroupSectionHero;

  /// No description provided for @readingGroupSectionProgress.
  ///
  /// In fr, this message translates to:
  /// **'Progression'**
  String get readingGroupSectionProgress;

  /// No description provided for @readingGroupSectionActions.
  ///
  /// In fr, this message translates to:
  /// **'Actions'**
  String get readingGroupSectionActions;

  /// No description provided for @readingGroupActionsMarkProgress.
  ///
  /// In fr, this message translates to:
  /// **'Marquer ma progression'**
  String get readingGroupActionsMarkProgress;

  /// No description provided for @readingGroupActionsMarkProgressSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Ouvrir la fiche du manga pour avancer'**
  String get readingGroupActionsMarkProgressSubtitle;

  /// No description provided for @readingGroupActionsInvite.
  ///
  /// In fr, this message translates to:
  /// **'Inviter un ami'**
  String get readingGroupActionsInvite;

  /// No description provided for @readingGroupActionsCopyFriendLink.
  ///
  /// In fr, this message translates to:
  /// **'Copier le lien de {friend}'**
  String readingGroupActionsCopyFriendLink(String friend);

  /// No description provided for @readingGroupActionsCopyFriendLinkSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Adapté au chapitre {chapter}'**
  String readingGroupActionsCopyFriendLinkSubtitle(int chapter);

  /// No description provided for @readingGroupApplyLinkSuccess.
  ///
  /// In fr, this message translates to:
  /// **'Lien enregistré sur le chapitre {chapter}'**
  String readingGroupApplyLinkSuccess(int chapter);

  /// No description provided for @readingGroupCopyLinkSuccess.
  ///
  /// In fr, this message translates to:
  /// **'Lien copié — chapitre {chapter}'**
  String readingGroupCopyLinkSuccess(int chapter);

  /// No description provided for @readingGroupCopyLinkFailed.
  ///
  /// In fr, this message translates to:
  /// **'Impossible d\'adapter ce lien (format non reconnu)'**
  String get readingGroupCopyLinkFailed;

  /// No description provided for @readingGroupActionsInviteSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter une personne au groupe'**
  String get readingGroupActionsInviteSubtitle;

  /// No description provided for @readingGroupActionsLeave.
  ///
  /// In fr, this message translates to:
  /// **'Quitter le groupe'**
  String get readingGroupActionsLeave;

  /// No description provided for @readingGroupActionsLeaveSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Tu ne verras plus la progression partagée'**
  String get readingGroupActionsLeaveSubtitle;

  /// No description provided for @readingGroupActionsDeleteSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer définitivement pour tous les membres'**
  String get readingGroupActionsDeleteSubtitle;

  /// No description provided for @readingGroupLeaveConfirmTitle.
  ///
  /// In fr, this message translates to:
  /// **'Quitter ce groupe ?'**
  String get readingGroupLeaveConfirmTitle;

  /// No description provided for @readingGroupLeaveConfirm.
  ///
  /// In fr, this message translates to:
  /// **'Tu n\'auras plus accès à la progression partagée.'**
  String get readingGroupLeaveConfirm;

  /// No description provided for @readingGroupLeaveSuccess.
  ///
  /// In fr, this message translates to:
  /// **'Tu as quitté le groupe'**
  String get readingGroupLeaveSuccess;

  /// No description provided for @readingGroupLeaveFailed.
  ///
  /// In fr, this message translates to:
  /// **'Impossible de quitter le groupe'**
  String get readingGroupLeaveFailed;

  /// No description provided for @readingGroupEmptyTitle.
  ///
  /// In fr, this message translates to:
  /// **'Aucune lecture à deux'**
  String get readingGroupEmptyTitle;

  /// No description provided for @readingGroupEmptySubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Démarre un manga avec un ami et suivez votre progression ensemble.'**
  String get readingGroupEmptySubtitle;

  /// No description provided for @readingGroupEmptyAction.
  ///
  /// In fr, this message translates to:
  /// **'Découvrir un manga'**
  String get readingGroupEmptyAction;

  /// No description provided for @readingGroupTotalLabel.
  ///
  /// In fr, this message translates to:
  /// **'Total'**
  String get readingGroupTotalLabel;

  /// No description provided for @readingGroupChaptersTotal.
  ///
  /// In fr, this message translates to:
  /// **'{count} ch.'**
  String readingGroupChaptersTotal(int count);

  /// No description provided for @readingGroupInviteSoonTitle.
  ///
  /// In fr, this message translates to:
  /// **'Bientôt disponible'**
  String get readingGroupInviteSoonTitle;

  /// No description provided for @readingGroupInviteSoonMessage.
  ///
  /// In fr, this message translates to:
  /// **'L\'invitation depuis le groupe arrive très bientôt. Pour l\'instant, recrée un groupe depuis la fiche d\'un manga.'**
  String get readingGroupInviteSoonMessage;

  /// Tooltip du bouton qui passe en vue liste dans la bibliothèque
  ///
  /// In fr, this message translates to:
  /// **'Vue liste'**
  String get libraryToggleListView;

  /// Tooltip du bouton qui passe en vue carte dans la bibliothèque
  ///
  /// In fr, this message translates to:
  /// **'Vue carte'**
  String get libraryToggleCardView;

  /// Tooltip du filtre Téléchargés uniquement
  ///
  /// In fr, this message translates to:
  /// **'Afficher uniquement les téléchargés'**
  String get libraryShowDownloadedOnly;

  /// Tooltip pour revenir à l'affichage complet (filtre Téléchargés désactivé)
  ///
  /// In fr, this message translates to:
  /// **'Afficher tous les mangas'**
  String get libraryShowAllMangas;

  /// Label d'accessibilité de la barre de progression de lecture
  ///
  /// In fr, this message translates to:
  /// **'{read} sur {total} chapitres lus'**
  String libraryProgressLabel(int read, int total);

  /// Nombre de votes communautaires sur un manga
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =0{Aucun vote} =1{1 vote} other{{count} votes}}'**
  String votesCount(int count);

  /// Titre de section des recommandations / mangas similaires
  ///
  /// In fr, this message translates to:
  /// **'Mangas similaires'**
  String get detailSectionSimilar;

  /// Label de la note communautaire affichée dans la carte d'informations du manga
  ///
  /// In fr, this message translates to:
  /// **'Note'**
  String get rating;

  /// Nom affiché à la place d'un identifiant au format email (RGPD defense-in-depth)
  ///
  /// In fr, this message translates to:
  /// **'Utilisateur anonyme'**
  String get anonymousUser;

  /// Titre du bandeau d'accueil recos quand la bibliothèque est vide
  ///
  /// In fr, this message translates to:
  /// **'Découvre les mangas populaires'**
  String get recommendationsColdStartTitle;

  /// Sous-titre du bandeau cold start recos
  ///
  /// In fr, this message translates to:
  /// **'Ajoute tes premières lectures pour recevoir des recommandations personnalisées'**
  String get recommendationsColdStartSubtitle;

  /// No description provided for @friendLibraryError.
  ///
  /// In fr, this message translates to:
  /// **'Impossible de charger la bibliothèque de cet ami.'**
  String get friendLibraryError;

  /// No description provided for @friendLibraryEmpty.
  ///
  /// In fr, this message translates to:
  /// **'Sa bibliothèque est vide pour l’instant.'**
  String get friendLibraryEmpty;

  /// No description provided for @friendLibraryCount.
  ///
  /// In fr, this message translates to:
  /// **'{count} mangas dans sa bibliothèque'**
  String friendLibraryCount(int count);

  /// No description provided for @statsHistoryTitle.
  ///
  /// In fr, this message translates to:
  /// **'Dernières lectures'**
  String get statsHistoryTitle;

  /// No description provided for @statsActivityTitle.
  ///
  /// In fr, this message translates to:
  /// **'Activité de lecture'**
  String get statsActivityTitle;

  /// No description provided for @statsBonusTag.
  ///
  /// In fr, this message translates to:
  /// **'Hors-série'**
  String get statsBonusTag;

  /// No description provided for @statsNoHistory.
  ///
  /// In fr, this message translates to:
  /// **'Aucune lecture enregistrée pour l’instant. Valide un chapitre depuis le lecteur pour démarrer ton historique.'**
  String get statsNoHistory;

  /// No description provided for @recommendationsSleepersTitle.
  ///
  /// In fr, this message translates to:
  /// **'💎 Pépites cachées'**
  String get recommendationsSleepersTitle;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>[
    'de',
    'en',
    'es',
    'fr',
    'ja',
    'ko',
    'pt',
  ].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'de':
      return AppLocalizationsDe();
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
    case 'fr':
      return AppLocalizationsFr();
    case 'ja':
      return AppLocalizationsJa();
    case 'ko':
      return AppLocalizationsKo();
    case 'pt':
      return AppLocalizationsPt();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
