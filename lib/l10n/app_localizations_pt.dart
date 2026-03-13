// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Portuguese (`pt`).
class AppLocalizationsPt extends AppLocalizations {
  AppLocalizationsPt([String locale = 'pt']) : super(locale);

  @override
  String get appTitle => 'MangaTracker';

  @override
  String get welcomeBack => 'Bem-vindo de volta';

  @override
  String get emailAddress => 'Endereço de e-mail';

  @override
  String get password => 'Senha';

  @override
  String get forgotPassword => 'Esqueceu a senha?';

  @override
  String get login => 'Entrar';

  @override
  String get googleLoginFailed => 'Falha no login com Google';

  @override
  String get loginWithGoogle => 'Entrar com Google';

  @override
  String get back => 'Voltar';

  @override
  String get signUp => 'Cadastrar';

  @override
  String get invalidCredentials => 'Credenciais inválidas';

  @override
  String get unknownError => 'Erro desconhecido';

  @override
  String get trending => 'Em alta';

  @override
  String get popular => 'Popular';

  @override
  String get newMangas => 'Novo';

  @override
  String get offlineMode => 'Modo offline';

  @override
  String get offlineModeNoCache => 'Modo offline - Sem dados em cache';

  @override
  String get offlineModeActionQueued => 'Modo offline - Ação na fila';

