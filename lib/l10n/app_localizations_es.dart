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
  String get googlePopupBlocked =>
      'Ventana de inicio de sesión bloqueada por el navegador — permite las ventanas emergentes para este sitio e inténtalo de nuevo';

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
  String get chapterNotFound => 'Capítulo no encontrado';

  @override
  String get previousChapterTooltip => 'Capítulo anterior';

  @override
  String get nextChapterTooltip => 'Capítulo siguiente';

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
  String get downloads => 'Descargas';

  @override
  String get manageDownloads => 'Gestionar descargas';

  @override
  String get manageDownloadsSubtitle =>
      'Ver y eliminar los capítulos descargados';

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
      'Añadir un patrón personalizado para este formato';

  @override
  String get customSelectors => 'Selectores personalizados';

  @override
  String get manageCustomSelectors => 'Gestionar selectores';

  @override
  String get manageCustomSelectorsSubtitle =>
      'Añade selectores CSS personalizados para bloquear anuncios o identificar el contenido';

  @override
  String get addCustomSelector => 'Añadir un selector';

  @override
  String get selectorDomainLabel => 'Dominio (ej.: ejemplo.com)';

  @override
  String get selectorCssLabel => 'Selector CSS';

  @override
  String get selectorTypeLabel => 'Tipo de selector';

  @override
  String get selectorTypeUrlPattern => 'Patrón de URL';

  @override
  String get selectorUrlPatternLabel => 'Patrón de URL (regex)';

  @override
  String get selectorUrlPatternHint =>
      'Ejemplo: /chapter-(\\d+)/ para detectar /chapter-22';

  @override
  String get selectorExamplesUrlPattern => 'Ejemplos de patrones de URL:';

  @override
  String get selectorExampleUrlPattern => 'Ejemplo: /chapter-22';

  @override
  String get selectorExampleUrlPatternExplanation =>
      'Si tu sitio usa \"/chapter-22\" en la URL y el sistema no lo detecta automáticamente:';

  @override
  String get selectorUrlPatternExampleDesc =>
      'Usa una expresión regular (regex) con (\\d+) para capturar el número del capítulo.\n\nEste patrón se aplicará a TODOS los sitios.\n\nEjemplos de patrones:\n• /chapter-(\\d+)/ → detecta /chapter-22\n• /chapppter-(\\d+)/ → detecta /chapppter-22 (con 3 p)\n• /manga/chapter-(\\d+)/ → detecta /manga/chapter-22\n• /episode-(\\d+)/ → detecta /episode-22';

  @override
  String get selectorUrlPatternGlobal =>
      'El patrón se aplicará a TODOS los sitios. No es necesario indicar un dominio.';

  @override
  String get selectorTypeAdBlocker => 'Bloqueador de anuncios';

  @override
  String get selectorTypeChapterContent => 'Contenido del capítulo';

  @override
  String get selectorDescriptionLabel => 'Descripción (opcional)';

  @override
  String get selectorDescriptionHint => 'Descripción del selector';

  @override
  String get selectorRequiredFields => 'Todos los campos son obligatorios';

  @override
  String get selectorAdded => 'Selector añadido';

  @override
  String get deleteSelector => 'Eliminar el selector';

  @override
  String get deleteSelectorConfirm =>
      '¿Seguro que quieres eliminar este selector?';

  @override
  String get selectorDeleted => 'Selector eliminado';

  @override
  String get selectorsExported => 'Selectores exportados al portapapeles';

  @override
  String get importSelectors => 'Importar selectores';

  @override
  String get selectorsJsonLabel => 'JSON de los selectores';

  @override
  String get import => 'Importar';

  @override
  String selectorsImported(String count) {
    return '$count selector(es) importado(s)';
  }

  @override
  String get selectorsReadyToShare =>
      '¡Selectores listos para compartir! Pega el JSON en Discord.';

  @override
  String get exportSelectors => 'Exportar';

  @override
  String get shareSelectors => 'Compartir';

  @override
  String get noCustomSelectors => 'Ningún selector personalizado';

  @override
  String get addFirstSelector => 'Añade tu primer selector para empezar';

  @override
  String get selectorExamples => 'Ejemplos';

  @override
  String get selectorExamplesAdBlocker => 'Ejemplos para bloquear anuncios:';

  @override
  String get selectorExampleAd1 => 'Banner publicitario';

  @override
  String get selectorExampleAd2 => 'Anuncio por ID';

  @override
  String get selectorExampleAd3 => 'Iframe publicitario';

  @override
  String get selectorExampleAd4 => 'Script publicitario';

  @override
  String get selectorExamplesChapter =>
      'Ejemplos para identificar el contenido del capítulo:';

  @override
  String get selectorExampleChapter1 => 'Contenedor del capítulo';

  @override
  String get selectorExampleChapter2 => 'Lector de manga';

  @override
  String get selectorExampleChapter3 => 'Imágenes del capítulo';

  @override
  String get selectorExampleChapter4 => 'Contenido de lectura';

  @override
  String get selectorExampleChapter5 => 'Formato manga/chapter-22';

  @override
  String get selectorExampleChapter5Explanation =>
      'Ejemplo concreto: si tu URL es \"misitio.com/manga/chapter-22\"';

  @override
  String get selectorUrlFormatDetected =>
      'BUENA NOTICIA: ¡el formato \"/manga/chapter-22\" en la URL ya lo detecta automáticamente el sistema!\n\nNO necesitas añadir un selector CSS si tu sitio solo usa este formato en la URL.';

  @override
  String get selectorWhenNeeded => '¿Cuándo añadir un selector CSS?';

  @override
  String get selectorPracticalExample => 'Ejemplo práctico:';

  @override
  String get selectorExampleScenario =>
      'Caso: tu sitio usa \"/chapppter-22\" (con 3 p) en lugar de \"/chapter-22\"';

  @override
  String get selectorStep1 => 'Abre la página del capítulo en tu navegador';

  @override
  String get selectorStep2 =>
      'Pulsa F12 para abrir las herramientas de desarrollo';

  @override
  String get selectorStep3 =>
      'Haz clic en el icono \"Inspeccionar\" (o Ctrl+Mayús+C)';

  @override
  String get selectorStep4 =>
      'Haz clic en el contenedor que contiene las imágenes del capítulo';

  @override
  String get selectorStep5 =>
      'En el código HTML, busca la clase o el ID del contenedor';

  @override
  String get selectorFillForm => 'Rellena el formulario:';

  @override
  String get selectorCssWhenNeededDesc =>
      'SOLO si tu sitio necesita un selector específico para identificar el contenido HTML de la página.\n\nSi el sistema ya detecta bien tu capítulo a través de la URL, NO necesitas añadir un selector CSS.\n\nAñade un selector CSS SOLO si:\n• El sistema no detecta correctamente el contenido del capítulo\n• Quieres bloquear anuncios específicos de este sitio\n• El sitio usa clases/IDs particulares para el contenido\n\nPara encontrar el selector: abre la página (F12 → Inspeccionar), busca el contenedor de las imágenes del capítulo y usa su clase o ID (ej.: .manga-content, #chapter-images)';

  @override
  String get selectorDomainExampleDesc =>
      'Escribe solo el nombre de dominio (sin http://, sin www, sin la ruta /manga/chapter-22)';

  @override
  String get selectorOtherExamples => 'Otros ejemplos habituales:';

  @override
  String get selectorExampleChapter5Desc =>
      'Para los sitios que usan el formato manga/chapter-22 en sus URL. Ejemplo: si tu URL es \"site.com/manga/chapter-22\", usa estos selectores para identificar el contenido.';

  @override
  String get selectorExamplesHint =>
      'Consejo: usa las herramientas de desarrollo de tu navegador (F12) para inspeccionar los elementos y encontrar los selectores CSS adecuados.';

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
      'Aún no hay lecturas registradas. Actualiza tu progreso para iniciar tu historial.';

  @override
  String get reportMoreChaptersCta => 'Reportar más capítulos';

  @override
  String get reportMoreChaptersDialogTitle => 'Reportar más capítulos';

  @override
  String get reportMoreChaptersExplainer =>
      '¿Has leído más capítulos que el total conocido? Indica el nuevo total: contará para tu progreso y se contrastará con los reportes de otros lectores.';

  @override
  String get reportMoreChaptersInputLabel => 'Nuevo total de capítulos';

  @override
  String reportMoreChaptersInvalidLow(int total) {
    return 'El total debe ser mayor que $total.';
  }

  @override
  String reportMoreChaptersInvalidHigh(int max) {
    return 'El total no puede superar $max.';
  }

  @override
  String get reportMoreChaptersSubmit => 'Reportar';

  @override
  String get reportMoreChaptersSuccess =>
      '¡Gracias! El número de capítulos se ha actualizado.';

  @override
  String get reportMoreChaptersError =>
      'No se puede enviar el reporte en este momento. Inténtalo más tarde.';

  @override
  String get reportMoreChaptersErrorInvalid =>
      'El total conocido cambió mientras tanto. Recarga la página e inténtalo de nuevo.';

  @override
  String get reportMoreChaptersErrorThrottled =>
      'Demasiados reportes enviados recientemente. Inténtalo de nuevo en un momento.';

  @override
  String get reportMoreChaptersOffline => 'No disponible sin conexión.';

  @override
  String get dismissRecommendationSheetTitle =>
      'No recomendarme más este título';

  @override
  String dismissRecommendationSheetSubtitle(String title) {
    return '«$title» desaparecerá de tus recomendaciones. Podrás cambiar de opinión.';
  }

  @override
  String get dismissReasonAlreadyRead => 'Ya leído';

  @override
  String get dismissReasonAlreadyReadHint =>
      'Ya lo he leído, no queda nada por descubrir';

  @override
  String get dismissReasonNotInterested => 'No me interesa';

  @override
  String get dismissReasonNotInterestedHint => 'No es mi estilo';

  @override
  String get dismissReasonSeenElsewhere => 'Visto en otro sitio';

  @override
  String get dismissReasonSeenElsewhereHint => 'En anime, drama o película';

  @override
  String dismissRecommendationSuccess(String title) {
    return '«$title» ya no aparecerá en tus recomendaciones';
  }

  @override
  String get dismissRecommendationUndo => 'Deshacer';

  @override
  String get dismissRecommendationUndone => 'Recomendación restaurada';

  @override
  String get dismissRecommendationError =>
      'No se ha podido descartar este título ahora mismo. Inténtalo más tarde.';

  @override
  String get dismissRecommendationOffline => 'No disponible sin conexión.';

  @override
  String get dismissRecommendationAccessibility =>
      'Mantén pulsado para dejar de recomendar este título';

  @override
  String get recommendationsSleepersTitle => '💎 Joyas ocultas';

  @override
  String get sessionRejectedBanner =>
      'Sesión caducada: mostrando tus datos guardados';

  @override
  String get sessionRejectedAction => 'Volver a iniciar sesión';

  @override
  String get challengeLoopTitle => 'Verificación bloqueada';

  @override
  String get challengeLoopMessage =>
      'La verificación antirrobot de este sitio no se completa: se recarga una y otra vez. Abre la página en tu navegador para completarla y luego vuelve aquí.';

  @override
  String get challengeLoopOpenBrowser => 'Abrir en el navegador';

  @override
  String get readerRefresh => 'Actualizar la página';

  @override
  String get readerMoreActions => 'Más acciones';

  @override
  String get readerDownloadPage => 'Descargar esta página';

  @override
  String get adBlockerEnableAction => 'Activar el bloqueador de anuncios';

  @override
  String get adBlockerDisableAction => 'Desactivar el bloqueador de anuncios';

  @override
  String get adBlockerInteractiveEnable =>
      'Activar el modo de detección de anuncios';

  @override
  String get adBlockerInteractiveDisable =>
      'Desactivar el modo de detección de anuncios';

  @override
  String get adBlockerEnabledNotice =>
      'Bloqueador de anuncios activado en esta página.';

  @override
  String get adBlockerDisabledNotice =>
      'Bloqueador desactivado — se recargó la página para restaurar el contenido.';

  @override
  String get adBlockerInteractiveOnNotice =>
      'Modo de detección activo — toca un anuncio para bloquearlo.';

  @override
  String get adBlockerInteractiveOffNotice => 'Modo de detección desactivado.';
}
