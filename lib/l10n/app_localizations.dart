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