  @override
  String pendingActions(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'ões',
      one: '',
      zero: 'ões',
    );
    String _temp1 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 's',
      one: '',
      zero: 's',
    );
    return '$count ação$_temp0 pendente$_temp1';
  }

  @override
  String get retry => 'Tentar novamente';

  @override
  String get error => 'Erro';

  @override
  String get library => 'Biblioteca';

  @override
  String get search => 'Pesquisar';

  @override
  String get profile => 'Perfil';

  @override
  String get account => 'Conta';

  @override
  String get settings => 'Configurações';

  @override
  String get actions => 'Ações';

  @override
  String get changePassword => 'Alterar senha';

  @override
  String get changePasswordSubtitle => 'Altere sua senha de login';

  @override
  String get accountInformation => 'Informações da conta';

  @override
  String get email => 'E-mail';

  @override
  String get notifications => 'Notificações';

  @override
  String get newChapterNotifications => 'Notifications nouveaux chapitres';

  @override
  String get newChapterNotificationsEnabled => 'Activées';

  @override
  String get newChapterNotificationsDisabled => 'Désactivées';

  @override
  String get manageNotifications => 'Gerenciar notificações';

  @override
  String get theme => 'Tema';

  @override
  String get lightMode => 'Modo claro';

  @override
  String get darkMode => 'Modo escuro';

  @override
  String get systemMode => 'Sistema';

  @override
  String get language => 'Idioma';

  @override
  String get selectLanguage => 'Selecionar idioma';

  @override
  String get french => 'Francês';

  @override
  String get english => 'Inglês';

  @override
  String get logout => 'Sair';

  @override
  String get logoutSubtitle => 'Sair da sua conta';

  @override
  String get confirmLogout => 'Sair';

  @override
  String get confirmLogoutMessage => 'Tem certeza de que deseja sair?';

  @override
  String get deleteAccount => 'Excluir conta';

  @override
  String get deleteAccountSubtitle => 'Ação irreversível';

  @override
  String get confirmDeleteAccount => 'Excluir conta';

  @override
  String get confirmDeleteAccountMessage =>
      'Esta ação é irreversível. Todos os seus dados serão permanentemente excluídos e não poderão ser recuperados.';

  @override
  String get cancel => 'Cancelar';

  @override
  String get save => 'Salvar';

  @override
  String get delete => 'Excluir';

  @override
  String get passwordChangedSuccess => 'Senha alterada com sucesso';

  @override
  String get passwordChangeError => 'Erro ao alterar a senha';

  @override
  String get accountDeletedSuccess => 'Conta excluída com sucesso';

  @override
  String get accountDeleteError => 'Erro ao excluir a conta';

  @override
  String get userInfoLoadError =>
      'Não foi possível carregar as informações do usuário';

  @override
  String get user => 'Usuário';

  @override
  String get comingSoon => 'Em breve';

  @override
  String get comingSoonAvatar => 'Em breve: alterar avatar';

  @override
  String get whatsNew => 'O que há de novo?';

  @override
  String get version => 'Versão';

  @override
  String get newFeaturesAvailable => 'Novos recursos disponíveis';

  @override
  String get currentVersion => 'Versão atual';

  @override
  String get great => 'Ótimo!';

  @override
  String get authorizationRequired => 'Autorização necessária';

  @override
  String get modifyLink => 'Modificar link';

  @override
  String get removeLink => 'Remover link';

  @override
  String get chapterSkip => 'Pular capítulo';

  @override
  String get validateReading => 'Validar leitura';

  @override
  String get addToLibrary => 'Adicionar à biblioteca';

  @override
  String get removeFromLibrary => 'Remover da biblioteca';

  @override
  String get updateStatus => 'Atualizar status';

  @override
  String get reading => 'Lendo';

  @override
  String get completed => 'Concluído';

  @override
  String get onHold => 'Em espera';

  @override
  String get dropped => 'Abandonado';

  @override
  String get planToRead => 'Planejado';

  @override
  String get reReading => 'Relendo';

  @override
  String get chapters => 'Capítulos';

  @override
  String get readChapters => 'Capítulos lidos';

  @override
  String get totalChapters => 'Total de capítulos';

  @override
  String get associatedNames => 'Nomes associados';

  @override
  String associatedNamesCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count nomes',
      one: '$count nome',
      zero: 'Nenhum nome',
    );
    return '$_temp0';
  }

  @override
  String get saveProgress => 'Salvar progresso';

  @override
  String get description => 'Descrição';

  @override
  String get authors => 'Autores';

  @override
  String get genres => 'Gêneros';

  @override
  String get recommendations => 'Recomendações';

  @override
  String get loading => 'Carregando...';

  @override
  String get noData => 'Nenhum dado disponível';

  @override
  String get noResults => 'Nenhum resultado';

  @override
  String get noAccount => 'Não tem uma conta?';

  @override
  String get home => 'Início';

  @override
  String get myAccount => 'Minha conta';

  @override
  String get offlineModeCached => 'Modo offline - Dados em cache';

  @override
  String get biometricAuthFailed => 'Autenticação biométrica falhou';

  @override
  String get biometricAuth => 'Login biométrico';

  @override
  String get addLink => 'Adicionar link';

  @override
  String get addOrModifyLink => 'Adicionar ou modificar link';

  @override
  String get linkUrlPlaceholder => 'https://exemplo.com';

  @override
  String get validate => 'Validar';

  @override
  String get invalidLink =>
      'Link inválido. O link deve começar com http:// ou https://';

  @override
  String get linkSaved => 'Link salvo!';

  @override
  String get linkRemoved => 'Link removido!';

  @override
  String get readOnline => 'Ler online';

  @override
  String get manageLink => 'Gerenciar link';

  @override
  String get recommendedMangas => 'Mangás recomendados';

  @override
  String get noRecommendationsAvailable => 'Nenhuma recomendação disponível.';

  @override
  String get close => 'Fechar';

  @override
  String get changeStatus => 'Alterar status';

  @override
  String get mangaAddedToLibrary => 'Mangá adicionado à biblioteca';

  @override
  String get mangaMarkedAs => 'Mangá marcado como';

  @override
  String get readLater => 'Ler mais tarde';

  @override
  String get upToDate => 'Atualizado';

  @override
  String get addToReadLater => 'Adicionar a \"Ler mais tarde\"';

  @override
  String get mangaRemovedFromLibrary => 'Mangá removido da biblioteca';

  @override
  String get searchPlaceholder => 'Pesquisar Mangás, Manwhas...';

  @override
  String get year => 'Ano';

  @override
  String get status => 'Status';

  @override
  String get author => 'Autor';

  @override
  String get artist => 'Artista';

  @override
  String get synopsis => 'Sinopse';

  @override
  String get seeMore => 'Ver mais';

  @override
  String get seeLess => 'Ver menos';

  @override
  String get all => 'Todos';

  @override
  String get newReleases => 'Novos lançamentos';

  @override
  String get chapter => 'Capítulo';

  @override
  String chaptersCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count capítulos',
      one: '$count capítulo',
      zero: 'Nenhum capítulo',
    );
    return '$_temp0';
  }

  @override
  String chapterSaved(String chapter) {
    return 'Capítulo $chapter salvo';
  }

  @override
  String get chapterRead => 'lido';

  @override
  String get chapterUnread => 'não lido';

  @override
  String mangaAddedToLibrarySuccess(String title) {
    return '$title foi adicionado à biblioteca!';
  }

  @override
  String get errorAddingToLibrary => 'Erro ao adicionar à biblioteca.';

  @override
  String get errorUpdatingChapter => 'Erro ao atualizar o capítulo.';

  @override
  String cannotOpenLink(String url) {
    return 'Não é possível abrir o link: $url';
  }

  @override
  String get searchHistoryTitle => 'Histórico de pesquisa';

  @override
  String get searchEmptyStateMessage =>
      'Pesquise por um mangá, manhwa ou manhua';

  @override
  String get clear => 'Limpar';

  @override
  String get biometricAuthTitle => 'Autenticação biométrica';

  @override
  String get biometricAuthSubtitle =>
      'Usar impressão digital ou Face ID para entrar rapidamente';

  @override
  String get enableBiometricAuth => 'Autenticação biométrica ativada';

  @override
  String get disableBiometricAuth => 'Autenticação biométrica desativada';

  @override
  String get biometricAuthEnabled => 'Ativada';

  @override
  String get biometricAuthDisabled => 'Desativada';

  @override
  String get biometricAuthFirstTimeTitle => 'Ativar autenticação biométrica?';

  @override
  String get biometricAuthFirstTimeMessage =>
      'Gostaria de usar sua impressão digital ou Face ID para entrar rapidamente no futuro?';

  @override
  String get biometricAuthNotAvailable =>
      'A autenticação biométrica não está disponível neste dispositivo';

  @override
  String get biometricAuthRequiresReconnect =>
      'Para ativar a autenticação biométrica, faça login novamente';

  @override
  String get or => 'Ou';

  @override
  String get startTrackingNow => 'Comece a rastrear sua leitura agora';

  @override
  String get username => 'Nome de usuário';

  @override
  String get confirmPassword => 'Confirmar';

  @override
  String get alreadyHaveAccount => 'Já tem uma conta?';

  @override
  String get newPassword => 'Nova senha';

  @override
  String get validationEmailRequired =>
      'Por favor, insira seu endereço de e-mail';

  @override
  String get validationEmailInvalid =>
      'Por favor, insira um endereço de e-mail válido';

  @override
  String get validationPasswordRequired => 'Por favor, insira sua senha';

  @override
  String get validationPasswordLength =>
      'Sua senha deve ter entre 8 e 64 caracteres';

  @override
  String get validationPasswordComplexity =>
      'Sua senha deve conter pelo menos uma letra minúscula, uma letra maiúscula e um caractere especial';

  @override
  String get validationConfirmPasswordRequired =>
      'Por favor, confirme sua senha';

  @override
  String get validationPasswordsDoNotMatch => 'As senhas não coincidem';

  @override
  String get showPassword => 'Mostrar senha';

  @override
  String get hidePassword => 'Ocultar senha';

  @override
  String get emailAlreadyUsed => 'Este endereço de e-mail já está registrado';

  @override
  String get networkError => 'Verifique sua conexão com a internet';

  @override
  String get timeoutError =>
      'O servidor está demorando muito para responder. Tente novamente.';

  @override
  String get passwordStrengthLabel => 'Força da senha';

  @override
  String get passwordStrengthWeak => 'Fraca';

  @override
  String get passwordStrengthMedium => 'Média';

  @override
  String get passwordStrengthStrong => 'Forte';

  @override
  String get yes => 'Sim';

  @override
  String get no => 'Não';

  @override
  String get yesValidate => 'Sim, validar';

  @override
  String chapterSkipMessage(String prev, String next) {
    return 'Você está pulando do capítulo $prev para $next.\nMarcar $prev como lido?';
  }

  @override
  String validateReadingMessage(String chapter) {
    return 'Você terminou o capítulo $chapter?';
  }

  @override
  String get validateReadingHint => 'Seu progresso será salvo automaticamente.';

  @override
  String get adBlockerTitle => 'Bloqueador de anúncios';

  @override
  String get adBlockerDescription =>
      'O bloqueador de anúncios bloqueia automaticamente anúncios em sites de leitura.\n\nSe você quiser adicionar links ou sugerir melhorias para o bloqueio de anúncios, junte-se ao nosso servidor Discord!';

  @override
  String get adBlockerTooltip => 'Informações sobre o bloqueador de anúncios';

  @override
  String get joinDiscord => 'Entrar no Discord';

  @override
  String get joinDiscordSubtitle =>
      'Compartilhe suas sugestões e relate problemas';

  @override
  String get contactUs => 'Entre em contato';

  @override
  String get downloads => 'Téléchargements';

  @override
  String get manageDownloads => 'Gérer les téléchargements';

  @override
  String get manageDownloadsSubtitle =>
      'Voir et supprimer les chapitres téléchargés';

  @override
  String get discordLinkError => 'Não é possível abrir o link do Discord';

  @override
  String get urlCopied => 'URL copiada para a área de transferência';

  @override
  String get urlCopyError => 'Erro ao copiar URL';

  @override
  String get copyUrl => 'Copiar URL';

  @override
  String get progressUpdated => 'Progresso atualizado';

  @override
  String get invalidUrl => 'URL inválida';

  @override
  String get webModeProgressTracking => 'Modo Web - Rastreamento de progresso';

  @override
  String get webModeProgressDescription =>
      'Para rastrear seu progresso, cole a URL do capítulo que você está lendo atualmente.';

  @override
  String get chapterUrlLabel => 'URL do capítulo';

  @override
  String get updateProgress => 'Atualizar progresso';

  @override
  String get openInNewTab => 'Abrir em nova aba';

  @override
  String get linkUrlLabel => 'URL do site de scan';

  @override
  String get linkFormatInfo => 'Formato de capítulo necessário';

  @override
  String get linkFormatDescription =>
      'Inclua o número do capítulo na URL para permitir o salvamento automático do progresso.\n\nFormatos aceitos:\n• /capítulo-23/ ou /chapter-23/\n• /c23/ ou /ch23/\n• /ep-23/ ou /episode-23/\n• ?chapter=23 ou ?num=24';

  @override
  String get linkFormatWarning =>
      'Nenhum formato de capítulo detectado. O link redirecionará para a página do mangá (não um capítulo específico).';

  @override
  String get linkFormatDetected =>
      'Formato de capítulo detectado! O progresso será salvo automaticamente.';

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
      'Captcha detectado - O bloqueador de anúncios foi temporariamente desativado';

  @override
  String get captchaResolved =>
      'Captcha resolvido - O bloqueador de anúncios foi reativado';

  @override
  String get scrollPositionSaved => 'Posição de rolagem salva';

  @override
  String get chapterProgressSaved => 'Progresso do capítulo salvo';

  @override
  String get readingOffline => 'Lendo offline';

  @override
  String get chapterDownloaded => 'Capítulo baixado';

  @override
  String get offlineReadingMode => 'Modo de leitura offline';

  @override
  String get deleteChapterTitle => 'Excluir capítulo';

  @override
  String deleteChapterMessage(int chapterNumber) {
    return 'Você realmente deseja excluir o capítulo $chapterNumber?';
  }

  @override
  String get deleteAllChaptersTitle => 'Excluir todos os capítulos';

  @override
  String get deleteAllChaptersMessage =>
      'Você realmente deseja excluir todos os capítulos baixados deste mangá?';

  @override
  String get deleteAllDownloadsTitle => 'Excluir todos os downloads';

  @override
  String get deleteAllDownloadsMessage =>
      'Você realmente deseja excluir TODOS os downloads? Esta ação é irreversível.';

  @override
  String get deleteAll => 'Excluir tudo';

  @override
  String get chapterDeleted => 'Capítulo excluído';

  @override
  String get allChaptersDeleted => 'Todos os capítulos excluídos';

  @override
  String get allDownloadsDeleted => 'Todos os downloads excluídos';

  @override
  String get noChaptersDownloaded => 'Nenhum capítulo baixado';

  @override
  String chaptersDownloadedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count capítulos baixados',
      one: '1 capítulo baixado',
      zero: 'Nenhum capítulo baixado',
    );
    return '$_temp0';
  }

  @override
  String get readChapter => 'Ler';

  @override
  String get deleteAllChaptersAction => 'Excluir todos os capítulos';

  @override
  String get deleteAllDownloadsTooltip => 'Excluir todos os downloads';
}
