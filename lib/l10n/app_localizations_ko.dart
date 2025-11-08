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
}
