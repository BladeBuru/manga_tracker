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
  String get googleLoginConfigError =>
      'Login com Google indisponível (erro de configuração do app)';

  @override
  String get googlePopupBlocked =>
      'Janela de login bloqueada pelo navegador — permita pop-ups para este site e tente novamente';

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
  String get searchNoResults => 'Nenhum resultado encontrado';

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
  String get searchLoadFailed => 'A pesquisa falhou';

  @override
  String get searchLoadMoreFailed =>
      'Não foi possível carregar mais resultados';

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
  String get changePasswordTitle => 'Alterar minha senha';

  @override
  String get changePasswordIntro =>
      'Digite sua senha atual e escolha uma nova. Seus outros dispositivos serão desconectados.';

  @override
  String get currentPasswordLabel => 'Senha atual';

  @override
  String get newPasswordLabel => 'Nova senha';

  @override
  String get confirmNewPasswordLabel => 'Confirmar a nova senha';

  @override
  String get changePasswordSuccess => 'Senha alterada';

  @override
  String get changePasswordSuccessHint =>
      'Seus outros dispositivos foram desconectados. Voltando ao perfil…';

  @override
  String get changePasswordWrongCurrent => 'A senha atual está incorreta';

  @override
  String get changePasswordSocialAccount =>
      'Esta conta usa o login do Google: não há senha para alterar';

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
  String get chapterNotFound => 'Capítulo não encontrado';

  @override
  String get previousChapterTooltip => 'Capítulo anterior';

  @override
  String get nextChapterTooltip => 'Próximo capítulo';

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
  String get downloads => 'Downloads';

  @override
  String get manageDownloads => 'Gerenciar downloads';

  @override
  String get manageDownloadsSubtitle => 'Ver e excluir os capítulos baixados';

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
      'Adicionar um padrão personalizado para este formato';

  @override
  String get customSelectors => 'Seletores personalizados';

  @override
  String get manageCustomSelectors => 'Gerenciar seletores';

  @override
  String get manageCustomSelectorsSubtitle =>
      'Adicione seletores CSS personalizados para bloquear anúncios ou identificar o conteúdo';

  @override
  String get addCustomSelector => 'Adicionar um seletor';

  @override
  String get selectorDomainLabel => 'Domínio (ex.: exemplo.com)';

  @override
  String get selectorCssLabel => 'Seletor CSS';

  @override
  String get selectorTypeLabel => 'Tipo de seletor';

  @override
  String get selectorTypeUrlPattern => 'Padrão de URL';

  @override
  String get selectorUrlPatternLabel => 'Padrão de URL (regex)';

  @override
  String get selectorUrlPatternHint =>
      'Exemplo: /chapter-(\\d+)/ para detectar /chapter-22';

  @override
  String get selectorExamplesUrlPattern => 'Exemplos de padrões de URL:';

  @override
  String get selectorExampleUrlPattern => 'Exemplo: /chapter-22';

  @override
  String get selectorExampleUrlPatternExplanation =>
      'Se o seu site usa \"/chapter-22\" na URL e o sistema não o detecta automaticamente:';

  @override
  String get selectorUrlPatternExampleDesc =>
      'Use uma expressão regular (regex) com (\\d+) para capturar o número do capítulo.\n\nEste padrão será aplicado a TODOS os sites.\n\nExemplos de padrões:\n• /chapter-(\\d+)/ → detecta /chapter-22\n• /chapppter-(\\d+)/ → detecta /chapppter-22 (com 3 p)\n• /manga/chapter-(\\d+)/ → detecta /manga/chapter-22\n• /episode-(\\d+)/ → detecta /episode-22';

  @override
  String get selectorUrlPatternGlobal =>
      'O padrão será aplicado a TODOS os sites. Não é necessário informar um domínio.';

  @override
  String get selectorTypeAdBlocker => 'Bloqueador de anúncios';

  @override
  String get selectorTypeChapterContent => 'Conteúdo do capítulo';

  @override
  String get selectorDescriptionLabel => 'Descrição (opcional)';

  @override
  String get selectorDescriptionHint => 'Descrição do seletor';

  @override
  String get selectorRequiredFields => 'Todos os campos são obrigatórios';

  @override
  String get selectorAdded => 'Seletor adicionado';

  @override
  String get deleteSelector => 'Excluir o seletor';

  @override
  String get deleteSelectorConfirm =>
      'Tem certeza de que deseja excluir este seletor?';

  @override
  String get selectorDeleted => 'Seletor excluído';

  @override
  String get selectorsExported =>
      'Seletores exportados para a área de transferência';

  @override
  String get importSelectors => 'Importar seletores';

  @override
  String get selectorsJsonLabel => 'JSON dos seletores';

  @override
  String get import => 'Importar';

  @override
  String selectorsImported(String count) {
    return '$count seletor(es) importado(s)';
  }

  @override
  String get selectorsReadyToShare =>
      'Seletores prontos para compartilhar! Cole o JSON no Discord.';

  @override
  String get exportSelectors => 'Exportar';

  @override
  String get shareSelectors => 'Compartilhar';

  @override
  String get noCustomSelectors => 'Nenhum seletor personalizado';

  @override
  String get addFirstSelector => 'Adicione seu primeiro seletor para começar';

  @override
  String get selectorExamples => 'Exemplos';

  @override
  String get selectorExamplesAdBlocker => 'Exemplos para bloquear anúncios:';

  @override
  String get selectorExampleAd1 => 'Banner publicitário';

  @override
  String get selectorExampleAd2 => 'Anúncio por ID';

  @override
  String get selectorExampleAd3 => 'Iframe publicitário';

  @override
  String get selectorExampleAd4 => 'Script publicitário';

  @override
  String get selectorExamplesChapter =>
      'Exemplos para identificar o conteúdo do capítulo:';

  @override
  String get selectorExampleChapter1 => 'Contêiner do capítulo';

  @override
  String get selectorExampleChapter2 => 'Leitor de mangá';

  @override
  String get selectorExampleChapter3 => 'Imagens do capítulo';

  @override
  String get selectorExampleChapter4 => 'Conteúdo de leitura';

  @override
  String get selectorExampleChapter5 => 'Formato manga/chapter-22';

  @override
  String get selectorExampleChapter5Explanation =>
      'Exemplo concreto: se a sua URL for \"meusite.com/manga/chapter-22\"';

  @override
  String get selectorUrlFormatDetected =>
      'BOA NOTÍCIA: o formato \"/manga/chapter-22\" na URL já é detectado automaticamente pelo sistema!\n\nVocê NÃO precisa adicionar um seletor CSS se o seu site usa apenas este formato na URL.';

  @override
  String get selectorWhenNeeded => 'Quando adicionar um seletor CSS?';

  @override
  String get selectorPracticalExample => 'Exemplo prático:';

  @override
  String get selectorExampleScenario =>
      'Caso: o seu site usa \"/chapppter-22\" (com 3 p) em vez de \"/chapter-22\"';

  @override
  String get selectorStep1 => 'Abra a página do capítulo no seu navegador';

  @override
  String get selectorStep2 =>
      'Pressione F12 para abrir as ferramentas de desenvolvedor';

  @override
  String get selectorStep3 =>
      'Clique no ícone \"Inspecionar\" (ou Ctrl+Shift+C)';

  @override
  String get selectorStep4 =>
      'Clique no contêiner que contém as imagens do capítulo';

  @override
  String get selectorStep5 =>
      'No código HTML, encontre a classe ou o ID do contêiner';

  @override
  String get selectorFillForm => 'Preencha o formulário:';

  @override
  String get selectorCssWhenNeededDesc =>
      'SOMENTE se o seu site precisar de um seletor específico para identificar o conteúdo HTML da página.\n\nSe o sistema já detecta corretamente o seu capítulo pela URL, você NÃO precisa adicionar um seletor CSS.\n\nAdicione um seletor CSS SOMENTE se:\n• O sistema não detecta corretamente o conteúdo do capítulo\n• Você quer bloquear anúncios específicos deste site\n• O site usa classes/IDs particulares para o conteúdo\n\nPara encontrar o seletor: abra a página (F12 → Inspecionar), encontre o contêiner das imagens do capítulo e use sua classe ou ID (ex.: .manga-content, #chapter-images)';

  @override
  String get selectorDomainExampleDesc =>
      'Informe apenas o nome do domínio (sem http://, sem www, sem o caminho /manga/chapter-22)';

  @override
  String get selectorOtherExamples => 'Outros exemplos comuns:';

  @override
  String get selectorExampleChapter5Desc =>
      'Para sites que usam o formato manga/chapter-22 em suas URLs. Exemplo: se a sua URL for \"site.com/manga/chapter-22\", use estes seletores para identificar o conteúdo.';

  @override
  String get selectorExamplesHint =>
      'Dica: use as ferramentas de desenvolvedor do seu navegador (F12) para inspecionar os elementos e encontrar os seletores CSS adequados.';

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

  @override
  String get rating => 'Avaliação';

  @override
  String get anonymousUser => 'Usuário anônimo';

  @override
  String get recommendationsColdStartTitle => 'Descubra mangás populares';

  @override
  String get recommendationsColdStartSubtitle =>
      'Adicione suas primeiras leituras para receber recomendações personalizadas';

  @override
  String get friendLibraryError =>
      'Não foi possível carregar a biblioteca deste amigo.';

  @override
  String get friendLibraryEmpty => 'A biblioteca dele está vazia por enquanto.';

  @override
  String friendLibraryCount(int count) {
    return '$count mangás na biblioteca dele';
  }

  @override
  String get statsHistoryTitle => 'Leituras recentes';

  @override
  String get statsActivityTitle => 'Atividade de leitura';

  @override
  String get statsBonusTag => 'História extra';

  @override
  String get statsNoHistory =>
      'Nenhuma leitura registrada ainda. Atualize seu progresso para iniciar seu histórico.';

  @override
  String get reportMoreChaptersCta => 'Informar mais capítulos';

  @override
  String get reportMoreChaptersDialogTitle => 'Informar mais capítulos';

  @override
  String get reportMoreChaptersExplainer =>
      'Leu mais capítulos do que o total conhecido? Informe o novo total: ele contará para o seu progresso e será verificado com os relatos de outros leitores.';

  @override
  String get reportMoreChaptersInputLabel => 'Novo total de capítulos';

  @override
  String reportMoreChaptersInvalidLow(int total) {
    return 'O total deve ser maior que $total.';
  }

  @override
  String reportMoreChaptersInvalidHigh(int max) {
    return 'O total não pode exceder $max.';
  }

  @override
  String get reportMoreChaptersSubmit => 'Informar';

  @override
  String get reportMoreChaptersSuccess =>
      'Obrigado! O número de capítulos foi atualizado.';

  @override
  String get reportMoreChaptersError =>
      'Não foi possível enviar o relato agora. Tente novamente mais tarde.';

  @override
  String get reportMoreChaptersErrorInvalid =>
      'O total conhecido mudou nesse meio-tempo. Recarregue a página e tente novamente.';

  @override
  String get reportMoreChaptersErrorThrottled =>
      'Muitos relatos enviados recentemente. Tente novamente daqui a pouco.';

  @override
  String get reportMoreChaptersOffline => 'Indisponível offline.';

  @override
  String get dismissRecommendationSheetTitle =>
      'Não recomendar mais este título';

  @override
  String dismissRecommendationSheetSubtitle(String title) {
    return '«$title» vai desaparecer das tuas recomendações. Podes mudar de ideias mais tarde.';
  }

  @override
  String get dismissReasonAlreadyRead => 'Já li';

  @override
  String get dismissReasonAlreadyReadHint =>
      'Já li, não há nada de novo para descobrir';

  @override
  String get dismissReasonNotInterested => 'Sem interesse';

  @override
  String get dismissReasonNotInterestedHint => 'Não é o meu género';

  @override
  String get dismissReasonSeenElsewhere => 'Vi noutro lado';

  @override
  String get dismissReasonSeenElsewhereHint => 'Em anime, drama ou filme';

  @override
  String dismissRecommendationSuccess(String title) {
    return '«$title» não voltará a aparecer nas tuas recomendações';
  }

  @override
  String get dismissRecommendationUndo => 'Anular';

  @override
  String get dismissRecommendationUndone => 'Recomendação reposta';

  @override
  String get dismissRecommendationError =>
      'Não foi possível descartar este título agora. Tenta mais tarde.';

  @override
  String get dismissRecommendationOffline => 'Indisponível offline.';

  @override
  String get dismissRecommendationAccessibility =>
      'Toque longo para deixar de recomendar este título';

  @override
  String get recommendationsSleepersTitle => '💎 Joias escondidas';

  @override
  String get sessionRejectedBanner =>
      'Sessão expirada — a mostrar os seus dados guardados';

  @override
  String get sessionRejectedAction => 'Iniciar sessão novamente';

  @override
  String get challengeLoopTitle => 'Verificação bloqueada';

  @override
  String get challengeLoopMessage =>
      'A verificação antirrobô deste site não é concluída: fica a recarregar sem parar. Abra a página no seu navegador para a concluir e depois volte aqui.';

  @override
  String get challengeLoopOpenBrowser => 'Abrir no navegador';

  @override
  String get readerRefresh => 'Atualizar a página';

  @override
  String get readerMoreActions => 'Mais ações';

  @override
  String get readerDownloadPage => 'Baixar esta página';

  @override
  String get adBlockerEnableAction => 'Ativar o bloqueador de anúncios';

  @override
  String get adBlockerDisableAction => 'Desativar o bloqueador de anúncios';

  @override
  String get adBlockerInteractiveEnable =>
      'Ativar o modo de deteção de anúncios';

  @override
  String get adBlockerInteractiveDisable =>
      'Desativar o modo de deteção de anúncios';

  @override
  String get adBlockerEnabledNotice =>
      'Bloqueador de anúncios ativado nesta página.';

  @override
  String get adBlockerDisabledNotice =>
      'Bloqueador desativado — página recarregada para restaurar o conteúdo.';

  @override
  String get adBlockerInteractiveOnNotice =>
      'Modo de deteção ativo — toque num anúncio para o bloquear.';

  @override
  String get adBlockerInteractiveOffNotice => 'Modo de deteção desativado.';
}
