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
  String get accountInformation => 'Información de la cuenta';

  @override
  String get email => 'Correo electrónico';

  @override
  String get notifications => 'Notificaciones';

  @override
  String get manageNotifications => 'Gestionar notificaciones';

  @override
  String get theme => 'Tema';

  @override
  String get lightMode => 'Modo claro';

  @override
  String get darkMode => 'Modo oscuro';

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
}
