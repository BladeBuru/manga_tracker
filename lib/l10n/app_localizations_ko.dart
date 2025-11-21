// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Korean (`ko`).
class AppLocalizationsKo extends AppLocalizations {
  AppLocalizationsKo([String locale = 'ko']) : super(locale);

  @override
  String get appTitle => 'MangaTracker';

  @override
  String get welcomeBack => '다시 오신 것을 환영합니다';

  @override
  String get emailAddress => '이메일 주소';

  @override
  String get password => '비밀번호';

  @override
  String get forgotPassword => '비밀번호를 잊으셨나요?';

  @override
  String get login => '로그인';

  @override
  String get back => '뒤로';

  @override
  String get signUp => '회원가입';

  @override
  String get invalidCredentials => '잘못된 자격 증명';

  @override
  String get unknownError => '알 수 없는 오류';

  @override
  String get trending => '인기';

  @override
  String get popular => '인기';

  @override
  String get newMangas => '신규';

  @override
  String get offlineMode => '오프라인 모드';

  @override
  String get offlineModeNoCache => '오프라인 모드 - 캐시된 데이터 없음';

  @override
  String get offlineModeActionQueued => '오프라인 모드 - 작업 대기 중';

  @override
  String pendingActions(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count개',
      one: '$count개',
      zero: '',
    );
    return '대기 중인 작업 $_temp0';
  }

  @override
  String get retry => '다시 시도';

  @override
  String get error => '오류';

  @override
  String get library => '라이브러리';

  @override
  String get search => '검색';

  @override
  String get profile => '프로필';

  @override
  String get account => '계정';

  @override
  String get settings => '설정';

  @override
  String get actions => '작업';

  @override
  String get changePassword => '비밀번호 변경';

  @override
  String get changePasswordSubtitle => '로그인 비밀번호 변경';

  @override
  String get accountInformation => '계정 정보';

  @override
  String get email => '이메일';

  @override
  String get notifications => '알림';

  @override
  String get newChapterNotifications => 'Notifications nouveaux chapitres';

  @override
  String get newChapterNotificationsEnabled => 'Activées';

  @override
  String get newChapterNotificationsDisabled => 'Désactivées';

  @override
  String get manageNotifications => '알림 관리';

  @override
  String get theme => '테마';

  @override
  String get lightMode => '라이트 모드';

  @override
  String get darkMode => '다크 모드';

  @override
  String get language => '언어';

  @override
  String get selectLanguage => '언어 선택';

  @override
  String get french => '프랑스어';

  @override
  String get english => '영어';

  @override
  String get logout => '로그아웃';

  @override
  String get logoutSubtitle => '계정에서 로그아웃';

  @override
  String get confirmLogout => '로그아웃';

  @override
  String get confirmLogoutMessage => '정말 로그아웃하시겠습니까?';

  @override
  String get deleteAccount => '계정 삭제';

  @override
  String get deleteAccountSubtitle => '되돌릴 수 없는 작업';

  @override
  String get confirmDeleteAccount => '계정 삭제';

  @override
  String get confirmDeleteAccountMessage =>
      '이 작업은 되돌릴 수 없습니다. 모든 데이터가 영구적으로 삭제되며 복구할 수 없습니다.';

  @override
  String get cancel => '취소';

  @override
  String get save => '저장';

  @override
  String get delete => '삭제';

  @override
  String get passwordChangedSuccess => '비밀번호가 성공적으로 변경되었습니다';

  @override
  String get passwordChangeError => '비밀번호 변경 오류';

  @override
  String get accountDeletedSuccess => '계정이 성공적으로 삭제되었습니다';

  @override
  String get accountDeleteError => '계정 삭제 오류';

  @override
  String get userInfoLoadError => '사용자 정보를 불러올 수 없습니다';

  @override
  String get user => '사용자';

  @override
  String get comingSoon => '곧 출시';

  @override
  String get comingSoonAvatar => '곧 출시: 아바타 변경';

  @override
  String get whatsNew => '새로운 기능';

  @override
  String get version => '버전';

  @override
  String get newFeaturesAvailable => '새로운 기능 사용 가능';

  @override
  String get currentVersion => '현재 버전';

  @override
  String get great => '좋습니다!';

  @override
  String get authorizationRequired => '인증 필요';

  @override
  String get modifyLink => '링크 수정';

  @override
  String get removeLink => '링크 제거';

  @override
  String get chapterSkip => '챕터 건너뛰기';

  @override
  String get validateReading => '읽기 확인';

  @override
  String get addToLibrary => '라이브러리에 추가';

  @override
  String get removeFromLibrary => '라이브러리에서 제거';

  @override
  String get updateStatus => '상태 업데이트';

  @override
  String get reading => '읽는 중';

  @override
  String get completed => '완료';

  @override
  String get onHold => '보류';

  @override
  String get dropped => '중단';

  @override
  String get planToRead => '읽을 예정';

  @override
  String get reReading => '재읽기';

  @override
  String get chapters => '챕터';

  @override
  String get readChapters => '읽은 챕터';

  @override
  String get totalChapters => '전체 챕터';

  @override
  String get associatedNames => '관련 이름';

  @override
  String associatedNamesCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count개 이름',
      one: '$count개 이름',
      zero: '이름 없음',
    );
    return '$_temp0';
  }

  @override
  String get saveProgress => '진행 상황 저장';

  @override
  String get description => '설명';

  @override
  String get authors => '작가';

  @override
  String get genres => '장르';

  @override
  String get recommendations => '추천';

  @override
  String get loading => '로딩 중...';

  @override
  String get noData => '데이터 없음';

  @override
  String get noResults => '결과 없음';

  @override
  String get noAccount => '계정이 없으신가요?';

  @override
  String get home => '홈';

  @override
  String get myAccount => '내 계정';

  @override
  String get offlineModeCached => '오프라인 모드 - 캐시된 데이터';

  @override
  String get biometricAuthFailed => '생체 인증 실패';

  @override
  String get biometricAuth => '생체 인증 로그인';

  @override
  String get addLink => '링크 추가';

  @override
  String get addOrModifyLink => '링크 추가 또는 수정';

  @override
  String get linkUrlPlaceholder => 'https://example.com';

  @override
  String get validate => '확인';

  @override
  String get invalidLink => '잘못된 링크. 링크는 http:// 또는 https://로 시작해야 합니다';

  @override
  String get linkSaved => '링크가 저장되었습니다!';

  @override
  String get linkRemoved => '링크가 제거되었습니다!';

  @override
  String get readOnline => '온라인으로 읽기';

  @override
  String get manageLink => '링크 관리';

  @override
  String get recommendedMangas => '추천 만화';

  @override
  String get noRecommendationsAvailable => '추천이 없습니다.';

  @override
  String get close => '닫기';

  @override
  String get changeStatus => '상태 변경';

  @override
  String get mangaAddedToLibrary => '만화가 라이브러리에 추가되었습니다';

  @override
  String get mangaMarkedAs => '만화를 표시';

  @override
  String get readLater => '나중에 읽기';

  @override
  String get upToDate => '최신';

  @override
  String get addToReadLater => '\"나중에 읽기\"에 추가';

  @override
  String get mangaRemovedFromLibrary => '만화가 라이브러리에서 제거되었습니다';

  @override
  String get searchPlaceholder => '만화, 만화 검색...';

  @override
  String get year => '연도';

  @override
  String get status => '상태';

  @override
  String get author => '작가';

  @override
  String get artist => '아티스트';

  @override
  String get synopsis => '줄거리';

  @override
  String get seeMore => '더 보기';

  @override
  String get seeLess => '접기';

  @override
  String get all => '전체';

  @override
  String get newReleases => '신작';

  @override
  String get chapter => '챕터';

  @override
  String chaptersCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count챕터',
      one: '$count챕터',
      zero: '챕터 없음',
    );
    return '$_temp0';
  }

  @override
  String chapterSaved(String chapter) {
    return '챕터 $chapter 저장됨';
  }

  @override
  String get chapterRead => '읽음';

  @override
  String get chapterUnread => '읽지 않음';

  @override
  String mangaAddedToLibrarySuccess(String title) {
    return '$title이(가) 라이브러리에 추가되었습니다!';
  }

  @override
  String get errorAddingToLibrary => '라이브러리에 추가하는 중 오류가 발생했습니다.';

  @override
  String get errorUpdatingChapter => '챕터 업데이트 중 오류가 발생했습니다.';

  @override
  String cannotOpenLink(String url) {
    return '링크를 열 수 없습니다: $url';
  }

  @override
  String get searchHistoryTitle => '검색 기록';

  @override
  String get searchEmptyStateMessage => '만화, 만화 또는 만화 검색';

  @override
  String get clear => '지우기';

  @override
  String get biometricAuthTitle => '생체 인증';

  @override
  String get biometricAuthSubtitle => '지문 또는 Face ID를 사용하여 빠르게 로그인';

  @override
  String get enableBiometricAuth => '생체 인증이 활성화되었습니다';

  @override
  String get disableBiometricAuth => '생체 인증이 비활성화되었습니다';

  @override
  String get biometricAuthEnabled => '활성화됨';

  @override
  String get biometricAuthDisabled => '비활성화됨';

  @override
  String get biometricAuthFirstTimeTitle => '생체 인증을 활성화하시겠습니까?';

  @override
  String get biometricAuthFirstTimeMessage =>
      '향후 지문 또는 Face ID를 사용하여 빠르게 로그인하시겠습니까?';

  @override
  String get biometricAuthNotAvailable => '이 기기에서는 생체 인증을 사용할 수 없습니다';

  @override
  String get biometricAuthRequiresReconnect => '생체 인증을 활성화하려면 다시 로그인하세요';

  @override
  String get or => '또는';

  @override
  String get startTrackingNow => '지금 읽기를 추적하기 시작하세요';

  @override
  String get username => '사용자 이름';

  @override
  String get confirmPassword => '확인';

  @override
  String get alreadyHaveAccount => '이미 계정이 있으신가요?';

  @override
  String get newPassword => '새 비밀번호';

  @override
  String get validationEmailRequired => '이메일 주소를 입력해주세요';

  @override
  String get validationEmailInvalid => '유효한 이메일 주소를 입력해주세요';

  @override
  String get validationPasswordRequired => '비밀번호를 입력해주세요';

  @override
  String get validationPasswordLength => '비밀번호는 8자 이상 64자 이하여야 합니다';

  @override
  String get validationPasswordComplexity =>
      '비밀번호에는 최소한 하나의 소문자, 하나의 대문자 및 하나의 특수 문자가 포함되어야 합니다';

  @override
  String get validationConfirmPasswordRequired => '비밀번호를 확인해주세요';

  @override
  String get validationPasswordsDoNotMatch => '비밀번호가 일치하지 않습니다';

  @override
  String get showPassword => '비밀번호 표시';

  @override
  String get hidePassword => '비밀번호 숨기기';

  @override
  String get emailAlreadyUsed => '이 이메일 주소는 이미 등록되어 있습니다';

  @override
  String get networkError => '인터넷 연결을 확인하세요';

  @override
  String get timeoutError => '서버 응답이 너무 오래 걸립니다. 다시 시도해주세요.';

  @override
  String get passwordStrengthLabel => '비밀번호 강도';

  @override
  String get passwordStrengthWeak => '약함';

  @override
  String get passwordStrengthMedium => '보통';

  @override
  String get passwordStrengthStrong => '강함';

  @override
  String get yes => '예';

  @override
  String get no => '아니오';

  @override
  String get yesValidate => '예, 확인';

  @override
  String chapterSkipMessage(String prev, String next) {
    return '챕터 $prev에서 $next로 건너뜁니다.\n$prev을(를) 읽음으로 표시하시겠습니까?';
  }

  @override
  String validateReadingMessage(String chapter) {
    return '챕터 $chapter을(를) 읽으셨나요?';
  }

  @override
  String get validateReadingHint => '진행 상황이 자동으로 저장됩니다.';

  @override
  String get adBlockerTitle => '광고 차단기';

  @override
  String get adBlockerDescription =>
      '광고 차단기는 읽기 사이트의 광고를 자동으로 차단합니다.\n\n링크를 추가하거나 광고 차단 개선 사항을 제안하려면 Discord 서버에 참여하세요!';

  @override
  String get adBlockerTooltip => '광고 차단기 정보';

  @override
  String get joinDiscord => 'Discord 참여';

  @override
  String get joinDiscordSubtitle => '제안을 공유하고 문제를 보고하세요';

  @override
  String get contactUs => '문의하기';

  @override
  String get downloads => 'Téléchargements';

  @override
  String get manageDownloads => 'Gérer les téléchargements';

  @override
  String get manageDownloadsSubtitle =>
      'Voir et supprimer les chapitres téléchargés';

  @override
  String get discordLinkError => 'Discord 링크를 열 수 없습니다';

  @override
  String get urlCopied => 'URL이 클립보드에 복사되었습니다';

  @override
  String get urlCopyError => 'URL 복사 오류';

  @override
  String get copyUrl => 'URL 복사';

  @override
  String get progressUpdated => '진행 상황이 업데이트되었습니다';

  @override
  String get invalidUrl => '잘못된 URL';

  @override
  String get webModeProgressTracking => '웹 모드 - 진행 상황 추적';

  @override
  String get webModeProgressDescription =>
      '진행 상황을 추적하려면 현재 읽고 있는 챕터의 URL을 붙여넣으세요.';

  @override
  String get chapterUrlLabel => '챕터 URL';

  @override
  String get updateProgress => '진행 상황 업데이트';

  @override
  String get openInNewTab => '새 탭에서 열기';

  @override
  String get linkUrlLabel => '스캔 사이트 URL';

  @override
  String get linkFormatInfo => '챕터 형식 필요';

  @override
  String get linkFormatDescription =>
      '자동 진행 상황 저장을 활성화하려면 URL에 챕터 번호를 포함하세요.\n\n허용되는 형식:\n• /챕터-23/ 또는 /chapter-23/\n• /c23/ 또는 /ch23/\n• /ep-23/ 또는 /episode-23/\n• ?chapter=23 또는 ?num=24';

  @override
  String get linkFormatWarning =>
      '챕터 형식이 감지되지 않았습니다. 링크는 만화 페이지로 리디렉션됩니다(특정 챕터가 아님).';

  @override
  String get linkFormatDetected => '챕터 형식이 감지되었습니다! 진행 상황이 자동으로 저장됩니다.';

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
}
