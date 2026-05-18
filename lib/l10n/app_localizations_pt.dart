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
  String get newChapterNotifications => 'Notificações de novos capítulos';

  @override
  String get newChapterNotificationsEnabled => 'Ativadas';

  @override
  String get newChapterNotificationsDisabled => 'Desativadas';

  @override
  String get manageNotifications => 'Gerenciar notificações';

  @override
  String get notifSectionApp => 'Notificações do aplicativo';

  @override
  String get notifSectionInfo => 'Informações';

  @override
  String get notifNewChaptersTitle => 'Novos capítulos';

  @override
  String get notifNewChaptersSubtitle =>
      'Seja notificado quando seus mangás seguidos publicarem novos capítulos';

  @override
  String get notifFriendReqTitle => 'Pedidos de amizade';

  @override
  String get notifFriendReqSubtitle => 'Alguém quer adicioná-lo como amigo';

  @override
  String get notifSharesTitle => 'Recomendações recebidas';

  @override
  String get notifSharesSubtitle => 'Um amigo compartilha um mangá com você';

  @override
  String get notifPermissionExplanation =>
      'As notificações aparecem apenas quando o aplicativo tem permissão do sistema. Se você não receber nenhuma, ative-as nas configurações do telefone.';

  @override
  String get notifOpenSystemSettings => 'Abrir configurações do sistema';

  @override
  String get pushNotifFriendRequestTitle => 'Novo pedido de amizade';

  @override
  String pushNotifFriendRequestBody(String senderUsername) {
    return '$senderUsername quer adicioná-lo como amigo';
  }

  @override
  String get pushNotifShareTitle => 'Novo mangá compartilhado';

  @override
  String pushNotifShareBody(String senderUsername, String mangaTitle) {
    return '$senderUsername recomenda $mangaTitle';
  }

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
  String get searchTitle => 'Pesquisar';

  @override
  String get searchEmptyHistory => 'Nenhuma pesquisa recente';

  @override
  String get searchPopularGenres => 'Géneros populares';

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

  @override
  String get recommendedForYou => 'Recomendado para você';

  @override
  String get recommendedForYouEmpty =>
      'Adicione mangás à sua biblioteca\npara obter recomendações personalizadas.';

  @override
  String recommendedForYouCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count mangás',
      one: '1 mangá',
    );
    return '$_temp0';
  }

  @override
  String get recommendedForYouCached => 'Recomendações em cache (modo offline)';

  @override
  String errorWithMessage(String message) {
    return 'Erro: $message';
  }

  @override
  String recommendedBecauseOf(String titles) {
    return 'Porque você gostou de $titles';
  }

  @override
  String get yourRating => 'Sua avaliação';

  @override
  String get myDataTitle => 'Meus dados';

  @override
  String get myDataSubtitle =>
      'Ver, exportar ou excluir meus dados (LGPD/RGPD)';

  @override
  String get gdprIntro =>
      'Conforme o RGPD, você tem direitos sobre seus dados pessoais. Esta página permite exercê-los facilmente.';

  @override
  String get gdprAccessTitle => 'Ver meus dados';

  @override
  String get gdprAccessSubtitle =>
      'Artigo 15 — resumo das informações armazenadas';

  @override
  String get gdprExportTitle => 'Exportar meus dados';

  @override
  String get gdprExportSubtitle =>
      'Artigo 20 — JSON completo copiado para a área de transferência';

  @override
  String get gdprLegalDocs => 'Documentos legais';

  @override
  String get gdprDeleteHint =>
      'Para excluir sua conta permanentemente, vá para Perfil → Excluir conta. Esta ação é irreversível.';

  @override
  String get privacyPolicyTitle => 'Política de privacidade';

  @override
  String get termsOfServiceTitle => 'Termos de uso';

  @override
  String get myDataInfoBanner =>
      'Conforme o RGPD, você tem o direito de acessar seus dados, exportá-los e solicitar sua exclusão.';

  @override
  String get myDataSectionPersonalData => 'Dados pessoais';

  @override
  String get myDataSectionMyRights => 'Meus direitos';

  @override
  String get myDataSectionDeletion => 'Exclusão';

  @override
  String get myDataSummaryTitle => 'Resumo dos meus dados';

  @override
  String get myDataSummarySubtitle =>
      'Ver uma visão geral dos seus dados armazenados';

  @override
  String get myDataExportSubtitle =>
      'Baixar um arquivo JSON completo (artigo 20)';

  @override
  String get privacyPolicySubtitle => 'Ler o documento completo';

  @override
  String get termsOfServiceSubtitle => 'Ver os Termos';

  @override
  String get myDataDeleteAccountSubtitle => 'Esta ação é irreversível';

  @override
  String get gdprExportSuccessSnack =>
      'Seus dados foram copiados para a área de transferência (JSON).';

  @override
  String get gdprExportFailedSnack => 'Falha na exportação';

  @override
  String get gdprSummaryLoadFailed => 'Erro de carregamento';

  @override
  String get myDataBackLabel => 'Perfil';

  @override
  String get tosShortVersion =>
      'Manga Tracker é fornecido como está, sem garantia. O editor declina qualquer responsabilidade por uso não conforme do usuário (conteúdo ilegal, scraping, etc.).\n\nDocumento completo no site oficial.';

  @override
  String get privacyShortVersion =>
      'Dados coletados: email, senha (com hash), biblioteca de mangás, preferências. Nenhum dado é vendido a terceiros. Você pode exportar ou excluir seus dados a qualquer momento.\n\nDocumento completo no site oficial.';

  @override
  String get iAcceptTos => 'Aceito os Termos de uso';

  @override
  String get iAcceptPrivacy => 'Aceito a Política de privacidade';

  @override
  String get iAccept => 'Aceitar';

  @override
  String get consentRequired =>
      'Você deve aceitar os Termos de uso e a Política de privacidade.';

  @override
  String get consentRefreshTitle => 'Nossos termos foram atualizados';

  @override
  String get consentRefreshIntro =>
      'Nossos termos de uso e política de privacidade foram atualizados. Aceite-os para continuar.';

  @override
  String get refuseAndLogout => 'Recusar e sair';

  @override
  String get versionLabel => 'Versão';

  @override
  String get welcomeTitle => 'Bem-vindo!';

  @override
  String get loginSubtitle => 'Entre na sua conta';

  @override
  String get createAccountTitle => 'Criar uma conta';

  @override
  String get registerSubtitle => 'Comece a acompanhar suas leituras';

  @override
  String get orLoginWith => 'ou entre com';

  @override
  String get orSignUpWith => 'ou registe-se com';

  @override
  String get continueWithApple => 'Continuar com a Apple';

  @override
  String get loadingApp => 'A carregar…';

  @override
  String get forgotPasswordTitle => 'Senha esquecida';

  @override
  String get forgotPasswordIntro =>
      'Digite seu email. Se houver uma conta, você receberá um link para definir uma nova senha.';

  @override
  String get sendResetLink => 'Enviar link';

  @override
  String get resetEmailSentTitle => 'Verifique sua caixa de entrada';

  @override
  String resetEmailSentMessage(String email) {
    return 'Se houver uma conta para $email, foi enviado um email com um link para definir uma nova senha.\n\nO link expira em 30 minutos.';
  }

  @override
  String get resetPasswordTitle => 'Nova senha';

  @override
  String get resetPasswordIntro =>
      'Defina uma nova senha para sua conta. Após a validação, você será conectado automaticamente.';

  @override
  String get confirmReset => 'Confirmar';

  @override
  String get resetTokenExpired =>
      'Link inválido ou expirado. Solicite um novo.';

  @override
  String get resetPasswordSuccess => 'Senha alterada';

  @override
  String get resetPasswordSuccessHint => 'Você está conectado. Redirecionando…';

  @override
  String get verifyingEmail => 'Verificando…';

  @override
  String get emailVerifiedSuccess => 'Email verificado!';

  @override
  String get emailVerifiedHint => 'Conectando…';

  @override
  String get emailVerifyFailedTitle => 'Link inválido ou expirado';

  @override
  String get emailVerifyFailedHint =>
      'O link que você usou não é mais válido. Faça login e solicite um novo link no seu perfil.';

  @override
  String get backToLogin => 'Voltar ao login';

  @override
  String get verifyEmailBannerMessage =>
      'Verifique seu endereço de email para ativar todos os recursos.';

  @override
  String get emailSentShort => 'Enviado';

  @override
  String get resendEmailShort => 'Reenviar';

  @override
  String get recommendedForYouHome => 'Recomendados para você';

  @override
  String get seeMoreByGenre => 'Ver mais por gênero';

  @override
  String get recommendationsByGenreTitle => 'Recomendações por gênero';

  @override
  String get recommendationsByGenreEmpty =>
      'Ainda não há recomendações. Adicione mangás à sua biblioteca para receber sugestões personalizadas.';

  @override
  String get recommendationsAllTitle => 'Todas as recomendações';

  @override
  String get recommendationsAllEmpty => 'Ainda não há recomendações para você.';

  @override
  String get seeAllRecommendations => 'Ver tudo';

  @override
  String get browseByGenre => 'Por gênero';

  @override
  String get recommendationsTabAll => 'Tudo';

  @override
  String get recommendationsTabByGenre => 'Por gênero';

  @override
  String get statsTitle => 'Minhas estatísticas';

  @override
  String get statsTotalMangas => 'mangás na sua biblioteca';

  @override
  String statsMemberSince(String date) {
    return 'Membro desde $date';
  }

  @override
  String get statsTotalChapters => 'Capítulos lidos';

  @override
  String get statsReadingTime => 'Tempo de leitura estimado';

  @override
  String get statsCompletionRate => 'Taxa de conclusão';

  @override
  String get statsLastRead => 'Última leitura';

  @override
  String get statsByStatusTitle => 'Distribuição por status';

  @override
  String get statsByStatusEmpty => 'Ainda não há mangás na sua biblioteca.';

  @override
  String get statsTopGenresTitle => 'Gêneros favoritos';

  @override
  String get statsTopGenresEmpty =>
      'Adicione mangás para descobrir seus gêneros favoritos.';

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
  String get statusReadLater => 'Para ler';

  @override
  String get statusReading => 'Lendo';

  @override
  String get statusCaughtUp => 'Em dia';

  @override
  String get statusCompleted => 'Concluído';

  @override
  String get statsSectionOverview => 'Visão geral';

  @override
  String get statsSectionBreakdown => 'Mangás por status';

  @override
  String get statsSectionGenres => 'Gêneros favoritos';

  @override
  String get statsLibraryTotal => 'Mangás na sua biblioteca';

  @override
  String statsMonthsSinceJoin(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Membro há $count meses',
      one: 'Membro há 1 mês',
      zero: 'Membro há menos de um mês',
    );
    return '$_temp0';
  }

  @override
  String statsHeroBadge(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count mangás',
      one: '1 mangá',
    );
    return '$_temp0';
  }

  @override
  String get profileMyStats => 'Minhas estatísticas';

  @override
  String get profileEditTitle => 'Editar meu perfil';

  @override
  String get profileEditBackLabel => 'Perfil';

  @override
  String get profileEditMenuTitle => 'Editar perfil';

  @override
  String get profileEditMenuSubtitle =>
      'Foto, nome de exibição, bio, privacidade';

  @override
  String get profileFieldAvatarUrl => 'URL do avatar';

  @override
  String get profileFieldDisplayName => 'Nome de exibição';

  @override
  String get profileFieldBio => 'Bio';

  @override
  String get profileFieldDateOfBirth => 'Data de nascimento';

  @override
  String get profileFieldGender => 'Gênero';

  @override
  String get profileGenderNotSet => 'Não informado';

  @override
  String get profileGenderMale => 'Masculino';

  @override
  String get profileGenderFemale => 'Feminino';

  @override
  String get profileGenderNonBinary => 'Não-binário';

  @override
  String get profileGenderPreferNotToSay => 'Prefiro não dizer';

  @override
  String get profileFieldIsPublic => 'Perfil público';

  @override
  String get profileFieldIsPublicSubtitle => 'Visível para outros usuários';

  @override
  String get profileSaved => 'Perfil salvo';

  @override
  String get profileSaveFailed => 'Falha ao salvar';

  @override
  String get friendsTitle => 'Amigos';

  @override
  String get friendsTabAccepted => 'Amigos';

  @override
  String get friendsTabPending => 'Solicitações';

  @override
  String get friendsSearchLabel => 'Encontrar um amigo';

  @override
  String get friendsSearchHint =>
      'Digite um nome de usuário (min 2 caracteres)';

  @override
  String get friendsAddRequest => 'Enviar solicitação';

  @override
  String get friendsAccept => 'Aceitar';

  @override
  String get friendsReject => 'Recusar';

  @override
  String get friendsRemove => 'Remover';

  @override
  String get friendsRequestSent => 'Solicitação enviada';

  @override
  String get friendsError => 'Erro';

  @override
  String get friendsEmptyAccepted => 'Sem amigos ainda';

  @override
  String get friendsEmptyAcceptedSubtitle =>
      'Pesquise usuários acima para adicioná-los.';

  @override
  String get friendsEmptyPending => 'Nenhuma solicitação pendente';

  @override
  String get friendsEmptyPendingSubtitle =>
      'Solicitações recebidas aparecerão aqui.';

  @override
  String get friendsSectionAccepted => 'Meus amigos';

  @override
  String get friendsSectionPending => 'Solicitações recebidas';

  @override
  String get friendsSearchClear => 'Limpar';

  @override
  String get friendsSearchResults => 'Resultados';

  @override
  String get friendsSearchEmpty => 'Nenhum usuário encontrado.';

  @override
  String get profileMyFriends => 'Meus amigos';

  @override
  String get commentsTitle => 'Comentários';

  @override
  String get commentsEmpty => 'Sem comentários ainda. Seja o primeiro!';

  @override
  String get commentsSortRecent => 'Recentes';

  @override
  String get commentsSortTop => 'Popular';

  @override
  String get commentsInputHint => 'Compartilhe sua opinião (3-2000 caracteres)';

  @override
  String get commentsPost => 'Publicar';

  @override
  String get commentsDelete => 'Excluir';

  @override
  String get commentsLoadMore => 'Carregar mais';

  @override
  String commentsReplyCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count respostas',
      one: '1 resposta',
    );
    return '$_temp0';
  }

  @override
  String get timeJustNow => 'agora mesmo';

  @override
  String timeMinutesAgo(int count) {
    return 'há $count min';
  }

  @override
  String timeHoursAgo(int count) {
    return 'há $count h';
  }

  @override
  String timeDaysAgo(int count) {
    return 'há $count d';
  }

  @override
  String get shareTitle => 'Compartilhar este mangá';

  @override
  String get shareMessageHint => 'Adicionar uma mensagem (opcional)';

  @override
  String get shareCancel => 'Cancelar';

  @override
  String get shareSend => 'Enviar';

  @override
  String get shareSuccess => 'Mangá compartilhado';

  @override
  String get shareFailed => 'Falha ao compartilhar';

  @override
  String get shareLoadError => 'Não foi possível carregar seus amigos';

  @override
  String get shareNoFriends =>
      'Você ainda não tem amigos para compartilhar. Adicione na página Amigos.';

  @override
  String get inboxTitle => 'Recomendações recebidas';

  @override
  String get inboxEmpty => 'Nenhuma recomendação ainda.';

  @override
  String get inboxBadgeNew => 'NOVO';

  @override
  String inboxSenderRecommends(String sender) {
    return '$sender recomenda';
  }

  @override
  String inboxSharedYouLabel(String sender) {
    return '$sender compartilhou com você';
  }

  @override
  String get inboxFilterAll => 'Todas';

  @override
  String get inboxFilterUnread => 'Não lidas';

  @override
  String get inboxFilterRead => 'Lidas';

  @override
  String get inboxGroupToday => 'Hoje';

  @override
  String get inboxGroupYesterday => 'Ontem';

  @override
  String get inboxGroupThisWeek => 'Esta semana';

  @override
  String get inboxGroupOlder => 'Antes';

  @override
  String get inboxEmptyTitle => 'Sem recomendações';

  @override
  String get inboxEmptySubtitle =>
      'Peça aos seus amigos para compartilharem as leituras favoritas deles.';

  @override
  String get inboxEmptyFilteredUnread => 'Sem recomendações não lidas.';

  @override
  String get inboxEmptyFilteredRead => 'Sem recomendações lidas.';

  @override
  String get profileMyInbox => 'Recomendações recebidas';

  @override
  String get readingGroupsTitle => 'Leituras em dupla';

  @override
  String get readingGroupsEmpty =>
      'Ainda não há grupos de leitura. Crie um a partir da página de um mangá.';

  @override
  String get readingGroupDetailTitle => 'Grupo de leitura';

  @override
  String get readingGroupMembersTitle => 'Membros';

  @override
  String get readingGroupOwnerBadge => 'OWNER';

  @override
  String get readingGroupOpenManga => 'Abrir mangá';

  @override
  String get readingGroupNotStarted => 'Não iniciado';

  @override
  String readingGroupChaptersRead(int count) {
    return 'Cap. $count';
  }

  @override
  String get readingGroupChaptersReadLabel => 'lidos';

  @override
  String readingGroupMembersCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count membros',
      one: '1 membro',
    );
    return '$_temp0';
  }

  @override
  String get profileMyReadingGroups => 'Leituras em dupla';

  @override
  String get profileSectionPublicInfo => 'Informações públicas';

  @override
  String get profileSectionAbout => 'Sobre você';

  @override
  String get profileSectionPrivacy => 'Privacidade';

  @override
  String get profileNotSet => 'Não informado';

  @override
  String get profileSectionAvatar => 'Avatar';

  @override
  String get profileEditAvatarHeroHint =>
      'A pré-visualização atualiza quando colares um URL de imagem.';

  @override
  String get profileEditPickPhoto => 'Escolher uma foto';

  @override
  String get profileEditClearAvatar => 'Limpar';

  @override
  String get profileEditPhotoPickFailed => 'Não foi possível selecionar a foto';

  @override
  String get profileGenderClear => 'Limpar';

  @override
  String get avatarUrlLabel => 'URL do avatar';

  @override
  String get avatarUrlInvalid => 'A URL deve começar com http:// ou https://';

  @override
  String get profileSectionAccount => 'Conta';

  @override
  String get profileFieldUsername => 'Nome de usuário';

  @override
  String get profileFieldEmail => 'E-mail';

  @override
  String get profileFieldReadOnly => 'Somente leitura';

  @override
  String get profileChangePhoto => 'Alterar foto';

  @override
  String get changelogCardTitle => 'Notas de versão';

  @override
  String get readingGroupCreateTitle => 'Ler em dupla';

  @override
  String get readingGroupCreateNameLabel => 'Nome do grupo (opcional)';

  @override
  String get readingGroupCreateNameHint => 'ex: Berserk com Lea';

  @override
  String get readingGroupCreateInviteSection => 'Convidar amigos';

  @override
  String get readingGroupCreateConfirm => 'Criar grupo';

  @override
  String get readingGroupCreateFailed => 'Falha ao criar grupo';

  @override
  String get readingGroupCreateInviteRequired =>
      'Seleciona ao menos um amigo para criar o grupo';

  @override
  String get readingGroupDelete => 'Excluir grupo';

  @override
  String get readingGroupDeleteConfirmTitle => 'Excluir este grupo?';

  @override
  String get readingGroupDeleteConfirm =>
      'Esta ação é irreversível. Todos os membros perderão o acesso ao grupo.';

  @override
  String get readingGroupDeleteSuccess => 'Grupo excluído';

  @override
  String get readingGroupDeleteFailed => 'Falha ao excluir o grupo';

  @override
  String get readingGroupSharedReading => 'Leitura compartilhada';

  @override
  String get readingGroupViewGroup => 'Ver grupo';

  @override
  String get readingGroupChapterShort => 'cap.';

  @override
  String get profileHighlightTitle => 'Novas funcionalidades';

  @override
  String get profileNewBadge => 'Novo';

  @override
  String get profileFooterBrand => 'MANGA TRACKER';

  @override
  String get readingGroupListSectionTitle => 'Os meus grupos';

  @override
  String readingGroupWithLabel(String name) {
    return 'Com $name';
  }

  @override
  String get readingGroupYouLabel => 'Tu';

  @override
  String readingGroupProgressYouVsFriend(
    String you,
    String friend,
    String their,
  ) {
    return 'Tu: cap. $you · $friend: cap. $their';
  }

  @override
  String get readingGroupChapterDash => '—';

  @override
  String get readingGroupSectionHero => 'A ler atualmente';

  @override
  String get readingGroupSectionProgress => 'Progresso';

  @override
  String get readingGroupSectionActions => 'Ações';

  @override
  String get readingGroupActionsMarkProgress => 'Atualizar o meu progresso';

  @override
  String get readingGroupActionsMarkProgressSubtitle =>
      'Abrir a página do manga para avançar';

  @override
  String get readingGroupActionsInvite => 'Convidar um amigo';

  @override
  String readingGroupActionsCopyFriendLink(String friend) {
    return 'Copiar o link de $friend';
  }

  @override
  String readingGroupActionsCopyFriendLinkSubtitle(int chapter) {
    return 'Adaptado ao capítulo $chapter';
  }

  @override
  String readingGroupApplyLinkSuccess(int chapter) {
    return 'Link salvo no capítulo $chapter';
  }

  @override
  String readingGroupCopyLinkSuccess(int chapter) {
    return 'Link copiado — capítulo $chapter';
  }

  @override
  String get readingGroupCopyLinkFailed =>
      'Não é possível adaptar este link (formato desconhecido)';

  @override
  String get readingGroupActionsInviteSubtitle => 'Adicionar alguém ao grupo';

  @override
  String get readingGroupActionsLeave => 'Sair do grupo';

  @override
  String get readingGroupActionsLeaveSubtitle =>
      'Deixarás de ver o progresso partilhado';

  @override
  String get readingGroupActionsDeleteSubtitle =>
      'Eliminar definitivamente para todos os membros';

  @override
  String get readingGroupLeaveConfirmTitle => 'Sair deste grupo?';

  @override
  String get readingGroupLeaveConfirm =>
      'Perderás o acesso ao progresso partilhado.';

  @override
  String get readingGroupLeaveSuccess => 'Saíste do grupo';

  @override
  String get readingGroupLeaveFailed => 'Não foi possível sair do grupo';

  @override
  String get readingGroupEmptyTitle => 'Ainda sem leituras a dois';

  @override
  String get readingGroupEmptySubtitle =>
      'Começa um manga com um amigo e acompanhem o progresso juntos.';

  @override
  String get readingGroupEmptyAction => 'Descobrir um manga';

  @override
  String get readingGroupTotalLabel => 'Total';

  @override
  String readingGroupChaptersTotal(int count) {
    return '$count cap.';
  }

  @override
  String get readingGroupInviteSoonTitle => 'Em breve';

  @override
  String get readingGroupInviteSoonMessage =>
      'Convidar a partir do grupo chega muito em breve. Por agora, cria um novo grupo na página do manga.';

  @override
  String get libraryToggleListView => 'Vista em lista';

  @override
  String get libraryToggleCardView => 'Vista em cartões';

  @override
  String get libraryShowDownloadedOnly => 'Mostrar apenas transferidos';

  @override
  String get libraryShowAllMangas => 'Mostrar todos os mangas';

  @override
  String libraryProgressLabel(int read, int total) {
    return '$read de $total capítulos lidos';
  }

  @override
  String votesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count votos',
      one: '1 voto',
      zero: 'Sem votos',
    );
    return '$_temp0';
  }

  @override
  String get detailSectionSimilar => 'Mangas semelhantes';
}
