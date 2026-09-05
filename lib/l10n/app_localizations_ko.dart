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
  String get googleLoginFailed => 'Google 로그인 실패';

  @override
  String get googleLoginConfigError => 'Google 로그인을 사용할 수 없습니다 (앱 구성 오류)';

  @override
  String get googlePopupBlocked =>
      '브라우저가 로그인 창을 차단했습니다. 이 사이트의 팝업을 허용한 후 다시 시도하세요';

  @override
  String get loginWithGoogle => 'Google로 로그인';

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
  String get searchNoResults => '검색 결과가 없습니다';

  @override
  String searchResultsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '결과 $count개',
    );
    return '$_temp0';
  }

  @override
  String get searchLoadFailed => '검색에 실패했습니다';

  @override
  String get searchLoadMoreFailed => '추가 결과를 불러오지 못했습니다';

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
  String get changePasswordTitle => '비밀번호 변경';

  @override
  String get changePasswordIntro =>
      '현재 비밀번호를 입력한 후 새 비밀번호를 설정하세요. 다른 기기는 로그아웃됩니다.';

  @override
  String get currentPasswordLabel => '현재 비밀번호';

  @override
  String get newPasswordLabel => '새 비밀번호';

  @override
  String get confirmNewPasswordLabel => '새 비밀번호 확인';

  @override
  String get changePasswordSuccess => '비밀번호가 변경되었습니다';

  @override
  String get changePasswordSuccessHint => '다른 기기는 로그아웃되었습니다. 프로필로 돌아갑니다…';

  @override
  String get changePasswordWrongCurrent => '현재 비밀번호가 올바르지 않습니다';

  @override
  String get changePasswordSocialAccount =>
      '이 계정은 Google 로그인을 사용하므로 변경할 비밀번호가 없습니다';

  @override
  String get accountInformation => '계정 정보';

  @override
  String get email => '이메일';

  @override
  String get notifications => '알림';

  @override
  String get newChapterNotifications => '새 챕터 알림';

  @override
  String get newChapterNotificationsEnabled => '사용';

  @override
  String get newChapterNotificationsDisabled => '사용 안 함';

  @override
  String get manageNotifications => '알림 관리';

  @override
  String get notifSectionApp => '앱 알림';

  @override
  String get notifSectionInfo => '정보';

  @override
  String get notifNewChaptersTitle => '새 챕터';

  @override
  String get notifNewChaptersSubtitle => '팔로우 중인 만화에 새 챕터가 게시되면 알림을 받습니다';

  @override
  String get notifFriendReqTitle => '친구 요청';

  @override
  String get notifFriendReqSubtitle => '누군가가 당신을 친구로 추가하고 싶어합니다';

  @override
  String get notifSharesTitle => '받은 추천';

  @override
  String get notifSharesSubtitle => '친구가 만화를 공유합니다';

  @override
  String get notifPermissionExplanation =>
      '알림은 앱에 시스템 권한이 있을 때만 표시됩니다. 받지 못한다면 휴대전화 설정에서 활성화하세요.';

  @override
  String get notifOpenSystemSettings => '시스템 설정 열기';

  @override
  String get pushNotifFriendRequestTitle => '새 친구 요청';

  @override
  String pushNotifFriendRequestBody(String senderUsername) {
    return '$senderUsername님이 친구로 추가하고 싶어합니다';
  }

  @override
  String get pushNotifShareTitle => '새 만화 공유됨';

  @override
  String pushNotifShareBody(String senderUsername, String mangaTitle) {
    return '$senderUsername님이 $mangaTitle을(를) 추천합니다';
  }

  @override
  String get theme => '테마';

  @override
  String get lightMode => '라이트 모드';

  @override
  String get darkMode => '다크 모드';

  @override
  String get systemMode => '시스템';

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
  String get chapterNotFound => '챕터를 찾을 수 없습니다';

  @override
  String get previousChapterTooltip => '이전 챕터';

  @override
  String get nextChapterTooltip => '다음 챕터';

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
  String get searchTitle => '검색';

  @override
  String get searchEmptyHistory => '최근 검색 없음';

  @override
  String get searchPopularGenres => '인기 장르';

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
  String get downloads => '다운로드';

  @override
  String get manageDownloads => '다운로드 관리';

  @override
  String get manageDownloadsSubtitle => '다운로드한 챕터 보기 및 삭제';

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
  String get linkAddCustomPattern => '이 형식에 사용할 사용자 지정 패턴 추가';

  @override
  String get customSelectors => '사용자 지정 선택자';

  @override
  String get manageCustomSelectors => '선택자 관리';

  @override
  String get manageCustomSelectorsSubtitle =>
      '광고를 차단하거나 콘텐츠를 식별하기 위한 사용자 지정 CSS 선택자를 추가하세요';

  @override
  String get addCustomSelector => '선택자 추가';

  @override
  String get selectorDomainLabel => '도메인 (예: example.com)';

  @override
  String get selectorCssLabel => 'CSS 선택자';

  @override
  String get selectorTypeLabel => '선택자 유형';

  @override
  String get selectorTypeUrlPattern => 'URL 패턴';

  @override
  String get selectorUrlPatternLabel => 'URL 패턴 (정규식)';

  @override
  String get selectorUrlPatternHint => '예: /chapter-(\\d+)/ 로 /chapter-22 감지';

  @override
  String get selectorExamplesUrlPattern => 'URL 패턴 예시:';

  @override
  String get selectorExampleUrlPattern => '예: /chapter-22';

  @override
  String get selectorExampleUrlPatternExplanation =>
      '사이트 URL에 \"/chapter-22\"가 포함되어 있는데 시스템이 자동으로 감지하지 못하는 경우:';

  @override
  String get selectorUrlPatternExampleDesc =>
      '(\\d+)가 포함된 정규식(regex)을 사용하여 챕터 번호를 추출하세요.\n\n이 패턴은 모든 사이트에 적용됩니다.\n\n패턴 예시:\n• /chapter-(\\d+)/ → /chapter-22 감지\n• /chapppter-(\\d+)/ → /chapppter-22 감지 (p가 3개)\n• /manga/chapter-(\\d+)/ → /manga/chapter-22 감지\n• /episode-(\\d+)/ → /episode-22 감지';

  @override
  String get selectorUrlPatternGlobal =>
      '이 패턴은 모든 사이트에 적용됩니다. 도메인을 지정할 필요가 없습니다.';

  @override
  String get selectorTypeAdBlocker => '광고 차단기';

  @override
  String get selectorTypeChapterContent => '챕터 콘텐츠';

  @override
  String get selectorDescriptionLabel => '설명 (선택 사항)';

  @override
  String get selectorDescriptionHint => '선택자 설명';

  @override
  String get selectorRequiredFields => '모든 항목을 입력해야 합니다';

  @override
  String get selectorAdded => '선택자가 추가되었습니다';

  @override
  String get deleteSelector => '선택자 삭제';

  @override
  String get deleteSelectorConfirm => '이 선택자를 삭제하시겠습니까?';

  @override
  String get selectorDeleted => '선택자가 삭제되었습니다';

  @override
  String get selectorsExported => '선택자를 클립보드로 내보냈습니다';

  @override
  String get importSelectors => '선택자 가져오기';

  @override
  String get selectorsJsonLabel => '선택자 JSON';

  @override
  String get import => '가져오기';

  @override
  String selectorsImported(String count) {
    return '선택자 $count개를 가져왔습니다';
  }

  @override
  String get selectorsReadyToShare =>
      '선택자를 공유할 준비가 되었습니다! JSON을 Discord에 붙여넣으세요.';

  @override
  String get exportSelectors => '내보내기';

  @override
  String get shareSelectors => '공유';

  @override
  String get noCustomSelectors => '사용자 지정 선택자가 없습니다';

  @override
  String get addFirstSelector => '첫 번째 선택자를 추가하여 시작하세요';

  @override
  String get selectorExamples => '예시';

  @override
  String get selectorExamplesAdBlocker => '광고 차단 예시:';

  @override
  String get selectorExampleAd1 => '광고 배너';

  @override
  String get selectorExampleAd2 => 'ID로 지정한 광고';

  @override
  String get selectorExampleAd3 => '광고 iframe';

  @override
  String get selectorExampleAd4 => '광고 스크립트';

  @override
  String get selectorExamplesChapter => '챕터 콘텐츠 식별 예시:';

  @override
  String get selectorExampleChapter1 => '챕터 컨테이너';

  @override
  String get selectorExampleChapter2 => '만화 리더';

  @override
  String get selectorExampleChapter3 => '챕터 이미지';

  @override
  String get selectorExampleChapter4 => '읽기 콘텐츠';

  @override
  String get selectorExampleChapter5 => 'manga/chapter-22 형식';

  @override
  String get selectorExampleChapter5Explanation =>
      '구체적인 예: URL이 \"mysite.com/manga/chapter-22\"인 경우';

  @override
  String get selectorUrlFormatDetected =>
      '좋은 소식: URL의 \"/manga/chapter-22\" 형식은 시스템이 이미 자동으로 감지합니다!\n\n사이트가 URL에서 이 형식만 사용한다면 CSS 선택자를 추가할 필요가 없습니다.';

  @override
  String get selectorWhenNeeded => 'CSS 선택자는 언제 추가해야 하나요?';

  @override
  String get selectorPracticalExample => '실제 예시:';

  @override
  String get selectorExampleScenario =>
      '사례: 사이트가 \"/chapter-22\" 대신 \"/chapppter-22\"(p가 3개)를 사용하는 경우';

  @override
  String get selectorStep1 => '브라우저에서 챕터 페이지를 엽니다';

  @override
  String get selectorStep2 => 'F12 키를 눌러 개발자 도구를 엽니다';

  @override
  String get selectorStep3 => '\"검사\" 아이콘을 클릭합니다 (또는 Ctrl+Shift+C)';

  @override
  String get selectorStep4 => '챕터 이미지가 들어 있는 컨테이너를 클릭합니다';

  @override
  String get selectorStep5 => 'HTML 코드에서 컨테이너의 클래스 또는 ID를 찾습니다';

  @override
  String get selectorFillForm => '양식을 작성하세요:';

  @override
  String get selectorCssWhenNeededDesc =>
      '페이지의 HTML 콘텐츠를 식별하기 위해 특정 선택자가 필요한 사이트에만 사용하세요.\n\n시스템이 이미 URL로 챕터를 올바르게 감지한다면 CSS 선택자를 추가할 필요가 없습니다.\n\n다음 경우에만 CSS 선택자를 추가하세요:\n• 시스템이 챕터 콘텐츠를 올바르게 감지하지 못하는 경우\n• 이 사이트에만 있는 광고를 차단하려는 경우\n• 사이트가 콘텐츠에 특수한 클래스/ID를 사용하는 경우\n\n선택자 찾는 방법: 페이지를 열고(F12 → 검사) 챕터 이미지가 들어 있는 컨테이너를 찾아 해당 클래스 또는 ID를 사용하세요 (예: .manga-content, #chapter-images)';

  @override
  String get selectorDomainExampleDesc =>
      '도메인 이름만 입력하세요 (http://, www, 경로 /manga/chapter-22 제외)';

  @override
  String get selectorOtherExamples => '기타 일반적인 예시:';

  @override
  String get selectorExampleChapter5Desc =>
      'URL에 manga/chapter-22 형식을 사용하는 사이트용. 예: URL이 \"site.com/manga/chapter-22\"라면 이 선택자들을 사용하여 콘텐츠를 식별하세요.';

  @override
  String get selectorExamplesHint =>
      '팁: 브라우저의 개발자 도구(F12)로 요소를 검사하여 적절한 CSS 선택자를 찾으세요.';

  @override
  String get captchaDetected => '캡차가 감지되었습니다 - 광고 차단기가 일시적으로 비활성화되었습니다';

  @override
  String get captchaResolved => '캡차가 해결되었습니다 - 광고 차단기가 다시 활성화되었습니다';

  @override
  String get scrollPositionSaved => '스크롤 위치가 저장되었습니다';

  @override
  String get chapterProgressSaved => '챕터 진행 상황이 저장되었습니다';

  @override
  String get readingOffline => '오프라인으로 읽기';

  @override
  String get chapterDownloaded => '챕터가 다운로드되었습니다';

  @override
  String get offlineReadingMode => '오프라인 읽기 모드';

  @override
  String get deleteChapterTitle => '챕터 삭제';

  @override
  String deleteChapterMessage(int chapterNumber) {
    return '정말 챕터 $chapterNumber을(를) 삭제하시겠습니까?';
  }

  @override
  String get deleteAllChaptersTitle => '모든 챕터 삭제';

  @override
  String get deleteAllChaptersMessage => '이 만화의 모든 다운로드된 챕터를 정말 삭제하시겠습니까?';

  @override
  String get deleteAllDownloadsTitle => '모든 다운로드 삭제';

  @override
  String get deleteAllDownloadsMessage =>
      '정말 모든 다운로드를 삭제하시겠습니까? 이 작업은 되돌릴 수 없습니다.';

  @override
  String get deleteAll => '모두 삭제';

  @override
  String get chapterDeleted => '챕터가 삭제되었습니다';

  @override
  String get allChaptersDeleted => '모든 챕터가 삭제되었습니다';

  @override
  String get allDownloadsDeleted => '모든 다운로드가 삭제되었습니다';

  @override
  String get noChaptersDownloaded => '다운로드된 챕터가 없습니다';

  @override
  String chaptersDownloadedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count개 챕터가 다운로드되었습니다',
      one: '1개 챕터가 다운로드되었습니다',
      zero: '다운로드된 챕터가 없습니다',
    );
    return '$_temp0';
  }

  @override
  String get readChapter => '읽기';

  @override
  String get deleteAllChaptersAction => '모든 챕터 삭제';

  @override
  String get deleteAllDownloadsTooltip => '모든 다운로드 삭제';

  @override
  String get recommendedForYou => '추천 항목';

  @override
  String get recommendedForYouEmpty => '라이브러리에 만화를 추가하여\n맞춤 추천을 받아보세요.';

  @override
  String recommendedForYouCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '만화 $count개',
    );
    return '$_temp0';
  }

  @override
  String get recommendedForYouCached => '캐시된 추천 (오프라인 모드)';

  @override
  String errorWithMessage(String message) {
    return '오류: $message';
  }

  @override
  String recommendedBecauseOf(String titles) {
    return '$titles을(를) 좋아했기 때문에';
  }

  @override
  String get yourRating => '내 평점';

  @override
  String get myDataTitle => '내 데이터';

  @override
  String get myDataSubtitle => '내 데이터 보기, 내보내기 또는 삭제 (GDPR)';

  @override
  String get gdprIntro =>
      'GDPR에 따라 귀하는 개인 데이터에 대한 권리를 가집니다. 이 페이지에서 이러한 권리를 쉽게 행사할 수 있습니다.';

  @override
  String get gdprAccessTitle => '내 데이터 보기';

  @override
  String get gdprAccessSubtitle => '제15조 — 저장된 정보의 요약';

  @override
  String get gdprExportTitle => '내 데이터 내보내기';

  @override
  String get gdprExportSubtitle => '제20조 — 클립보드에 복사된 전체 JSON';

  @override
  String get gdprLegalDocs => '법적 문서';

  @override
  String get gdprDeleteHint =>
      '계정을 영구적으로 삭제하려면 프로필 → 계정 삭제로 이동하세요. 이 작업은 되돌릴 수 없습니다.';

  @override
  String get privacyPolicyTitle => '개인정보 처리방침';

  @override
  String get termsOfServiceTitle => '이용 약관';

  @override
  String get myDataInfoBanner =>
      'GDPR에 따라 귀하는 데이터에 접근하고, 내보내고, 삭제를 요청할 권리가 있습니다.';

  @override
  String get myDataSectionPersonalData => '개인 데이터';

  @override
  String get myDataSectionMyRights => '내 권리';

  @override
  String get myDataSectionDeletion => '삭제';

  @override
  String get myDataSummaryTitle => '내 데이터 요약';

  @override
  String get myDataSummarySubtitle => '저장된 데이터의 개요 보기';

  @override
  String get myDataExportSubtitle => '전체 JSON 파일 다운로드 (제20조)';

  @override
  String get privacyPolicySubtitle => '전체 문서 읽기';

  @override
  String get termsOfServiceSubtitle => '이용 약관 보기';

  @override
  String get myDataDeleteAccountSubtitle => '이 작업은 되돌릴 수 없습니다';

  @override
  String get gdprExportSuccessSnack => '데이터가 클립보드에 복사되었습니다 (JSON).';

  @override
  String get gdprExportFailedSnack => '내보내기 실패';

  @override
  String get gdprSummaryLoadFailed => '로딩 오류';

  @override
  String get myDataBackLabel => '프로필';

  @override
  String get tosShortVersion =>
      'Manga Tracker는 보증 없이 그대로 제공됩니다. 발행인은 사용자의 비규정 사용(불법 콘텐츠, 스크래핑 등)에 대한 모든 책임을 부인합니다.\n\n전체 문서는 공식 웹사이트에서 확인할 수 있습니다.';

  @override
  String get privacyShortVersion =>
      '수집된 데이터: 이메일, 비밀번호(해시화), 만화 라이브러리, 환경 설정. 데이터는 제3자에게 판매되지 않습니다. 언제든지 데이터를 내보내거나 삭제할 수 있습니다.\n\n전체 문서는 공식 웹사이트에서 확인할 수 있습니다.';

  @override
  String get iAcceptTos => '이용 약관에 동의합니다';

  @override
  String get iAcceptPrivacy => '개인정보 처리방침에 동의합니다';

  @override
  String get iAccept => '동의';

  @override
  String get consentRequired => '이용 약관과 개인정보 처리방침에 동의해야 합니다.';

  @override
  String get consentRefreshTitle => '약관이 업데이트되었습니다';

  @override
  String get consentRefreshIntro =>
      '이용 약관과 개인정보 처리방침이 업데이트되었습니다. 계속하려면 동의해 주세요.';

  @override
  String get refuseAndLogout => '거부하고 로그아웃';

  @override
  String get versionLabel => '버전';

  @override
  String get welcomeTitle => '환영합니다!';

  @override
  String get loginSubtitle => '계정에 로그인하세요';

  @override
  String get createAccountTitle => '계정 만들기';

  @override
  String get registerSubtitle => '독서 기록을 시작하세요';

  @override
  String get orLoginWith => '또는 다음으로 로그인';

  @override
  String get orSignUpWith => '또는 다음으로 가입';

  @override
  String get continueWithApple => 'Apple로 계속하기';

  @override
  String get loadingApp => '로딩 중…';

  @override
  String get forgotPasswordTitle => '비밀번호 찾기';

  @override
  String get forgotPasswordIntro =>
      '이메일을 입력하세요. 계정이 존재하면 새 비밀번호를 설정할 수 있는 링크를 받게 됩니다.';

  @override
  String get sendResetLink => '링크 보내기';

  @override
  String get resetEmailSentTitle => '받은 편지함을 확인하세요';

  @override
  String resetEmailSentMessage(String email) {
    return '$email 계정이 존재하는 경우 새 비밀번호를 설정할 수 있는 링크가 포함된 이메일이 전송되었습니다.\n\n링크는 30분 후에 만료됩니다.';
  }

  @override
  String get resetPasswordTitle => '새 비밀번호';

  @override
  String get resetPasswordIntro => '계정의 새 비밀번호를 설정하세요. 확인 후 자동으로 로그인됩니다.';

  @override
  String get confirmReset => '확인';

  @override
  String get resetTokenExpired => '유효하지 않거나 만료된 링크입니다. 다시 요청해 주세요.';

  @override
  String get resetPasswordSuccess => '비밀번호가 변경되었습니다';

  @override
  String get resetPasswordSuccessHint => '로그인되었습니다. 리디렉션 중…';

  @override
  String get verifyingEmail => '확인 중…';

  @override
  String get emailVerifiedSuccess => '이메일이 확인되었습니다!';

  @override
  String get emailVerifiedHint => '로그인 중…';

  @override
  String get emailVerifyFailedTitle => '유효하지 않거나 만료된 링크';

  @override
  String get emailVerifyFailedHint =>
      '사용하신 링크는 더 이상 유효하지 않습니다. 로그인하여 프로필에서 새 링크를 요청하세요.';

  @override
  String get backToLogin => '로그인으로 돌아가기';

  @override
  String get verifyEmailBannerMessage => '모든 기능을 활성화하려면 이메일 주소를 확인하세요.';

  @override
  String get emailSentShort => '전송됨';

  @override
  String get resendEmailShort => '재전송';

  @override
  String get recommendedForYouHome => '추천 작품';

  @override
  String get seeMoreByGenre => '장르별로 더 보기';

  @override
  String get recommendationsByGenreTitle => '장르별 추천';

  @override
  String get recommendationsByGenreEmpty =>
      '아직 추천이 없습니다. 라이브러리에 만화를 추가하여 맞춤 추천을 받아보세요.';

  @override
  String get recommendationsAllTitle => '전체 추천';

  @override
  String get recommendationsAllEmpty => '아직 추천이 없습니다.';

  @override
  String get seeAllRecommendations => '전체 보기';

  @override
  String get browseByGenre => '장르별';

  @override
  String get recommendationsTabAll => '모두';

  @override
  String get recommendationsTabByGenre => '장르별';

  @override
  String get statsTitle => '내 통계';

  @override
  String get statsTotalMangas => '권이 라이브러리에 있습니다';

  @override
  String statsMemberSince(String date) {
    return '$date부터 가입';
  }

  @override
  String get statsTotalChapters => '읽은 화 수';

  @override
  String get statsReadingTime => '예상 독서 시간';

  @override
  String get statsCompletionRate => '완독률';

  @override
  String get statsLastRead => '마지막으로 읽은 작품';

  @override
  String get statsByStatusTitle => '상태별 분포';

  @override
  String get statsByStatusEmpty => '아직 라이브러리에 만화가 없습니다.';

  @override
  String get statsTopGenresTitle => '좋아하는 장르';

  @override
  String get statsTopGenresEmpty => '만화를 추가해 좋아하는 장르를 알아보세요.';

  @override
  String statsMinutesShort(int count) {
    return '$count분';
  }

  @override
  String statsHoursAndMinutesShort(int hours, int minutes) {
    return '$hours시간 $minutes분';
  }

  @override
  String statsDaysAndHoursShort(int days, int hours) {
    return '$days일 $hours시간';
  }

  @override
  String get statusReadLater => '나중에 읽기';

  @override
  String get statusReading => '읽는 중';

  @override
  String get statusCaughtUp => '최신화까지';

  @override
  String get statusCompleted => '완결';

  @override
  String get statsSectionOverview => '개요';

  @override
  String get statsSectionBreakdown => '상태별 만화';

  @override
  String get statsSectionGenres => '선호 장르';

  @override
  String get statsLibraryTotal => '라이브러리의 만화';

  @override
  String statsMonthsSinceJoin(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '가입한 지 $count개월',
      zero: '가입한 지 1개월 미만',
    );
    return '$_temp0';
  }

  @override
  String statsHeroBadge(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '만화 $count권',
    );
    return '$_temp0';
  }

  @override
  String get profileMyStats => '내 통계';

  @override
  String get profileEditTitle => '프로필 편집';

  @override
  String get profileEditBackLabel => '프로필';

  @override
  String get profileEditMenuTitle => '프로필 편집';

  @override
  String get profileEditMenuSubtitle => '사진, 표시 이름, 소개, 공개 설정';

  @override
  String get profileFieldAvatarUrl => '아바타 URL';

  @override
  String get profileFieldDisplayName => '표시 이름';

  @override
  String get profileFieldBio => '소개';

  @override
  String get profileFieldDateOfBirth => '생년월일';

  @override
  String get profileFieldGender => '성별';

  @override
  String get profileGenderNotSet => '미설정';

  @override
  String get profileGenderMale => '남성';

  @override
  String get profileGenderFemale => '여성';

  @override
  String get profileGenderNonBinary => '논바이너리';

  @override
  String get profileGenderPreferNotToSay => '답변하지 않음';

  @override
  String get profileFieldIsPublic => '공개 프로필';

  @override
  String get profileFieldIsPublicSubtitle => '다른 사용자에게 표시됩니다';

  @override
  String get profileSaved => '프로필이 저장되었습니다';

  @override
  String get profileSaveFailed => '저장에 실패했습니다';

  @override
  String get friendsTitle => '친구';

  @override
  String get friendsTabAccepted => '친구';

  @override
  String get friendsTabPending => '요청';

  @override
  String get friendsSearchLabel => '친구 찾기';

  @override
  String get friendsSearchHint => '사용자 이름 입력 (최소 2자)';

  @override
  String get friendsAddRequest => '요청 보내기';

  @override
  String get friendsAccept => '수락';

  @override
  String get friendsReject => '거절';

  @override
  String get friendsRemove => '삭제';

  @override
  String get friendsRequestSent => '요청을 보냈습니다';

  @override
  String get friendsError => '오류';

  @override
  String get friendsEmptyAccepted => '아직 친구가 없습니다';

  @override
  String get friendsEmptyAcceptedSubtitle => '위의 검색에서 사용자를 추가하세요.';

  @override
  String get friendsEmptyPending => '대기 중인 요청이 없습니다';

  @override
  String get friendsEmptyPendingSubtitle => '받은 요청이 여기에 표시됩니다.';

  @override
  String get friendsSectionAccepted => '내 친구';

  @override
  String get friendsSectionPending => '받은 요청';

  @override
  String get friendsSearchClear => '지우기';

  @override
  String get friendsSearchResults => '검색 결과';

  @override
  String get friendsSearchEmpty => '사용자를 찾을 수 없습니다.';

  @override
  String get profileMyFriends => '내 친구';

  @override
  String get commentsTitle => '댓글';

  @override
  String get commentsEmpty => '아직 댓글이 없습니다. 첫 댓글을 남겨보세요!';

  @override
  String get commentsSortRecent => '최신순';

  @override
  String get commentsSortTop => '인기';

  @override
  String get commentsInputHint => '감상평을 남겨주세요 (3-2000자)';

  @override
  String get commentsPost => '게시';

  @override
  String get commentsDelete => '삭제';

  @override
  String get commentsLoadMore => '더 보기';

  @override
  String commentsReplyCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count개의 답글',
      one: '1개의 답글',
    );
    return '$_temp0';
  }

  @override
  String get timeJustNow => '방금 전';

  @override
  String timeMinutesAgo(int count) {
    return '$count분 전';
  }

  @override
  String timeHoursAgo(int count) {
    return '$count시간 전';
  }

  @override
  String timeDaysAgo(int count) {
    return '$count일 전';
  }

  @override
  String get shareTitle => '이 만화 공유';

  @override
  String get shareMessageHint => '메시지 추가 (선택)';

  @override
  String get shareCancel => '취소';

  @override
  String get shareSend => '보내기';

  @override
  String get shareSuccess => '공유되었습니다';

  @override
  String get shareFailed => '공유 실패';

  @override
  String get shareLoadError => '친구 목록을 불러올 수 없습니다';

  @override
  String get shareNoFriends => '아직 공유할 친구가 없습니다. 친구 페이지에서 추가하세요.';

  @override
  String get inboxTitle => '받은 추천';

  @override
  String get inboxEmpty => '아직 추천이 없습니다.';

  @override
  String get inboxBadgeNew => 'NEW';

  @override
  String inboxSenderRecommends(String sender) {
    return '$sender님이 추천합니다';
  }

  @override
  String inboxSharedYouLabel(String sender) {
    return '$sender님이 공유했습니다';
  }

  @override
  String get inboxFilterAll => '전체';

  @override
  String get inboxFilterUnread => '읽지 않음';

  @override
  String get inboxFilterRead => '읽음';

  @override
  String get inboxGroupToday => '오늘';

  @override
  String get inboxGroupYesterday => '어제';

  @override
  String get inboxGroupThisWeek => '이번 주';

  @override
  String get inboxGroupOlder => '그 이전';

  @override
  String get inboxEmptyTitle => '추천이 없습니다';

  @override
  String get inboxEmptySubtitle => '친구들에게 즐겨 읽는 작품을 공유해 달라고 요청해 보세요.';

  @override
  String get inboxEmptyFilteredUnread => '읽지 않은 추천이 없습니다.';

  @override
  String get inboxEmptyFilteredRead => '읽은 추천이 없습니다.';

  @override
  String get profileMyInbox => '받은 추천';

  @override
  String get readingGroupsTitle => '함께 읽기';

  @override
  String get readingGroupsEmpty => '아직 독서 그룹이 없습니다. 만화 상세 페이지에서 만들어보세요.';

  @override
  String get readingGroupDetailTitle => '독서 그룹';

  @override
  String get readingGroupMembersTitle => '멤버';

  @override
  String get readingGroupOwnerBadge => 'OWNER';

  @override
  String get readingGroupOpenManga => '만화 열기';

  @override
  String get readingGroupNotStarted => '시작 안 함';

  @override
  String readingGroupChaptersRead(int count) {
    return '$count화';
  }

  @override
  String get readingGroupChaptersReadLabel => '읽음';

  @override
  String readingGroupMembersCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count명',
      one: '1명',
    );
    return '$_temp0';
  }

  @override
  String get profileMyReadingGroups => '함께 읽기';

  @override
  String get profileSectionPublicInfo => '공개 정보';

  @override
  String get profileSectionAbout => '내 정보';

  @override
  String get profileSectionPrivacy => '개인 정보 보호';

  @override
  String get profileNotSet => '미설정';

  @override
  String get profileSectionAvatar => '아바타';

  @override
  String get profileEditAvatarHeroHint => '이미지 URL을 붙여넣으면 미리보기가 업데이트됩니다.';

  @override
  String get profileEditPickPhoto => '사진 선택';

  @override
  String get profileEditClearAvatar => '지우기';

  @override
  String get profileEditPhotoPickFailed => '사진을 선택할 수 없습니다';

  @override
  String get profileGenderClear => '지우기';

  @override
  String get avatarUrlLabel => '아바타 URL';

  @override
  String get avatarUrlInvalid => 'URL은 http:// 또는 https://로 시작해야 합니다';

  @override
  String get profileSectionAccount => '계정';

  @override
  String get profileFieldUsername => '사용자 이름';

  @override
  String get profileFieldEmail => '이메일';

  @override
  String get profileFieldReadOnly => '변경 불가';

  @override
  String get profileChangePhoto => '사진 변경';

  @override
  String get changelogCardTitle => '릴리스 노트';

  @override
  String get readingGroupCreateTitle => '함께 읽기';

  @override
  String get readingGroupCreateNameLabel => '그룹 이름 (선택)';

  @override
  String get readingGroupCreateNameHint => '예: Berserk 레아와';

  @override
  String get readingGroupCreateInviteSection => '친구 초대';

  @override
  String get readingGroupCreateConfirm => '그룹 만들기';

  @override
  String get readingGroupCreateFailed => '그룹 만들기에 실패했습니다';

  @override
  String get readingGroupCreateInviteRequired => '그룹을 만들려면 친구를 한 명 이상 선택하세요';

  @override
  String get readingGroupDelete => '그룹 삭제';

  @override
  String get readingGroupDeleteConfirmTitle => '이 그룹을 삭제하시겠습니까?';

  @override
  String get readingGroupDeleteConfirm =>
      '이 작업은 되돌릴 수 없습니다. 모든 멤버가 그룹 접근 권한을 잃게 됩니다.';

  @override
  String get readingGroupDeleteSuccess => '그룹을 삭제했습니다';

  @override
  String get readingGroupDeleteFailed => '그룹 삭제에 실패했습니다';

  @override
  String get readingGroupSharedReading => '공유 독서';

  @override
  String get readingGroupViewGroup => '그룹 보기';

  @override
  String get readingGroupChapterShort => '화';

  @override
  String get profileHighlightTitle => '새로운 기능';

  @override
  String get profileNewBadge => '새로움';

  @override
  String get profileFooterBrand => 'MANGA TRACKER';

  @override
  String get readingGroupListSectionTitle => '내 그룹';

  @override
  String readingGroupWithLabel(String name) {
    return '$name 와(과) 함께';
  }

  @override
  String get readingGroupYouLabel => '나';

  @override
  String readingGroupProgressYouVsFriend(
    String you,
    String friend,
    String their,
  ) {
    return '나: $you화 · $friend: $their화';
  }

  @override
  String get readingGroupChapterDash => '—';

  @override
  String get readingGroupSectionHero => '현재 읽는 중';

  @override
  String get readingGroupSectionProgress => '진행도';

  @override
  String get readingGroupSectionActions => '작업';

  @override
  String get readingGroupActionsMarkProgress => '내 진행도 업데이트';

  @override
  String get readingGroupActionsMarkProgressSubtitle => '만화 페이지를 열어 계속 읽기';

  @override
  String get readingGroupActionsInvite => '친구 초대하기';

  @override
  String readingGroupActionsCopyFriendLink(String friend) {
    return '$friend의 링크 복사';
  }

  @override
  String readingGroupActionsCopyFriendLinkSubtitle(int chapter) {
    return '$chapter화에 맞춰 조정됨';
  }

  @override
  String readingGroupApplyLinkSuccess(int chapter) {
    return '$chapter화의 링크가 저장되었습니다';
  }

  @override
  String readingGroupCopyLinkSuccess(int chapter) {
    return '링크 복사됨 — $chapter화';
  }

  @override
  String get readingGroupCopyLinkFailed => '이 링크를 조정할 수 없습니다(알 수 없는 형식)';

  @override
  String get readingGroupActionsInviteSubtitle => '그룹에 사람 추가';

  @override
  String get readingGroupActionsLeave => '그룹 나가기';

  @override
  String get readingGroupActionsLeaveSubtitle => '공유된 진행도를 더 이상 볼 수 없습니다';

  @override
  String get readingGroupActionsDeleteSubtitle => '모든 멤버에게서 영구적으로 삭제';

  @override
  String get readingGroupLeaveConfirmTitle => '이 그룹에서 나가시겠습니까?';

  @override
  String get readingGroupLeaveConfirm => '공유된 진행도에 더 이상 접근할 수 없습니다.';

  @override
  String get readingGroupLeaveSuccess => '그룹에서 나왔습니다';

  @override
  String get readingGroupLeaveFailed => '그룹을 나갈 수 없습니다';

  @override
  String get readingGroupEmptyTitle => '아직 함께 읽는 만화가 없습니다';

  @override
  String get readingGroupEmptySubtitle => '친구와 함께 만화를 시작하고 진행도를 함께 추적하세요.';

  @override
  String get readingGroupEmptyAction => '만화 탐색';

  @override
  String get readingGroupTotalLabel => '전체';

  @override
  String readingGroupChaptersTotal(int count) {
    return '$count화';
  }

  @override
  String get readingGroupInviteSoonTitle => '곧 제공 예정';

  @override
  String get readingGroupInviteSoonMessage =>
      '그룹에서 친구를 초대하는 기능이 곧 추가됩니다. 지금은 만화 페이지에서 새 그룹을 만들어 주세요.';

  @override
  String get libraryToggleListView => '목록 보기';

  @override
  String get libraryToggleCardView => '카드 보기';

  @override
  String get libraryShowDownloadedOnly => '다운로드한 항목만 표시';

  @override
  String get libraryShowAllMangas => '모든 만화 표시';

  @override
  String libraryProgressLabel(int read, int total) {
    return '$total화 중 $read화 읽음';
  }

  @override
  String votesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count표',
      zero: '투표 없음',
    );
    return '$_temp0';
  }

  @override
  String get detailSectionSimilar => '비슷한 만화';

  @override
  String get rating => '평점';

  @override
  String get anonymousUser => '익명 사용자';

  @override
  String get recommendationsColdStartTitle => '인기 만화를 만나보세요';

  @override
  String get recommendationsColdStartSubtitle => '첫 작품을 추가하면 맞춤 추천을 받을 수 있어요';

  @override
  String get friendLibraryError => '친구의 서재를 불러올 수 없습니다.';

  @override
  String get friendLibraryEmpty => '서재가 아직 비어 있습니다.';

  @override
  String friendLibraryCount(int count) {
    return '서재에 $count개의 만화';
  }

  @override
  String get statsHistoryTitle => '최근 읽은 작품';

  @override
  String get statsActivityTitle => '독서 활동';

  @override
  String get statsBonusTag => '외전';

  @override
  String get statsNoHistory => '아직 기록된 독서가 없습니다. 진행 상황을 업데이트하면 기록이 시작됩니다.';

  @override
  String get reportMoreChaptersCta => '챕터 수 신고';

  @override
  String get reportMoreChaptersDialogTitle => '챕터 수 신고';

  @override
  String get reportMoreChaptersExplainer =>
      '알려진 총 챕터 수보다 더 많이 읽으셨나요? 새로운 총 수를 입력하세요. 진행 상황에 반영되고 다른 독자들의 신고와 대조됩니다.';

  @override
  String get reportMoreChaptersInputLabel => '새 챕터 총 수';

  @override
  String reportMoreChaptersInvalidLow(int total) {
    return '총 수는 $total보다 커야 합니다.';
  }

  @override
  String reportMoreChaptersInvalidHigh(int max) {
    return '총 수는 $max을(를) 초과할 수 없습니다.';
  }

  @override
  String get reportMoreChaptersSubmit => '신고';

  @override
  String get reportMoreChaptersSuccess => '감사합니다! 챕터 수가 업데이트되었습니다.';

  @override
  String get reportMoreChaptersError => '지금은 신고를 보낼 수 없습니다. 나중에 다시 시도해 주세요.';

  @override
  String get reportMoreChaptersErrorInvalid =>
      '그 사이에 알려진 총 화수가 변경되었습니다. 페이지를 새로고침한 후 다시 시도해 주세요.';

  @override
  String get reportMoreChaptersErrorThrottled =>
      '최근에 신고를 너무 많이 보냈습니다. 잠시 후 다시 시도해 주세요.';

  @override
  String get reportMoreChaptersOffline => '오프라인에서는 사용할 수 없습니다.';

  @override
  String get dismissRecommendationSheetTitle => '이 작품 추천 안 함';

  @override
  String dismissRecommendationSheetSubtitle(String title) {
    return '‘$title’이(가) 추천 목록에서 사라집니다. 나중에 되돌릴 수 있어요.';
  }

  @override
  String get dismissReasonAlreadyRead => '이미 읽음';

  @override
  String get dismissReasonAlreadyReadHint => '이미 읽어서 새로 볼 게 없어요';

  @override
  String get dismissReasonNotInterested => '관심 없음';

  @override
  String get dismissReasonNotInterestedHint => '제 취향이 아니에요';

  @override
  String get dismissReasonSeenElsewhere => '다른 곳에서 봄';

  @override
  String get dismissReasonSeenElsewhereHint => '애니메이션, 드라마 또는 영화로';

  @override
  String dismissRecommendationSuccess(String title) {
    return '‘$title’이(가) 더 이상 추천에 표시되지 않습니다';
  }

  @override
  String get dismissRecommendationUndo => '실행 취소';

  @override
  String get dismissRecommendationUndone => '추천을 되돌렸습니다';

  @override
  String get dismissRecommendationError =>
      '지금은 이 작품을 제외할 수 없습니다. 나중에 다시 시도해 주세요.';

  @override
  String get dismissRecommendationOffline => '오프라인에서는 사용할 수 없습니다.';

  @override
  String get dismissRecommendationAccessibility => '길게 눌러 이 작품을 추천에서 제외';

  @override
  String get recommendationsSleepersTitle => '숨은 명작';

  @override
  String get sessionRejectedBanner => '세션이 만료되었습니다 — 저장된 데이터를 표시합니다';

  @override
  String get sessionRejectedAction => '다시 로그인';

  @override
  String get challengeLoopTitle => '인증이 완료되지 않음';

  @override
  String get challengeLoopMessage =>
      '이 사이트의 로봇 확인이 완료되지 않고 계속 새로고침됩니다. 브라우저에서 페이지를 열어 인증을 완료한 후 다시 돌아오세요.';

  @override
  String get challengeLoopOpenBrowser => '브라우저에서 열기';

  @override
  String get readerRefresh => '페이지 새로고침';

  @override
  String get readerMoreActions => '추가 작업';

  @override
  String get readerDownloadPage => '이 페이지 다운로드';

  @override
  String get adBlockerEnableAction => '광고 차단기 켜기';

  @override
  String get adBlockerDisableAction => '광고 차단기 끄기';

  @override
  String get adBlockerInteractiveEnable => '광고 감지 모드 켜기';

  @override
  String get adBlockerInteractiveDisable => '광고 감지 모드 끄기';

  @override
  String get adBlockerEnabledNotice => '이 페이지에서 광고 차단기를 켰습니다.';

  @override
  String get adBlockerDisabledNotice =>
      '광고 차단기를 꺼습니다 — 콘텐츠를 복원하기 위해 페이지를 새로고침했습니다.';

  @override
  String get adBlockerInteractiveOnNotice => '감지 모드 켜짐 — 광고를 탭하면 차단됩니다.';

  @override
  String get adBlockerInteractiveOffNotice => '감지 모드 꺼짐.';

  @override
  String get homeSectionLatest => '최신 출시작';

  @override
  String get homeSectionPopular => '지금 가장 인기';

  @override
  String get homeSectionTopRated => '평점 높은 작품';

  @override
  String get homeSectionTypeManga => '일본 만화';

  @override
  String get homeSectionTypeManhwa => '한국 만화';

  @override
  String get homeSectionTypeManhua => '중국 만화';

  @override
  String homeSectionGenre(String genre) {
    return '장르: $genre';
  }

  @override
  String homeSectionYear(String year) {
    return '$year년 출시작';
  }

  @override
  String get homeSectionCommunity => '커뮤니티의 선택';

  @override
  String get homeSectionHiddenGems => '숨은 명작';

  @override
  String get homeSectionSeeAll => '모두 보기';

  @override
  String homeSectionSeeAllAccessibility(String title) {
    return '$title 섹션 모두 보기';
  }

  @override
  String get homeSectionsEmptyTitle => '아직 표시할 내용이 없습니다';

  @override
  String get homeSectionsEmptySubtitle => '아래로 당겨 카탈로그를 새로고침하세요.';

  @override
  String get homeSectionsLoadError => '지금은 홈 화면을 불러올 수 없습니다.';

  @override
  String get homeSectionNotFound => '이 섹션은 더 이상 존재하지 않습니다.';

  @override
  String get homeSectionLoadError => '이 섹션을 불러올 수 없습니다.';

  @override
  String get homeSectionLoadMoreFailed => '더 불러오지 못했습니다.';

  @override
  String get homeSectionEmpty => '이 섹션에는 아직 작품이 없습니다.';

  @override
  String get homeSectionEndOfList => '모두 확인했습니다';

  @override
  String homeSectionTitlesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count개 작품',
      zero: '작품 없음',
    );
    return '$_temp0';
  }

  @override
  String get genreRomance => '로맨스';

  @override
  String get genreDrama => '드라마';

  @override
  String get genreFantasy => '판타지';

  @override
  String get genreComedy => '코미디';

  @override
  String get genreSliceOfLife => '일상';

  @override
  String get genreAction => '액션';

  @override
  String get genreSchoolLife => '학원';

  @override
  String get genreSupernatural => '초자연';

  @override
  String get genreAdventure => '모험';

  @override
  String get genreHistorical => '역사';

  @override
  String get genreMystery => '미스터리';

  @override
  String get genrePsychological => '심리';

  @override
  String get genreSciFi => 'SF';

  @override
  String get genreHorror => '공포';

  @override
  String get genreMartialArts => '무술';
}
