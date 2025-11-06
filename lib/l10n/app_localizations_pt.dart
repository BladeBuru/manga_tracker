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
  String get manageNotifications => 'Gerenciar notificações';

  @override
  String get theme => 'Tema';

  @override
  String get lightMode => 'Modo claro';

  @override
  String get darkMode => 'Modo escuro';

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
}
