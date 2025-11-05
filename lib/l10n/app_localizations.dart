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

  /// Bouton d'annulation
  ///
  /// In fr, this message translates to:
  /// **'Annuler'**
  String get cancel;

  /// Bouton d'enregistrement
  ///
  /// In fr, this message translates to:
  /// **'Enregistrer'**
  String get save;

  /// Bouton de suppression
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
