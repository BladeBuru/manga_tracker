// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get appTitle => 'MangaTracker';

  @override
  String get welcomeBack => 'Bienvenido de nuevo';

  @override
  String get emailAddress => 'Dirección de correo electrónico';

  @override
  String get password => 'Contraseña';

  @override
  String get forgotPassword => '¿Olvidaste la contraseña?';

  @override
  String get login => 'Iniciar sesión';

  @override
  String get googleLoginFailed => 'Error al iniciar sesión con Google';

  @override
  String get googleLoginConfigError =>
      'Inicio de sesión con Google no disponible (error de configuración de la app)';

  @override
  String get loginWithGoogle => 'Iniciar sesión con Google';

  @override
  String get back => 'Atrás';

  @override
  String get signUp => 'Registrarse';

  @override
  String get invalidCredentials => 'Credenciales inválidas';

  @override
  String get unknownError => 'Error desconocido';

  @override
  String get trending => 'Tendencias';

  @override
  String get popular => 'Popular';

  @override
  String get newMangas => 'Nuevo';

  @override
  String get offlineMode => 'Modo offline';

  @override
  String get offlineModeNoCache => 'Modo offline - Sin datos en caché';

  @override
  String get offlineModeActionQueued => 'Modo offline - Acción en cola';

  @override
  String pendingActions(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'es',
      one: '',
      zero: 'es',
    );
    String _temp1 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 's',
      one: '',
      zero: 's',
    );
    return '$count acción$_temp0 pendiente$_temp1';
  }

  @override
  String get retry => 'Reintentar';

  @override
  String get searchNoResults => 'No se encontraron resultados';

  @override
  String searchResultsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count resultados',
      one: '1 resultado',
    );
    return '$_temp0';
  }

  @override
  String get searchLoadFailed => 'La búsqueda falló';

  @override
  String get searchLoadMoreFailed => 'No se pudieron cargar más resultados';

  @override
  String get error => 'Error';

  @override
  String get library => 'Biblioteca';

  @override
  String get search => 'Buscar';

  @override
  String get profile => 'Perfil';

  @override
  String get account => 'Cuenta';

  @override
  String get settings => 'Configuración';

  @override
  String get actions => 'Acciones';

  @override
  String get changePassword => 'Cambiar contraseña';

  @override
  String get changePasswordSubtitle =>
      'Cambiar tu contraseña de inicio de sesión';

  @override
  String get changePasswordTitle => 'Cambiar mi contraseña';

  @override
  String get changePasswordIntro =>
      'Introduce tu contraseña actual y elige una nueva. Tus otros dispositivos se desconectarán.';

  @override
  String get currentPasswordLabel => 'Contraseña actual';

  @override
  String get newPasswordLabel => 'Nueva contraseña';

  @override
  String get confirmNewPasswordLabel => 'Confirmar la nueva contraseña';

  @override
  String get changePasswordSuccess => 'Contraseña cambiada';

  @override
  String get changePasswordSuccessHint =>
      'Tus otros dispositivos se han desconectado. Volviendo al perfil…';

  @override
  String get changePasswordWrongCurrent => 'La contraseña actual es incorrecta';

  @override
  String get changePasswordSocialAccount =>
      'Esta cuenta usa el inicio de sesión de Google: no hay contraseña que cambiar';

  @override
  String get accountInformation => 'Información de la cuenta';

  @override
  String get email => 'Correo electrónico';

  @override
  String get notifications => 'Notificaciones';

  @override
  String get newChapterNotifications => 'Notificaciones de nuevos capítulos';

  @override
  String get newChapterNotificationsEnabled => 'Activadas';

  @override
  String get newChapterNotificationsDisabled => 'Desactivadas';

  @override
  String get manageNotifications => 'Gestionar notificaciones';

  @override
  String get notifSectionApp => 'Notificaciones de la aplicación';

  @override
  String get notifSectionInfo => 'Información';

  @override
  String get notifNewChaptersTitle => 'Nuevos capítulos';

  @override
  String get notifNewChaptersSubtitle =>
      'Recibe una alerta cuando tus mangas seguidos publiquen nuevos capítulos';

  @override
  String get notifFriendReqTitle => 'Solicitudes de amistad';

  @override
  String get notifFriendReqSubtitle => 'Alguien quiere añadirte como amigo';

  @override
  String get notifSharesTitle => 'Recomendaciones recibidas';

  @override
  String get notifSharesSubtitle => 'Un amigo te comparte un manga';

  @override
  String get notifPermissionExplanation =>
      'Las notificaciones aparecen solo cuando la aplicación tiene permiso del sistema. Si no recibes ninguna, actívalas desde los ajustes de tu teléfono.';

  @override
  String get notifOpenSystemSettings => 'Abrir ajustes del sistema';

  @override
  String get pushNotifFriendRequestTitle => 'Nueva solicitud de amistad';

  @override
  String pushNotifFriendRequestBody(String senderUsername) {
    return '$senderUsername quiere añadirte como amigo';
  }

  @override
  String get pushNotifShareTitle => 'Nuevo manga compartido';

  @override
  String pushNotifShareBody(String senderUsername, String mangaTitle) {
    return '$senderUsername te recomienda $mangaTitle';
  }

  @override
  String get theme => 'Tema';

  @override
  String get lightMode => 'Modo claro';

  @override
  String get darkMode => 'Modo oscuro';

  @override
  String get systemMode => 'Sistema';

  @override
  String get language => 'Idioma';

  @override
  String get selectLanguage => 'Seleccionar idioma';

  @override
  String get french => 'Francés';

  @override
  String get english => 'Inglés';

  @override
  String get logout => 'Cerrar sesión';

  @override
  String get logoutSubtitle => 'Cerrar sesión de tu cuenta';

  @override
  String get confirmLogout => 'Cerrar sesión';

  @override
  String get confirmLogoutMessage =>
      '¿Estás seguro de que quieres cerrar sesión?';

  @override
  String get deleteAccount => 'Eliminar cuenta';

  @override
  String get deleteAccountSubtitle => 'Acción irreversible';

  @override
  String get confirmDeleteAccount => 'Eliminar cuenta';

  @override
  String get confirmDeleteAccountMessage =>
      'Esta acción es irreversible. Todos tus datos serán eliminados permanentemente y no se podrán recuperar.';

  @override
  String get cancel => 'Cancelar';

  @override
  String get save => 'Guardar';

  @override
  String get delete => 'Eliminar';

  @override
  String get passwordChangedSuccess => 'Contraseña cambiada con éxito';

  @override
  String get passwordChangeError => 'Error al cambiar la contraseña';

  @override
  String get accountDeletedSuccess => 'Cuenta eliminada con éxito';

  @override
  String get accountDeleteError => 'Error al eliminar la cuenta';

  @override
  String get userInfoLoadError =>
      'No se pudieron cargar la información del usuario';

  @override
  String get user => 'Usuario';

  @override
  String get comingSoon => 'Próximamente';

  @override
  String get comingSoonAvatar => 'Próximamente: cambiar avatar';

  @override
  String get whatsNew => '¿Qué hay de nuevo?';

  @override
  String get version => 'Versión';

  @override
  String get newFeaturesAvailable => 'Nuevas funciones disponibles';

  @override
  String get currentVersion => 'Versión actual';

  @override
  String get great => '¡Genial!';

  @override
  String get authorizationRequired => 'Autorización requerida';

  @override
  String get modifyLink => 'Modificar enlace';

  @override
  String get removeLink => 'Eliminar enlace';

  @override
  String get chapterSkip => 'Saltar capítulo';

  @override
  String get validateReading => 'Validar lectura';

  @override
  String get addToLibrary => 'Añadir a la biblioteca';

  @override
  String get removeFromLibrary => 'Eliminar de la biblioteca';

  @override
  String get updateStatus => 'Actualizar estado';

  @override
  String get reading => 'Leyendo';

  @override
  String get completed => 'Completado';

  @override
  String get onHold => 'En pausa';

  @override
  String get dropped => 'Abandonado';

  @override
  String get planToRead => 'Planificado';

  @override
  String get reReading => 'Releyendo';

  @override
  String get chapters => 'Capítulos';

  @override
  String get readChapters => 'Capítulos leídos';

  @override
  String get totalChapters => 'Total de capítulos';

  @override
  String get associatedNames => 'Nombres asociados';

  @override
  String associatedNamesCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count nombres',
      one: '$count nombre',
      zero: 'Sin nombres',
    );
    return '$_temp0';
  }

  @override
  String get saveProgress => 'Guardar progreso';

  @override
  String get description => 'Descripción';

  @override
  String get authors => 'Autores';

  @override
  String get genres => 'Géneros';

  @override
  String get recommendations => 'Recomendaciones';

  @override
  String get loading => 'Cargando...';

  @override
  String get noData => 'No hay datos disponibles';

  @override
  String get noResults => 'No hay resultados';

  @override
  String get noAccount => '¿No tienes una cuenta?';

  @override
  String get home => 'Inicio';

  @override
  String get myAccount => 'Mi cuenta';

  @override
  String get offlineModeCached => 'Modo offline - Datos en caché';

  @override
  String get biometricAuthFailed => 'Autenticación biométrica fallida';

  @override
  String get biometricAuth => 'Inicio de sesión biométrico';

  @override
  String get addLink => 'Añadir enlace';

  @override
  String get addOrModifyLink => 'Añadir o modificar enlace';

  @override
  String get linkUrlPlaceholder => 'https://ejemplo.com';

  @override
  String get validate => 'Validar';

  @override
  String get invalidLink =>
      'Enlace inválido. El enlace debe comenzar con http:// o https://';

  @override
  String get linkSaved => '¡Enlace guardado!';

  @override
  String get linkRemoved => '¡Enlace eliminado!';

  @override
  String get readOnline => 'Leer en línea';

  @override
  String get manageLink => 'Gestionar enlace';

  @override
  String get recommendedMangas => 'Mangas recomendados';

  @override
  String get noRecommendationsAvailable =>
      'No hay recomendaciones disponibles.';

  @override
  String get close => 'Cerrar';

  @override
  String get changeStatus => 'Cambiar estado';

  @override
  String get mangaAddedToLibrary => 'Manga añadido a la biblioteca';

  @override
  String get mangaMarkedAs => 'Manga marcado como';

  @override
  String get readLater => 'Leer más tarde';

  @override
  String get upToDate => 'Actualizado';

  @override
  String get addToReadLater => 'Añadir a \"Leer más tarde\"';

  @override
  String get mangaRemovedFromLibrary => 'Manga eliminado de la biblioteca';

  @override
  String get searchPlaceholder => 'Buscar Mangas, Manwhas...';

  @override
  String get year => 'Año';

  @override
  String get status => 'Estado';

  @override
  String get author => 'Autor';

  @override
  String get artist => 'Artista';

  @override
  String get synopsis => 'Sinopsis';

  @override
  String get seeMore => 'Ver más';

  @override
  String get seeLess => 'Ver menos';

  @override
  String get all => 'Todos';

  @override
  String get newReleases => 'Nuevos lanzamientos';

  @override
  String get chapter => 'Capítulo';

  @override
  String chaptersCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count capítulos',
      one: '$count capítulo',
      zero: 'Sin capítulos',
    );
    return '$_temp0';
  }

  @override
  String chapterSaved(String chapter) {
    return 'Capítulo $chapter guardado';
  }

  @override
  String get chapterRead => 'leído';

  @override
  String get chapterUnread => 'no leído';

  @override
  String mangaAddedToLibrarySuccess(String title) {
    return '¡$title ha sido añadido a la biblioteca!';
  }

  @override
  String get errorAddingToLibrary => 'Error al añadir a la biblioteca.';

  @override
  String get errorUpdatingChapter => 'Error al actualizar el capítulo.';

  @override
  String cannotOpenLink(String url) {
    return 'No se puede abrir el enlace: $url';
  }

  @override
  String get searchHistoryTitle => 'Historial de búsqueda';

  @override
  String get searchEmptyStateMessage => 'Busque un manga, manhwa o manhua';

  @override
  String get clear => 'Borrar';

  @override
  String get searchTitle => 'Buscar';

  @override
  String get searchEmptyHistory => 'Sin búsquedas recientes';

  @override
  String get searchPopularGenres => 'Géneros populares';

  @override
  String get biometricAuthTitle => 'Autenticación biométrica';

  @override
  String get biometricAuthSubtitle =>
      'Usar huella dactilar o Face ID para iniciar sesión rápidamente';

  @override
  String get enableBiometricAuth => 'Autenticación biométrica activada';

  @override
  String get disableBiometricAuth => 'Autenticación biométrica desactivada';

  @override
  String get biometricAuthEnabled => 'Activada';

  @override
  String get biometricAuthDisabled => 'Desactivada';

  @override
  String get biometricAuthFirstTimeTitle =>
      '¿Activar la autenticación biométrica?';

  @override
  String get biometricAuthFirstTimeMessage =>
      '¿Le gustaría usar su huella dactilar o Face ID para iniciar sesión rápidamente en el futuro?';

  @override
  String get biometricAuthNotAvailable =>
      'La autenticación biométrica no está disponible en este dispositivo';

  @override
  String get biometricAuthRequiresReconnect =>
      'Para activar la autenticación biométrica, inicie sesión nuevamente';

  @override
  String get or => 'O';

  @override
  String get startTrackingNow => 'Comience a seguir su lectura ahora';

  @override
  String get username => 'Nombre de usuario';

  @override
  String get confirmPassword => 'Confirmar';

  @override
  String get alreadyHaveAccount => '¿Ya tiene una cuenta?';

  @override
  String get newPassword => 'Nueva contraseña';

  @override
  String get validationEmailRequired =>
      'Por favor ingrese su dirección de correo electrónico';

  @override
  String get validationEmailInvalid =>
      'Por favor ingrese una dirección de correo electrónico válida';

  @override
  String get validationPasswordRequired => 'Por favor ingrese su contraseña';

  @override
  String get validationPasswordLength =>
      'Su contraseña debe tener entre 8 y 64 caracteres';

  @override
  String get validationPasswordComplexity =>
      'Su contraseña debe contener al menos una letra minúscula, una letra mayúscula y un carácter especial';

  @override
  String get validationConfirmPasswordRequired =>
      'Por favor confirme su contraseña';

  @override
  String get validationPasswordsDoNotMatch => 'Las contraseñas no coinciden';

  @override
  String get showPassword => 'Mostrar contraseña';

  @override
  String get hidePassword => 'Ocultar contraseña';

  @override
  String get emailAlreadyUsed => 'Esta dirección de correo ya está registrada';

  @override
  String get networkError => 'Por favor, verifica tu conexión a internet';

  @override
  String get timeoutError =>
      'El servidor está tardando demasiado en responder. Inténtalo de nuevo.';

  @override
  String get passwordStrengthLabel => 'Seguridad de la contraseña';

  @override
  String get passwordStrengthWeak => 'Débil';

  @override
  String get passwordStrengthMedium => 'Media';

  @override
  String get passwordStrengthStrong => 'Fuerte';

  @override
  String get yes => 'Sí';

  @override
  String get no => 'No';

  @override
  String get yesValidate => 'Sí, validar';

  @override
  String chapterSkipMessage(String prev, String next) {
    return 'Estás saltando del capítulo $prev al $next.\n¿Marcar $prev como leído?';
  }

  @override
  String validateReadingMessage(String chapter) {
    return '¿Has terminado el capítulo $chapter?';
  }

  @override
  String get validateReadingHint => 'Tu progreso se guardará automáticamente.';

  @override
  String get adBlockerTitle => 'Bloqueador de anuncios';

  @override
  String get adBlockerDescription =>
      'El bloqueador de anuncios bloquea automáticamente los anuncios en los sitios de lectura.\n\nSi deseas agregar enlaces o sugerir mejoras para el bloqueo de anuncios, ¡únete a nuestro servidor de Discord!';

  @override
  String get adBlockerTooltip => 'Información sobre el bloqueador de anuncios';

  @override
  String get joinDiscord => 'Unirse a Discord';

  @override
  String get joinDiscordSubtitle =>
      'Comparte tus sugerencias e informa problemas';

  @override
  String get contactUs => 'Contáctanos';

  @override
  String get downloads => 'Téléchargements';

  @override
  String get manageDownloads => 'Gérer les téléchargements';

  @override
  String get manageDownloadsSubtitle =>
      'Voir et supprimer les chapitres téléchargés';

  @override
  String get discordLinkError => 'No se puede abrir el enlace de Discord';

  @override
  String get urlCopied => 'URL copiada al portapapeles';

  @override
  String get urlCopyError => 'Error al copiar la URL';

  @override
  String get copyUrl => 'Copiar URL';

  @override
  String get progressUpdated => 'Progreso actualizado';

  @override
  String get invalidUrl => 'URL inválida';

  @override
  String get webModeProgressTracking => 'Modo Web - Seguimiento de progreso';

  @override
  String get webModeProgressDescription =>
      'Para rastrear tu progreso, pega la URL del capítulo que estás leyendo actualmente.';

  @override
  String get chapterUrlLabel => 'URL del capítulo';

  @override
  String get updateProgress => 'Actualizar progreso';

  @override
  String get openInNewTab => 'Abrir en nueva pestaña';

  @override
  String get linkUrlLabel => 'URL del sitio de escaneo';

  @override
  String get linkFormatInfo => 'Formato de capítulo requerido';

  @override
  String get linkFormatDescription =>
      'Incluya el número de capítulo en la URL para permitir el guardado automático del progreso.\n\nFormatos aceptados:\n• /capítulo-23/ o /chapter-23/\n• /c23/ o /ch23/\n• /ep-23/ o /episode-23/\n• ?chapter=23 o ?num=24';

  @override
  String get linkFormatWarning =>
      'No se detectó formato de capítulo. El enlace redirigirá a la página del manga (no a un capítulo específico).';

  @override
  String get linkFormatDetected =>
      '¡Formato de capítulo detectado! El progreso se guardará automáticamente.';

  @override
  String get linkAddCustomPattern =>
      'Ajouter un pattern personnalisé pour ce format';

  @override
  String get customSelectors => 'Sélecteurs personnalisés';

  @override
  String get manageCustomSelectors => 'Gérer les sélecteurs';

  @override
  String get manageCustomSelectorsSubtitle =>
      'Ajoutez des sélecteurs CSS personnalisés pour bloquer des publicités ou identifier le contenu';

  @override
  String get addCustomSelector => 'Ajouter un sélecteur';

  @override
  String get selectorDomainLabel => 'Domaine (ex: exemple.com)';

  @override
  String get selectorCssLabel => 'Sélecteur CSS';

  @override
  String get selectorTypeLabel => 'Type de sélecteur';

  @override
  String get selectorTypeUrlPattern => 'Pattern d\'URL';

  @override
  String get selectorUrlPatternLabel => 'Pattern d\'URL (regex)';

  @override
  String get selectorUrlPatternHint =>
      'Exemple : /chapter-(\\d+)/ pour détecter /chapter-22';

  @override
  String get selectorExamplesUrlPattern => 'Exemples de patterns d\'URL :';

  @override
  String get selectorExampleUrlPattern => 'Exemple : /chapter-22';

  @override
  String get selectorExampleUrlPatternExplanation =>
      'Si votre site utilise \"/chapter-22\" dans l\'URL et que le système ne le détecte pas automatiquement :';

  @override
  String get selectorUrlPatternExampleDesc =>
      'Utilisez une expression régulière (regex) avec (\\d+) pour capturer le numéro du chapitre.\n\nCe pattern sera appliqué à TOUS les sites.\n\nExemples de patterns :\n• /chapter-(\\d+)/ → détecte /chapter-22\n• /chapppter-(\\d+)/ → détecte /chapppter-22 (avec 3 p)\n• /manga/chapter-(\\d+)/ → détecte /manga/chapter-22\n• /episode-(\\d+)/ → détecte /episode-22';

  @override
  String get selectorUrlPatternGlobal =>
      'ℹ️ Le pattern sera appliqué à TOUS les sites. Pas besoin de spécifier un domaine.';

  @override
  String get selectorTypeAdBlocker => 'Bloqueur de publicités';

  @override
  String get selectorTypeChapterContent => 'Contenu du chapitre';

  @override
  String get selectorDescriptionLabel => 'Description (optionnel)';

  @override
  String get selectorDescriptionHint => 'Description du sélecteur';

  @override
  String get selectorRequiredFields => 'Tous les champs sont requis';

  @override
  String get selectorAdded => 'Sélecteur ajouté';

  @override
  String get deleteSelector => 'Supprimer le sélecteur';

  @override
  String get deleteSelectorConfirm =>
      'Êtes-vous sûr de vouloir supprimer ce sélecteur ?';

  @override
  String get selectorDeleted => 'Sélecteur supprimé';

  @override
  String get selectorsExported => 'Sélecteurs exportés dans le presse-papiers';

  @override
  String get importSelectors => 'Importer des sélecteurs';

  @override
  String get selectorsJsonLabel => 'JSON des sélecteurs';

  @override
  String get import => 'Importer';

  @override
  String selectorsImported(String count) {
    return '$count sélecteur(s) importé(s)';
  }

  @override
  String get selectorsReadyToShare =>
      'Sélecteurs prêts à être partagés ! Collez le JSON dans Discord.';

  @override
  String get exportSelectors => 'Exporter';

  @override
  String get shareSelectors => 'Partager';

  @override
  String get noCustomSelectors => 'Aucun sélecteur personnalisé';

  @override
  String get addFirstSelector =>
      'Ajoutez votre premier sélecteur pour commencer';

  @override
  String get selectorExamples => 'Exemples';

  @override
  String get selectorExamplesAdBlocker =>
      'Exemples pour bloquer des publicités :';

  @override
  String get selectorExampleAd1 => 'Bannière publicitaire';

  @override
  String get selectorExampleAd2 => 'Publicité par ID';

  @override
  String get selectorExampleAd3 => 'Iframe publicitaire';

  @override
  String get selectorExampleAd4 => 'Script publicitaire';

  @override
  String get selectorExamplesChapter =>
      'Exemples pour identifier le contenu du chapitre :';

  @override
  String get selectorExampleChapter1 => 'Conteneur de chapitre';

  @override
  String get selectorExampleChapter2 => 'Lecteur de manga';

  @override
  String get selectorExampleChapter3 => 'Images du chapitre';

  @override
  String get selectorExampleChapter4 => 'Contenu de lecture';

  @override
  String get selectorExampleChapter5 => 'Format manga/chapitre-22';

  @override
  String get selectorExampleChapter5Explanation =>
      'Exemple concret : Si votre URL est \"monsite.com/manga/chapitre-22\"';

  @override
  String get selectorUrlFormatDetected =>
      '✅ BONNE NOUVELLE : Le format \"/manga/chapitre-22\" dans l\'URL est déjà détecté automatiquement par le système !\n\nVous n\'avez PAS besoin d\'ajouter un sélecteur CSS si votre site utilise uniquement ce format dans l\'URL.';

  @override
  String get selectorWhenNeeded => 'Quand ajouter un sélecteur CSS ?';

  @override
  String get selectorPracticalExample => 'Exemple pratique :';

  @override
  String get selectorExampleScenario =>
      'Cas : Votre site utilise \"/chapppter-22\" (avec 3 p) au lieu de \"/chapter-22\"';

  @override
  String get selectorStep1 =>
      'Ouvrez la page du chapitre dans votre navigateur';

  @override
  String get selectorStep2 =>
      'Appuyez sur F12 pour ouvrir les outils de développement';

  @override
  String get selectorStep3 =>
      'Cliquez sur l\'icône \"Inspecter\" (ou Ctrl+Shift+C)';

  @override
  String get selectorStep4 =>
      'Cliquez sur le conteneur qui contient les images du chapitre';

  @override
  String get selectorStep5 =>
      'Dans le code HTML, trouvez la classe ou l\'ID du conteneur';

  @override
  String get selectorFillForm => 'Remplissez le formulaire :';

  @override
  String get selectorCssWhenNeededDesc =>
      '⚠️ UNIQUEMENT si votre site a besoin d\'un sélecteur spécifique pour identifier le contenu HTML de la page.\n\nSi le système détecte déjà bien votre chapitre via l\'URL, vous n\'avez PAS besoin d\'ajouter un sélecteur CSS.\n\nAjoutez un sélecteur CSS SEULEMENT si :\n• Le système ne détecte pas correctement le contenu du chapitre\n• Vous voulez bloquer des publicités spécifiques à ce site\n• Le site utilise des classes/IDs particuliers pour le contenu\n\nPour trouver le sélecteur : Ouvrez la page (F12 → Inspecter), trouvez le conteneur des images du chapitre, et utilisez sa classe ou ID (ex: .manga-content, #chapter-images)';

  @override
  String get selectorDomainExampleDesc =>
      'Mettez uniquement le nom de domaine (sans http://, sans www, sans le chemin /manga/chapitre-22)';

  @override
  String get selectorOtherExamples => 'Autres exemples courants :';

  @override
  String get selectorExampleChapter5Desc =>
      'Pour les sites utilisant le format manga/chapitre-22 dans leurs URLs. Exemple : si votre URL est \"site.com/manga/chapitre-22\", utilisez ces sélecteurs pour identifier le contenu.';

  @override
  String get selectorExamplesHint =>
      'Astuce : Utilisez les outils de développement de votre navigateur (F12) pour inspecter les éléments et trouver les sélecteurs CSS appropriés.';

  @override
  String get captchaDetected =>
      'Captcha detectado - El bloqueador de anuncios ha sido desactivado temporalmente';

  @override
  String get captchaResolved =>
      'Captcha resuelto - El bloqueador de anuncios ha sido reactivado';

  @override
  String get scrollPositionSaved => 'Posición de desplazamiento guardada';

  @override
  String get chapterProgressSaved => 'Progreso del capítulo guardado';

  @override
  String get readingOffline => 'Leyendo sin conexión';

  @override
  String get chapterDownloaded => 'Capítulo descargado';

  @override
  String get offlineReadingMode => 'Modo de lectura sin conexión';

  @override
  String get deleteChapterTitle => 'Eliminar capítulo';

  @override
  String deleteChapterMessage(int chapterNumber) {
    return '¿Realmente desea eliminar el capítulo $chapterNumber?';
  }

  @override
  String get deleteAllChaptersTitle => 'Eliminar todos los capítulos';

  @override
  String get deleteAllChaptersMessage =>
      '¿Realmente desea eliminar todos los capítulos descargados de este manga?';

  @override
  String get deleteAllDownloadsTitle => 'Eliminar todos los descargos';

  @override
  String get deleteAllDownloadsMessage =>
      '¿Realmente desea eliminar TODOS los descargos? Esta acción es irreversible.';

  @override
  String get deleteAll => 'Eliminar todo';

  @override
  String get chapterDeleted => 'Capítulo eliminado';

  @override
  String get allChaptersDeleted => 'Todos los capítulos eliminados';

  @override
  String get allDownloadsDeleted => 'Todos los descargos eliminados';

  @override
  String get noChaptersDownloaded => 'Ningún capítulo descargado';

  @override
  String chaptersDownloadedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count capítulos descargados',
      one: '1 capítulo descargado',
      zero: 'Ningún capítulo descargado',
    );
    return '$_temp0';
  }

  @override
  String get readChapter => 'Leer';

  @override
  String get deleteAllChaptersAction => 'Eliminar todos los capítulos';

  @override
  String get deleteAllDownloadsTooltip => 'Eliminar todos los descargos';

  @override
  String get recommendedForYou => 'Recomendado para ti';

  @override
  String get recommendedForYouEmpty =>
      'Añade mangas a tu biblioteca\npara obtener recomendaciones personalizadas.';

  @override
  String recommendedForYouCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count mangas',
      one: '1 manga',
    );
    return '$_temp0';
  }

  @override
  String get recommendedForYouCached =>
      'Recomendaciones en caché (modo sin conexión)';

  @override
  String errorWithMessage(String message) {
    return 'Error: $message';
  }

  @override
  String recommendedBecauseOf(String titles) {
    return 'Porque te gustó $titles';
  }

  @override
  String get yourRating => 'Tu valoración';

  @override
  String get myDataTitle => 'Mis datos';

  @override
  String get myDataSubtitle => 'Ver, exportar o eliminar mis datos (RGPD)';

  @override
  String get gdprIntro =>
      'Conforme al RGPD, tienes derechos sobre tus datos personales. Esta página te permite ejercerlos fácilmente.';

  @override
  String get gdprAccessTitle => 'Ver mis datos';

  @override
  String get gdprAccessSubtitle =>
      'Artículo 15 — resumen de la información almacenada';

  @override
  String get gdprExportTitle => 'Exportar mis datos';

  @override
  String get gdprExportSubtitle =>
      'Artículo 20 — JSON completo copiado al portapapeles';

  @override
  String get gdprLegalDocs => 'Documentos legales';

  @override
  String get gdprDeleteHint =>
      'Para eliminar tu cuenta permanentemente, ve a Perfil → Eliminar cuenta. Esta acción es irreversible.';

  @override
  String get privacyPolicyTitle => 'Política de privacidad';

  @override
  String get termsOfServiceTitle => 'Condiciones de uso';

  @override
  String get myDataInfoBanner =>
      'Conforme al RGPD, tienes derecho a acceder a tus datos, exportarlos y solicitar su eliminación.';

  @override
  String get myDataSectionPersonalData => 'Datos personales';

  @override
  String get myDataSectionMyRights => 'Mis derechos';

  @override
  String get myDataSectionDeletion => 'Eliminación';

  @override
  String get myDataSummaryTitle => 'Resumen de mis datos';

  @override
  String get myDataSummarySubtitle =>
      'Ver una vista general de tus datos almacenados';

  @override
  String get myDataExportSubtitle =>
      'Descargar un archivo JSON completo (artículo 20)';

  @override
  String get privacyPolicySubtitle => 'Leer el documento completo';

  @override
  String get termsOfServiceSubtitle => 'Ver las Condiciones';

  @override
  String get myDataDeleteAccountSubtitle => 'Esta acción es irreversible';

  @override
  String get gdprExportSuccessSnack =>
      'Tus datos han sido copiados al portapapeles (JSON).';

  @override
  String get gdprExportFailedSnack => 'Error en la exportación';

  @override
  String get gdprSummaryLoadFailed => 'Error de carga';

  @override
  String get myDataBackLabel => 'Perfil';

  @override
  String get tosShortVersion =>
      'Manga Tracker se proporciona tal cual, sin garantía. El editor declina toda responsabilidad por el uso no conforme por parte del usuario (contenido ilegal, scraping, etc.).\n\nDocumento completo en el sitio oficial.';

  @override
  String get privacyShortVersion =>
      'Datos recopilados: email, contraseña (hash), biblioteca de manga, preferencias. Ningún dato se vende a terceros. Puedes exportar o eliminar tus datos en cualquier momento.\n\nDocumento completo en el sitio oficial.';

  @override
  String get iAcceptTos => 'Acepto las Condiciones de uso';

  @override
  String get iAcceptPrivacy => 'Acepto la Política de privacidad';

  @override
  String get iAccept => 'Aceptar';

  @override
  String get consentRequired =>
      'Debes aceptar las Condiciones de uso y la Política de privacidad.';

  @override
  String get consentRefreshTitle => 'Nuestras condiciones se han actualizado';

  @override
  String get consentRefreshIntro =>
      'Nuestras condiciones de uso y política de privacidad se han actualizado. Acéptalas para continuar.';

  @override
  String get refuseAndLogout => 'Rechazar y cerrar sesión';

  @override
  String get versionLabel => 'Versión';

  @override
  String get welcomeTitle => '¡Bienvenido!';

  @override
  String get loginSubtitle => 'Inicia sesión en tu cuenta';

  @override
  String get createAccountTitle => 'Crear una cuenta';

  @override
  String get registerSubtitle => 'Empieza a seguir tus lecturas';

  @override
  String get orLoginWith => 'o inicia sesión con';

  @override
  String get orSignUpWith => 'o regístrate con';

  @override
  String get continueWithApple => 'Continuar con Apple';

  @override
  String get loadingApp => 'Cargando…';

  @override
  String get forgotPasswordTitle => 'Contraseña olvidada';

  @override
  String get forgotPasswordIntro =>
      'Introduce tu email. Si existe una cuenta, recibirás un enlace para establecer una nueva contraseña.';

  @override
  String get sendResetLink => 'Enviar enlace';

  @override
  String get resetEmailSentTitle => 'Revisa tu bandeja';

  @override
  String resetEmailSentMessage(String email) {
    return 'Si existe una cuenta para $email, se ha enviado un email con un enlace para establecer una nueva contraseña.\n\nEl enlace expira en 30 minutos.';
  }

  @override
  String get resetPasswordTitle => 'Nueva contraseña';

  @override
  String get resetPasswordIntro =>
      'Establece una nueva contraseña para tu cuenta. Una vez validada, se iniciará sesión automáticamente.';

  @override
  String get confirmReset => 'Confirmar';

  @override
  String get resetTokenExpired =>
      'Enlace inválido o expirado. Solicita uno nuevo.';

  @override
  String get resetPasswordSuccess => 'Contraseña cambiada';

  @override
  String get resetPasswordSuccessHint => 'Has iniciado sesión. Redirigiendo…';

  @override
  String get verifyingEmail => 'Verificando…';

  @override
  String get emailVerifiedSuccess => '¡Email verificado!';

  @override
  String get emailVerifiedHint => 'Iniciando sesión…';

  @override
  String get emailVerifyFailedTitle => 'Enlace inválido o expirado';

  @override
  String get emailVerifyFailedHint =>
      'El enlace que has utilizado ya no es válido. Inicia sesión y solicita uno nuevo desde tu perfil.';

  @override
  String get backToLogin => 'Volver al inicio de sesión';

  @override
  String get verifyEmailBannerMessage =>
      'Verifica tu dirección de email para activar todas las funciones.';

  @override
  String get emailSentShort => 'Enviado';

  @override
  String get resendEmailShort => 'Reenviar';

  @override
  String get recommendedForYouHome => 'Recomendados para ti';

  @override
  String get seeMoreByGenre => 'Ver más por género';

  @override
  String get recommendationsByGenreTitle => 'Recomendaciones por género';

  @override
  String get recommendationsByGenreEmpty =>
      'Aún no hay recomendaciones. Añade mangas a tu biblioteca para obtener sugerencias personalizadas.';

  @override
  String get recommendationsAllTitle => 'Todas las recomendaciones';

  @override
  String get recommendationsAllEmpty => 'Aún no hay recomendaciones para ti.';

  @override
  String get seeAllRecommendations => 'Ver todo';

  @override
  String get browseByGenre => 'Por género';

  @override
  String get recommendationsTabAll => 'Todo';

  @override
  String get recommendationsTabByGenre => 'Por género';

  @override
  String get statsTitle => 'Mis estadísticas';

  @override
  String get statsTotalMangas => 'mangas en tu biblioteca';

  @override
  String statsMemberSince(String date) {
    return 'Miembro desde $date';
  }

  @override
  String get statsTotalChapters => 'Capítulos leídos';

  @override
  String get statsReadingTime => 'Tiempo de lectura estimado';

  @override
  String get statsCompletionRate => 'Tasa de finalización';

  @override
  String get statsLastRead => 'Última lectura';

  @override
  String get statsByStatusTitle => 'Desglose por estado';

  @override
  String get statsByStatusEmpty => 'Aún no hay mangas en tu biblioteca.';

  @override
  String get statsTopGenresTitle => 'Géneros favoritos';

  @override
  String get statsTopGenresEmpty =>
      'Añade mangas para descubrir tus géneros favoritos.';

  @override
  String statsMinutesShort(int count) {
    return '$count min';
  }

  @override
  String statsHoursAndMinutesShort(int hours, int minutes) {
    return '$hours h $minutes min';
  }

  @override
  String statsDaysAndHoursShort(int days, int hours) {
    return '$days d $hours h';
  }

  @override
  String get statusReadLater => 'Para leer';

  @override
  String get statusReading => 'Leyendo';

  @override
  String get statusCaughtUp => 'Al día';

  @override
  String get statusCompleted => 'Completado';

  @override
  String get statsSectionOverview => 'Resumen';

  @override
  String get statsSectionBreakdown => 'Mangas por estado';

  @override
  String get statsSectionGenres => 'Géneros favoritos';

  @override
  String get statsLibraryTotal => 'Mangas en tu biblioteca';

  @override
  String statsMonthsSinceJoin(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Miembro desde hace $count meses',
      one: 'Miembro desde hace 1 mes',
      zero: 'Miembro desde hace menos de un mes',
    );
    return '$_temp0';
  }

  @override
  String statsHeroBadge(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count mangas',
      one: '1 manga',
    );
    return '$_temp0';
  }

  @override
  String get profileMyStats => 'Mis estadísticas';

  @override
  String get profileEditTitle => 'Editar mi perfil';

  @override
  String get profileEditBackLabel => 'Perfil';

  @override
  String get profileEditMenuTitle => 'Editar perfil';

  @override
  String get profileEditMenuSubtitle => 'Foto, nombre, biografía, privacidad';

  @override
  String get profileFieldAvatarUrl => 'URL del avatar';

  @override
  String get profileFieldDisplayName => 'Nombre para mostrar';

  @override
  String get profileFieldBio => 'Biografía';

  @override
  String get profileFieldDateOfBirth => 'Fecha de nacimiento';

  @override
  String get profileFieldGender => 'Género';

  @override
  String get profileGenderNotSet => 'Sin especificar';

  @override
  String get profileGenderMale => 'Masculino';

  @override
  String get profileGenderFemale => 'Femenino';

  @override
  String get profileGenderNonBinary => 'No binario';

  @override
  String get profileGenderPreferNotToSay => 'Prefiero no decirlo';

  @override
  String get profileFieldIsPublic => 'Perfil público';

  @override
  String get profileFieldIsPublicSubtitle => 'Visible para otros usuarios';

  @override
  String get profileSaved => 'Perfil guardado';

  @override
  String get profileSaveFailed => 'No se pudo guardar';

  @override
  String get friendsTitle => 'Amigos';

  @override
  String get friendsTabAccepted => 'Amigos';

  @override
  String get friendsTabPending => 'Solicitudes';

  @override
  String get friendsSearchLabel => 'Buscar un amigo';

  @override
  String get friendsSearchHint =>
      'Escribe un nombre de usuario (mín. 2 caracteres)';

  @override
  String get friendsAddRequest => 'Enviar solicitud';

  @override
  String get friendsAccept => 'Aceptar';

  @override
  String get friendsReject => 'Rechazar';

  @override
  String get friendsRemove => 'Eliminar';

  @override
  String get friendsRequestSent => 'Solicitud enviada';

  @override
  String get friendsError => 'Error';

  @override
  String get friendsEmptyAccepted => 'Aún no tienes amigos';

  @override
  String get friendsEmptyAcceptedSubtitle =>
      'Busca usuarios arriba para agregarlos.';

  @override
  String get friendsEmptyPending => 'Sin solicitudes pendientes';

  @override
  String get friendsEmptyPendingSubtitle =>
      'Las solicitudes recibidas aparecerán aquí.';

  @override
  String get friendsSectionAccepted => 'Mis amigos';

  @override
  String get friendsSectionPending => 'Solicitudes recibidas';

  @override
  String get friendsSearchClear => 'Borrar';

  @override
  String get friendsSearchResults => 'Resultados';

  @override
  String get friendsSearchEmpty => 'Ningún usuario encontrado.';

  @override
  String get profileMyFriends => 'Mis amigos';

  @override
  String get commentsTitle => 'Comentarios';

  @override
  String get commentsEmpty => 'Aún no hay comentarios. ¡Sé el primero!';

  @override
  String get commentsSortRecent => 'Recientes';

  @override
  String get commentsSortTop => 'Popular';

  @override
  String get commentsInputHint => 'Comparte tu opinión (3-2000 caracteres)';

  @override
  String get commentsPost => 'Publicar';

  @override
  String get commentsDelete => 'Eliminar';

  @override
  String get commentsLoadMore => 'Cargar más';

  @override
  String commentsReplyCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count respuestas',
      one: '1 respuesta',
    );
    return '$_temp0';
  }

  @override
  String get timeJustNow => 'justo ahora';

  @override
  String timeMinutesAgo(int count) {
    return 'hace $count min';
  }

  @override
  String timeHoursAgo(int count) {
    return 'hace $count h';
  }

  @override
  String timeDaysAgo(int count) {
    return 'hace $count d';
  }

  @override
  String get shareTitle => 'Compartir este manga';

  @override
  String get shareMessageHint => 'Añadir un mensaje (opcional)';

  @override
  String get shareCancel => 'Cancelar';

  @override
  String get shareSend => 'Enviar';

  @override
  String get shareSuccess => 'Manga compartido';

  @override
  String get shareFailed => 'Error al compartir';

  @override
  String get shareLoadError => 'No se pudieron cargar tus amigos';

  @override
  String get shareNoFriends =>
      'Aún no tienes amigos con quien compartir. Añade en la página Amigos.';

  @override
  String get inboxTitle => 'Recomendaciones recibidas';

  @override
  String get inboxEmpty => 'Aún no hay recomendaciones.';

  @override
  String get inboxBadgeNew => 'NUEVO';

  @override
  String inboxSenderRecommends(String sender) {
    return '$sender recomienda';
  }

  @override
  String inboxSharedYouLabel(String sender) {
    return '$sender compartió contigo';
  }

  @override
  String get inboxFilterAll => 'Todas';

  @override
  String get inboxFilterUnread => 'No leídas';

  @override
  String get inboxFilterRead => 'Leídas';

  @override
  String get inboxGroupToday => 'Hoy';

  @override
  String get inboxGroupYesterday => 'Ayer';

  @override
  String get inboxGroupThisWeek => 'Esta semana';

  @override
  String get inboxGroupOlder => 'Antes';

  @override
  String get inboxEmptyTitle => 'Sin recomendaciones';

  @override
  String get inboxEmptySubtitle =>
      'Pide a tus amigos que compartan sus lecturas favoritas contigo.';

  @override
  String get inboxEmptyFilteredUnread => 'Sin recomendaciones no leídas.';

  @override
  String get inboxEmptyFilteredRead => 'Sin recomendaciones leídas.';

  @override
  String get profileMyInbox => 'Recomendaciones recibidas';

  @override
  String get readingGroupsTitle => 'Lecturas en pareja';

  @override
  String get readingGroupsEmpty =>
      'Aún no hay grupos de lectura. Crea uno desde la página de un manga.';

  @override
  String get readingGroupDetailTitle => 'Grupo de lectura';

  @override
  String get readingGroupMembersTitle => 'Miembros';

  @override
  String get readingGroupOwnerBadge => 'OWNER';

  @override
  String get readingGroupOpenManga => 'Abrir manga';

  @override
  String get readingGroupNotStarted => 'No iniciado';

  @override
  String readingGroupChaptersRead(int count) {
    return 'Cap. $count';
  }

  @override
  String get readingGroupChaptersReadLabel => 'leídos';

  @override
  String readingGroupMembersCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count miembros',
      one: '1 miembro',
    );
    return '$_temp0';
  }

  @override
  String get profileMyReadingGroups => 'Lecturas en pareja';

  @override
  String get profileSectionPublicInfo => 'Información pública';

  @override
  String get profileSectionAbout => 'Sobre ti';

  @override
  String get profileSectionPrivacy => 'Privacidad';

  @override
  String get profileNotSet => 'Sin especificar';

  @override
  String get profileSectionAvatar => 'Avatar';

  @override
  String get profileEditAvatarHeroHint =>
      'La vista previa se actualiza al pegar una URL de imagen.';

  @override
  String get profileEditPickPhoto => 'Elegir una foto';

  @override
  String get profileEditClearAvatar => 'Limpiar';

  @override
  String get profileEditPhotoPickFailed => 'No se pudo seleccionar la foto';

  @override
  String get profileGenderClear => 'Limpiar';

  @override
  String get avatarUrlLabel => 'URL del avatar';

  @override
  String get avatarUrlInvalid => 'La URL debe empezar por http:// o https://';

  @override
  String get profileSectionAccount => 'Cuenta';

  @override
  String get profileFieldUsername => 'Nombre de usuario';

  @override
  String get profileFieldEmail => 'E-mail';

  @override
  String get profileFieldReadOnly => 'Solo lectura';

  @override
  String get profileChangePhoto => 'Cambiar foto';

  @override
  String get changelogCardTitle => 'Notas de versión';

  @override
  String get readingGroupCreateTitle => 'Leer juntos';

  @override
  String get readingGroupCreateNameLabel => 'Nombre del grupo (opcional)';

  @override
  String get readingGroupCreateNameHint => 'ej: Berserk con Lea';

  @override
  String get readingGroupCreateInviteSection => 'Invitar amigos';

  @override
  String get readingGroupCreateConfirm => 'Crear grupo';

  @override
  String get readingGroupCreateFailed => 'Error al crear grupo';

  @override
  String get readingGroupCreateInviteRequired =>
      'Selecciona al menos un amigo para crear el grupo';

  @override
  String get readingGroupDelete => 'Eliminar grupo';

  @override
  String get readingGroupDeleteConfirmTitle => '¿Eliminar este grupo?';

  @override
  String get readingGroupDeleteConfirm =>
      'Esta acción es irreversible. Todos los miembros perderán el acceso al grupo.';

  @override
  String get readingGroupDeleteSuccess => 'Grupo eliminado';

  @override
  String get readingGroupDeleteFailed => 'Error al eliminar el grupo';

  @override
  String get readingGroupSharedReading => 'Lectura compartida';

  @override
  String get readingGroupViewGroup => 'Ver grupo';

  @override
  String get readingGroupChapterShort => 'cap.';

  @override
  String get profileHighlightTitle => 'Nuevas funciones';

  @override
  String get profileNewBadge => 'Nuevo';

  @override
  String get profileFooterBrand => 'MANGA TRACKER';

  @override
  String get readingGroupListSectionTitle => 'Mis grupos';

  @override
  String readingGroupWithLabel(String name) {
    return 'Con $name';
  }

  @override
  String get readingGroupYouLabel => 'Tú';

  @override
  String readingGroupProgressYouVsFriend(
    String you,
    String friend,
    String their,
  ) {
    return 'Tú: cap. $you · $friend: cap. $their';
  }

  @override
  String get readingGroupChapterDash => '—';

  @override
  String get readingGroupSectionHero => 'Lectura en curso';

  @override
  String get readingGroupSectionProgress => 'Progreso';

  @override
  String get readingGroupSectionActions => 'Acciones';

  @override
  String get readingGroupActionsMarkProgress => 'Actualizar mi progreso';

  @override
  String get readingGroupActionsMarkProgressSubtitle =>
      'Abrir la ficha del manga para avanzar';

  @override
  String get readingGroupActionsInvite => 'Invitar a un amigo';

  @override
  String readingGroupActionsCopyFriendLink(String friend) {
    return 'Copiar el enlace de $friend';
  }

  @override
  String readingGroupActionsCopyFriendLinkSubtitle(int chapter) {
    return 'Adaptado al capítulo $chapter';
  }

  @override
  String readingGroupApplyLinkSuccess(int chapter) {
    return 'Enlace guardado en el capítulo $chapter';
  }

  @override
  String readingGroupCopyLinkSuccess(int chapter) {
    return 'Enlace copiado — capítulo $chapter';
  }

  @override
  String get readingGroupCopyLinkFailed =>
      'No se puede adaptar este enlace (formato desconocido)';

  @override
  String get readingGroupActionsInviteSubtitle => 'Añadir a alguien al grupo';

  @override
  String get readingGroupActionsLeave => 'Salir del grupo';

  @override
  String get readingGroupActionsLeaveSubtitle =>
      'Ya no verás el progreso compartido';

  @override
  String get readingGroupActionsDeleteSubtitle =>
      'Eliminar definitivamente para todos los miembros';

  @override
  String get readingGroupLeaveConfirmTitle => '¿Salir de este grupo?';

  @override
  String get readingGroupLeaveConfirm =>
      'Perderás el acceso al progreso compartido.';

  @override
  String get readingGroupLeaveSuccess => 'Has salido del grupo';

  @override
  String get readingGroupLeaveFailed => 'No se pudo salir del grupo';

  @override
  String get readingGroupEmptyTitle => 'Aún no hay lecturas en pareja';

  @override
  String get readingGroupEmptySubtitle =>
      'Empieza un manga con un amigo y seguid juntos vuestro progreso.';

  @override
  String get readingGroupEmptyAction => 'Descubrir un manga';

  @override
  String get readingGroupTotalLabel => 'Total';

  @override
  String readingGroupChaptersTotal(int count) {
    return '$count cap.';
  }

  @override
  String get readingGroupInviteSoonTitle => 'Próximamente';

  @override
  String get readingGroupInviteSoonMessage =>
      'Invitar desde el grupo llegará muy pronto. Por ahora, crea un nuevo grupo desde la ficha del manga.';

  @override
  String get libraryToggleListView => 'Vista de lista';

  @override
  String get libraryToggleCardView => 'Vista de tarjetas';

  @override
  String get libraryShowDownloadedOnly => 'Mostrar solo descargados';

  @override
  String get libraryShowAllMangas => 'Mostrar todos los mangas';

  @override
  String libraryProgressLabel(int read, int total) {
    return '$read de $total capítulos leídos';
  }

  @override
  String votesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count votos',
      one: '1 voto',
      zero: 'Sin votos',
    );
    return '$_temp0';
  }

  @override
  String get detailSectionSimilar => 'Mangas similares';

  @override
  String get rating => 'Valoración';

  @override
  String get anonymousUser => 'Usuario anónimo';

  @override
  String get recommendationsColdStartTitle => 'Descubre mangas populares';

  @override
  String get recommendationsColdStartSubtitle =>
      'Añade tus primeras lecturas para recibir recomendaciones personalizadas';

  @override
  String get friendLibraryError =>
      'No se pudo cargar la biblioteca de este amigo.';

  @override
  String get friendLibraryEmpty => 'Su biblioteca está vacía por ahora.';

  @override
  String friendLibraryCount(int count) {
    return '$count mangas en su biblioteca';
  }

  @override
  String get statsHistoryTitle => 'Lecturas recientes';

  @override
  String get statsActivityTitle => 'Actividad de lectura';

  @override
  String get statsBonusTag => 'Historia extra';

  @override
  String get statsNoHistory =>
      'Aún no hay lecturas registradas. Termina un capítulo en el lector para iniciar tu historial.';

  @override
  String get recommendationsSleepersTitle => '💎 Joyas ocultas';
}
