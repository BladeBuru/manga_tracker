// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'MangaTracker';

  @override
  String get welcomeBack => 'Welcome back';

  @override
  String get emailAddress => 'Email address';

  @override
  String get password => 'Password';

  @override
  String get forgotPassword => 'Forgot password?';

  @override
  String get login => 'Sign in';

  @override
  String get googleLoginFailed => 'Google sign-in failed';

  @override
  String get googleLoginConfigError =>
      'Google sign-in unavailable (app configuration error)';

  @override
  String get googlePopupBlocked =>
      'Sign-in window blocked by the browser — allow pop-ups for this site and try again';

  @override
  String get loginWithGoogle => 'Sign in with Google';

  @override
  String get back => 'Back';

  @override
  String get signUp => 'Sign up';

  @override
  String get invalidCredentials => 'Invalid credentials';

  @override
  String get unknownError => 'Unknown error';

  @override
  String get trending => 'Trending';

  @override
  String get popular => 'Popular';

  @override
  String get newMangas => 'New';

  @override
  String get offlineMode => 'Offline mode';

  @override
  String get offlineModeNoCache => 'Offline mode - No cached data';

  @override
  String get offlineModeActionQueued => 'Offline mode - Action queued';

  @override
  String pendingActions(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 's',
      one: '',
      zero: 's',
    );
    return '$count pending action$_temp0';
  }

  @override
  String get retry => 'Retry';

  @override
  String get searchNoResults => 'No results found';

  @override
  String searchResultsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count results',
      one: '1 result',
    );
    return '$_temp0';
  }

  @override
  String get searchLoadFailed => 'Search failed';

  @override
  String get searchLoadMoreFailed => 'Couldn\'t load more results';

  @override
  String get error => 'Error';

  @override
  String get library => 'Library';

  @override
  String get search => 'Search';

  @override
  String get profile => 'My account';

  @override
  String get account => 'Account';

  @override
  String get settings => 'Settings';

  @override
  String get actions => 'Actions';

  @override
  String get changePassword => 'Change password';

  @override
  String get changePasswordSubtitle => 'Change your login password';

  @override
  String get changePasswordTitle => 'Change my password';

  @override
  String get changePasswordIntro =>
      'Enter your current password, then choose a new one. Your other devices will be signed out.';

  @override
  String get currentPasswordLabel => 'Current password';

  @override
  String get newPasswordLabel => 'New password';

  @override
  String get confirmNewPasswordLabel => 'Confirm new password';

  @override
  String get changePasswordSuccess => 'Password changed';

  @override
  String get changePasswordSuccessHint =>
      'Your other devices have been signed out. Returning to your profile…';

  @override
  String get changePasswordWrongCurrent => 'The current password is incorrect';

  @override
  String get changePasswordSocialAccount =>
      'This account uses Google sign-in: there is no password to change';

  @override
  String get accountInformation => 'Account information';

  @override
  String get email => 'Email';

  @override
  String get notifications => 'Notifications';

  @override
  String get newChapterNotifications => 'New chapter notifications';

  @override
  String get newChapterNotificationsEnabled => 'Enabled';

  @override
  String get newChapterNotificationsDisabled => 'Disabled';

  @override
  String get manageNotifications => 'Manage notifications';

  @override
  String get notifSectionApp => 'App notifications';

  @override
  String get notifSectionInfo => 'Information';

  @override
  String get notifNewChaptersTitle => 'New chapters';

  @override
  String get notifNewChaptersSubtitle =>
      'Be notified when your followed manga release new chapters';

  @override
  String get notifFriendReqTitle => 'Friend requests';

  @override
  String get notifFriendReqSubtitle => 'Someone wants to add you as a friend';

  @override
  String get notifSharesTitle => 'Shared recommendations';

  @override
  String get notifSharesSubtitle => 'A friend shares a manga with you';

  @override
  String get notifPermissionExplanation =>
      'Notifications appear only when the app has system permission. If you receive none, enable them from your phone settings.';

  @override
  String get notifOpenSystemSettings => 'Open system settings';

  @override
  String get pushNotifFriendRequestTitle => 'New friend request';

  @override
  String pushNotifFriendRequestBody(String senderUsername) {
    return '$senderUsername wants to add you as a friend';
  }

  @override
  String get pushNotifShareTitle => 'New manga shared';

  @override
  String pushNotifShareBody(String senderUsername, String mangaTitle) {
    return '$senderUsername recommends $mangaTitle';
  }

  @override
  String get theme => 'Theme';

  @override
  String get lightMode => 'Light mode';

  @override
  String get darkMode => 'Dark mode';

  @override
  String get systemMode => 'System';

  @override
  String get language => 'Language';

  @override
  String get selectLanguage => 'Select language';

  @override
  String get french => 'French';

  @override
  String get english => 'English';

  @override
  String get logout => 'Sign out';

  @override
  String get logoutSubtitle => 'Sign out of your account';

  @override
  String get confirmLogout => 'Sign out';

  @override
  String get confirmLogoutMessage => 'Are you sure you want to sign out?';

  @override
  String get deleteAccount => 'Delete account';

  @override
  String get deleteAccountSubtitle => 'Irreversible action';

  @override
  String get confirmDeleteAccount => 'Delete account';

  @override
  String get confirmDeleteAccountMessage =>
      'This action is irreversible. All your data will be permanently deleted and cannot be recovered.';

  @override
  String get cancel => 'Cancel';

  @override
  String get save => 'Save';

  @override
  String get delete => 'Delete';

  @override
  String get passwordChangedSuccess => 'Password changed successfully';

  @override
  String get passwordChangeError => 'Error changing password';

  @override
  String get accountDeletedSuccess => 'Account deleted successfully';

  @override
  String get accountDeleteError => 'Error deleting account';

  @override
  String get userInfoLoadError => 'Unable to load user information';

  @override
  String get user => 'User';

  @override
  String get comingSoon => 'Coming soon';

  @override
  String get comingSoonAvatar => 'Coming soon: avatar change';

  @override
  String get whatsNew => 'What\'s new?';

  @override
  String get version => 'Version';

  @override
  String get newFeaturesAvailable => 'New features available';

  @override
  String get currentVersion => 'Current version';

  @override
  String get great => 'Great!';

  @override
  String get authorizationRequired => 'Authorization required';

  @override
  String get modifyLink => 'Modify link';

  @override
  String get removeLink => 'Remove link';

  @override
  String get chapterSkip => 'Chapter skip';

  @override
  String get validateReading => 'Validate reading';

  @override
  String get addToLibrary => 'Add to library';

  @override
  String get removeFromLibrary => 'Remove from library';

  @override
  String get updateStatus => 'Update status';

  @override
  String get reading => 'Reading';

  @override
  String get completed => 'Completed';

  @override
  String get onHold => 'On hold';

  @override
  String get dropped => 'Dropped';

  @override
  String get planToRead => 'Plan to read';

  @override
  String get reReading => 'Re-reading';

  @override
  String get chapters => 'Chapters';

  @override
  String get readChapters => 'Read chapters';

  @override
  String get totalChapters => 'Total chapters';

  @override
  String get associatedNames => 'Associated Names';

  @override
  String associatedNamesCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count names',
      one: '$count name',
      zero: 'No names',
    );
    return '$_temp0';
  }

  @override
  String get saveProgress => 'Save progress';

  @override
  String get description => 'Description';

  @override
  String get authors => 'Authors';

  @override
  String get genres => 'Genres';

  @override
  String get recommendations => 'Recommendations';

  @override
  String get loading => 'Loading...';

  @override
  String get noData => 'No data available';

  @override
  String get noResults => 'No results';

  @override
  String get noAccount => 'Don\'t have an account?';

  @override
  String get home => 'Home';

  @override
  String get myAccount => 'My account';

  @override
  String get offlineModeCached => 'Offline mode - Cached data';

  @override
  String get biometricAuthFailed => 'Biometric authentication failed';

  @override
  String get biometricAuth => 'Biometric login';

  @override
  String get addLink => 'Add link';

  @override
  String get addOrModifyLink => 'Add or modify link';

  @override
  String get linkUrlPlaceholder => 'https://example.com';

  @override
  String get validate => 'Validate';

  @override
  String get invalidLink =>
      'Invalid link. The link must start with http:// or https://';

  @override
  String get linkSaved => 'Link saved!';

  @override
  String get linkRemoved => 'Link removed!';

  @override
  String get readOnline => 'Read online';

  @override
  String get manageLink => 'Manage link';

  @override
  String get recommendedMangas => 'Recommended mangas';

  @override
  String get noRecommendationsAvailable => 'No recommendations available.';

  @override
  String get close => 'Close';

  @override
  String get changeStatus => 'Change status';

  @override
  String get mangaAddedToLibrary => 'Manga added to library';

  @override
  String get mangaMarkedAs => 'Manga marked as';

  @override
  String get readLater => 'Read later';

  @override
  String get upToDate => 'Up to date';

  @override
  String get addToReadLater => 'Add to \"Read later\"';

  @override
  String get mangaRemovedFromLibrary => 'Manga removed from library';

  @override
  String get searchPlaceholder => 'Search Mangas, Manwhas, ...';

  @override
  String get year => 'Year';

  @override
  String get status => 'Status';

  @override
  String get author => 'Author';

  @override
  String get artist => 'Artist';

  @override
  String get synopsis => 'Synopsis';

  @override
  String get seeMore => 'See more';

  @override
  String get seeLess => 'See less';

  @override
  String get all => 'All';

  @override
  String get newReleases => 'New releases';

  @override
  String get chapter => 'Chapter';

  @override
  String get chapterNotFound => 'Chapter not found';

  @override
  String get previousChapterTooltip => 'Previous chapter';

  @override
  String get nextChapterTooltip => 'Next chapter';

  @override
  String chaptersCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count chapters',
      one: '$count chapter',
      zero: 'No chapters',
    );
    return '$_temp0';
  }

  @override
  String chapterSaved(String chapter) {
    return 'Chapter $chapter saved';
  }

  @override
  String get chapterRead => 'read';

  @override
  String get chapterUnread => 'unread';

  @override
  String mangaAddedToLibrarySuccess(String title) {
    return '$title has been added to the library!';
  }

  @override
  String get errorAddingToLibrary => 'Error adding to library.';

  @override
  String get errorUpdatingChapter => 'Error updating chapter.';

  @override
  String cannotOpenLink(String url) {
    return 'Cannot open link: $url';
  }

  @override
  String get searchHistoryTitle => 'Search history';

  @override
  String get searchEmptyStateMessage => 'Search for a manga, manhwa or manhua';

  @override
  String get clear => 'Clear';

  @override
  String get searchTitle => 'Search';

  @override
  String get searchEmptyHistory => 'No recent searches';

  @override
  String get searchPopularGenres => 'Popular genres';

  @override
  String get biometricAuthTitle => 'Biometric authentication';

  @override
  String get biometricAuthSubtitle =>
      'Use fingerprint or Face ID to sign in quickly';

  @override
  String get enableBiometricAuth => 'Biometric authentication enabled';

  @override
  String get disableBiometricAuth => 'Biometric authentication disabled';

  @override
  String get biometricAuthEnabled => 'Enabled';

  @override
  String get biometricAuthDisabled => 'Disabled';

  @override
  String get biometricAuthFirstTimeTitle => 'Enable biometric authentication?';

  @override
  String get biometricAuthFirstTimeMessage =>
      'Would you like to use your fingerprint or Face ID to sign in quickly in the future?';

  @override
  String get biometricAuthNotAvailable =>
      'Biometric authentication is not available on this device';

  @override
  String get biometricAuthRequiresReconnect =>
      'To enable biometric authentication, please sign in again';

  @override
  String get or => 'Or';

  @override
  String get startTrackingNow => 'Start tracking your reading now';

  @override
  String get username => 'Username';

  @override
  String get confirmPassword => 'Confirm';

  @override
  String get alreadyHaveAccount => 'Already have an account?';

  @override
  String get newPassword => 'New password';

  @override
  String get validationEmailRequired => 'Please enter your email address';

  @override
  String get validationEmailInvalid => 'Please enter a valid email address';

  @override
  String get validationPasswordRequired => 'Please enter your password';

  @override
  String get validationPasswordLength =>
      'Your password must be between 8 and 64 characters';

  @override
  String get validationPasswordComplexity =>
      'Your password must contain at least one lowercase letter, one uppercase letter, and one special character';

  @override
  String get validationConfirmPasswordRequired =>
      'Please confirm your password';

  @override
  String get validationPasswordsDoNotMatch => 'Passwords do not match';

  @override
  String get showPassword => 'Show password';

  @override
  String get hidePassword => 'Hide password';

  @override
  String get emailAlreadyUsed => 'This email address is already registered';

  @override
  String get networkError => 'Please check your internet connection';

  @override
  String get timeoutError =>
      'The server is taking too long to respond. Please try again.';

  @override
  String get passwordStrengthLabel => 'Password strength';

  @override
  String get passwordStrengthWeak => 'Weak';

  @override
  String get passwordStrengthMedium => 'Medium';

  @override
  String get passwordStrengthStrong => 'Strong';

  @override
  String get yes => 'Yes';

  @override
  String get no => 'No';

  @override
  String get yesValidate => 'Yes, validate';

  @override
  String chapterSkipMessage(String prev, String next) {
    return 'You are jumping from chapter $prev to $next.\nMark $prev as read?';
  }

  @override
  String validateReadingMessage(String chapter) {
    return 'Have you finished chapter $chapter?';
  }

  @override
  String get validateReadingHint =>
      'Your progress will be saved automatically.';

  @override
  String get adBlockerTitle => 'Ad Blocker';

  @override
  String get adBlockerDescription =>
      'The ad blocker automatically blocks ads on reading sites.\n\nIf you want to add links or suggest improvements for ad blocking, join our Discord server!';

  @override
  String get adBlockerTooltip => 'Ad blocker information';

  @override
  String get joinDiscord => 'Join Discord';

  @override
  String get joinDiscordSubtitle => 'Share your suggestions and report issues';

  @override
  String get contactUs => 'Contact Us';

  @override
  String get downloads => 'Téléchargements';

  @override
  String get manageDownloads => 'Gérer les téléchargements';

  @override
  String get manageDownloadsSubtitle =>
      'Voir et supprimer les chapitres téléchargés';

  @override
  String get discordLinkError => 'Unable to open Discord link';

  @override
  String get urlCopied => 'URL copied to clipboard';

  @override
  String get urlCopyError => 'Error copying URL';

  @override
  String get copyUrl => 'Copy URL';

  @override
  String get progressUpdated => 'Progress updated';

  @override
  String get invalidUrl => 'Invalid URL';

  @override
  String get webModeProgressTracking => 'Web Mode - Progress Tracking';

  @override
  String get webModeProgressDescription =>
      'To track your progress, paste the URL of the chapter you are currently reading.';

  @override
  String get chapterUrlLabel => 'Chapter URL';

  @override
  String get updateProgress => 'Update progress';

  @override
  String get openInNewTab => 'Open in new tab';

  @override
  String get linkUrlLabel => 'Scan site URL';

  @override
  String get linkFormatInfo => 'Chapter format required';

  @override
  String get linkFormatDescription =>
      'Include the chapter number in the URL to enable automatic progress saving.\n\nAccepted formats:\n• /chapter-23/ or /chapitre-23/\n• /c23/ or /ch23/\n• /ep-23/ or /episode-23/\n• ?chapter=23 or ?num=24';

  @override
  String get linkFormatWarning =>
      'No chapter format detected. The link will redirect to the manga page (not a specific chapter).';

  @override
  String get linkFormatDetected =>
      'Chapter format detected! Progress will be saved automatically.';

  @override
  String get linkAddCustomPattern => 'Add a custom pattern for this format';

  @override
  String get customSelectors => 'Custom Selectors';

  @override
  String get manageCustomSelectors => 'Manage Selectors';

  @override
  String get manageCustomSelectorsSubtitle =>
      'Add custom CSS selectors to block ads or identify content';

  @override
  String get addCustomSelector => 'Add Selector';

  @override
  String get selectorDomainLabel => 'Domain (e.g., example.com)';

  @override
  String get selectorCssLabel => 'CSS Selector';

  @override
  String get selectorTypeLabel => 'Selector Type';

  @override
  String get selectorTypeUrlPattern => 'URL Pattern';

  @override
  String get selectorUrlPatternLabel => 'URL Pattern (regex)';

  @override
  String get selectorUrlPatternHint =>
      'Example: /chapter-(\\d+)/ to detect /chapter-22';

  @override
  String get selectorExamplesUrlPattern => 'URL Pattern Examples:';

  @override
  String get selectorExampleUrlPattern => 'Example: /chapter-22';

  @override
  String get selectorExampleUrlPatternExplanation =>
      'If your site uses \"/chapter-22\" in the URL and the system doesn\'t detect it automatically:';

  @override
  String get selectorUrlPatternExampleDesc =>
      'Use a regular expression (regex) with (\\d+) to capture the chapter number.\n\nThis pattern will be applied to ALL sites.\n\nPattern examples:\n• /chapter-(\\d+)/ → detects /chapter-22\n• /chapppter-(\\d+)/ → detects /chapppter-22 (with 3 p\'s)\n• /manga/chapter-(\\d+)/ → detects /manga/chapter-22\n• /episode-(\\d+)/ → detects /episode-22';

  @override
  String get selectorUrlPatternGlobal =>
      'ℹ️ The pattern will be applied to ALL sites. No need to specify a domain.';

  @override
  String get selectorTypeAdBlocker => 'Ad Blocker';

  @override
  String get selectorTypeChapterContent => 'Chapter Content';

  @override
  String get selectorDescriptionLabel => 'Description (optional)';

  @override
  String get selectorDescriptionHint => 'Selector description';

  @override
  String get selectorRequiredFields => 'All fields are required';

  @override
  String get selectorAdded => 'Selector added';

  @override
  String get deleteSelector => 'Delete Selector';

  @override
  String get deleteSelectorConfirm =>
      'Are you sure you want to delete this selector?';

  @override
  String get selectorDeleted => 'Selector deleted';

  @override
  String get selectorsExported => 'Selectors exported to clipboard';

  @override
  String get importSelectors => 'Import Selectors';

  @override
  String get selectorsJsonLabel => 'Selectors JSON';

  @override
  String get import => 'Import';

  @override
  String selectorsImported(String count) {
    return '$count selector(s) imported';
  }

  @override
  String get selectorsReadyToShare =>
      'Selectors ready to share! Paste the JSON in Discord.';

  @override
  String get exportSelectors => 'Export';

  @override
  String get shareSelectors => 'Share';

  @override
  String get noCustomSelectors => 'No custom selectors';

  @override
  String get addFirstSelector => 'Add your first selector to get started';

  @override
  String get selectorExamples => 'Examples';

  @override
  String get selectorExamplesAdBlocker => 'Examples for blocking ads:';

  @override
  String get selectorExampleAd1 => 'Ad Banner';

  @override
  String get selectorExampleAd2 => 'Ad by ID';

  @override
  String get selectorExampleAd3 => 'Ad Iframe';

  @override
  String get selectorExampleAd4 => 'Ad Script';

  @override
  String get selectorExamplesChapter =>
      'Examples for identifying chapter content:';

  @override
  String get selectorExampleChapter1 => 'Chapter Container';

  @override
  String get selectorExampleChapter2 => 'Manga Reader';

  @override
  String get selectorExampleChapter3 => 'Chapter Images';

  @override
  String get selectorExampleChapter4 => 'Reading Content';

  @override
  String get selectorExampleChapter5 => 'Format manga/chapter-22';

  @override
  String get selectorExampleChapter5Explanation =>
      'Concrete example: If your URL is \"mysite.com/manga/chapter-22\"';

  @override
  String get selectorUrlFormatDetected =>
      '✅ GOOD NEWS: The \"/manga/chapter-22\" format in the URL is already automatically detected by the system!\n\nYou do NOT need to add a CSS selector if your site only uses this format in the URL.';

  @override
  String get selectorWhenNeeded => 'When to add a CSS selector?';

  @override
  String get selectorPracticalExample => 'Practical example:';

  @override
  String get selectorExampleScenario =>
      'Case: Your site uses \"/chapppter-22\" (with 3 p\'s) instead of \"/chapter-22\"';

  @override
  String get selectorStep1 => 'Open the chapter page in your browser';

  @override
  String get selectorStep2 => 'Press F12 to open developer tools';

  @override
  String get selectorStep3 => 'Click on the \"Inspect\" icon (or Ctrl+Shift+C)';

  @override
  String get selectorStep4 =>
      'Click on the container that contains the chapter images';

  @override
  String get selectorStep5 =>
      'In the HTML code, find the container\'s class or ID';

  @override
  String get selectorFillForm => 'Fill in the form:';

  @override
  String get selectorCssWhenNeededDesc =>
      '⚠️ ONLY if your site needs a specific selector to identify the HTML content of the page.\n\nIf the system already detects your chapter correctly via the URL, you do NOT need to add a CSS selector.\n\nAdd a CSS selector ONLY if:\n• The system does not correctly detect the chapter content\n• You want to block ads specific to this site\n• The site uses particular classes/IDs for content\n\nTo find the selector: Open the page (F12 → Inspect), find the container of chapter images, and use its class or ID (e.g., .manga-content, #chapter-images)';

  @override
  String get selectorDomainExampleDesc =>
      'Enter only the domain name (without http://, without www, without the path /manga/chapter-22)';

  @override
  String get selectorOtherExamples => 'Other common examples:';

  @override
  String get selectorExampleChapter5Desc =>
      'For sites using the manga/chapter-22 format in their URLs. Example: if your URL is \"site.com/manga/chapter-22\", use these selectors to identify the content.';

  @override
  String get selectorExamplesHint =>
      'Tip: Use your browser\'s developer tools (F12) to inspect elements and find appropriate CSS selectors.';

  @override
  String get captchaDetected =>
      'Captcha detected - Ad blocker has been temporarily disabled';

  @override
  String get captchaResolved =>
      'Captcha resolved - Ad blocker has been re-enabled';

  @override
  String get scrollPositionSaved => 'Scroll position saved';

  @override
  String get chapterProgressSaved => 'Chapter progress saved';

  @override
  String get readingOffline => 'Reading offline';

  @override
  String get chapterDownloaded => 'Chapter downloaded';

  @override
  String get offlineReadingMode => 'Offline reading mode';

  @override
  String get deleteChapterTitle => 'Delete chapter';

  @override
  String deleteChapterMessage(int chapterNumber) {
    return 'Do you really want to delete chapter $chapterNumber?';
  }

  @override
  String get deleteAllChaptersTitle => 'Delete all chapters';

  @override
  String get deleteAllChaptersMessage =>
      'Do you really want to delete all downloaded chapters for this manga?';

  @override
  String get deleteAllDownloadsTitle => 'Delete all downloads';

  @override
  String get deleteAllDownloadsMessage =>
      'Do you really want to delete ALL downloads? This action is irreversible.';

  @override
  String get deleteAll => 'Delete all';

  @override
  String get chapterDeleted => 'Chapter deleted';

  @override
  String get allChaptersDeleted => 'All chapters deleted';

  @override
  String get allDownloadsDeleted => 'All downloads deleted';

  @override
  String get noChaptersDownloaded => 'No chapters downloaded';

  @override
  String chaptersDownloadedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count chapters downloaded',
      one: '1 chapter downloaded',
      zero: 'No chapters downloaded',
    );
    return '$_temp0';
  }

  @override
  String get readChapter => 'Read';

  @override
  String get deleteAllChaptersAction => 'Delete all chapters';

  @override
  String get deleteAllDownloadsTooltip => 'Delete all downloads';

  @override
  String get recommendedForYou => 'Recommended for you';

  @override
  String get recommendedForYouEmpty =>
      'Add manga to your library\nto get personalized recommendations.';

  @override
  String recommendedForYouCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count manga',
      one: '1 manga',
    );
    return '$_temp0';
  }

  @override
  String get recommendedForYouCached => 'Cached recommendations (offline mode)';

  @override
  String errorWithMessage(String message) {
    return 'Error: $message';
  }

  @override
  String recommendedBecauseOf(String titles) {
    return 'Because you liked $titles';
  }

  @override
  String get yourRating => 'Your rating';

  @override
  String get myDataTitle => 'My data';

  @override
  String get myDataSubtitle => 'View, export, or delete my data (GDPR)';

  @override
  String get gdprIntro =>
      'Under GDPR, you have rights over your personal data. This page lets you exercise them easily.';

  @override
  String get gdprAccessTitle => 'View my data';

  @override
  String get gdprAccessSubtitle => 'Article 15 — summary of stored information';

  @override
  String get gdprExportTitle => 'Export my data';

  @override
  String get gdprExportSubtitle => 'Article 20 — full JSON copied to clipboard';

  @override
  String get gdprLegalDocs => 'Legal documents';

  @override
  String get gdprDeleteHint =>
      'To permanently delete your account, go to Profile → Delete my account. This action is irreversible.';

  @override
  String get privacyPolicyTitle => 'Privacy Policy';

  @override
  String get termsOfServiceTitle => 'Terms of Service';

  @override
  String get myDataInfoBanner =>
      'Under GDPR, you have the right to access your data, export it, and request its deletion.';

  @override
  String get myDataSectionPersonalData => 'Personal data';

  @override
  String get myDataSectionMyRights => 'My rights';

  @override
  String get myDataSectionDeletion => 'Deletion';

  @override
  String get myDataSummaryTitle => 'My data summary';

  @override
  String get myDataSummarySubtitle => 'See an overview of your stored data';

  @override
  String get myDataExportSubtitle =>
      'Download a complete JSON file (article 20)';

  @override
  String get privacyPolicySubtitle => 'Read the full document';

  @override
  String get termsOfServiceSubtitle => 'View the Terms';

  @override
  String get myDataDeleteAccountSubtitle => 'This action is irreversible';

  @override
  String get gdprExportSuccessSnack =>
      'Your data has been copied to the clipboard (JSON).';

  @override
  String get gdprExportFailedSnack => 'Export failed';

  @override
  String get gdprSummaryLoadFailed => 'Loading error';

  @override
  String get myDataBackLabel => 'Profile';

  @override
  String get tosShortVersion =>
      'Manga Tracker is provided as-is, without warranty. The publisher disclaims all liability for non-compliant use by the user (illegal content, scraping, etc.).\n\nFull document on the official website.';

  @override
  String get privacyShortVersion =>
      'Data collected: email, password (hashed), manga library, preferences. No data is sold to third parties. You can export or delete your data at any time.\n\nFull document on the official website.';

  @override
  String get iAcceptTos => 'I accept the Terms of Service';

  @override
  String get iAcceptPrivacy => 'I accept the Privacy Policy';

  @override
  String get iAccept => 'Accept';

  @override
  String get consentRequired =>
      'You must accept the Terms of Service and Privacy Policy.';

  @override
  String get consentRefreshTitle => 'Our terms have been updated';

  @override
  String get consentRefreshIntro =>
      'Our terms of service and privacy policy have been updated. Please accept them to continue.';

  @override
  String get refuseAndLogout => 'Refuse and log out';

  @override
  String get versionLabel => 'Version';

  @override
  String get welcomeTitle => 'Welcome!';

  @override
  String get loginSubtitle => 'Sign in to your account';

  @override
  String get createAccountTitle => 'Create an account';

  @override
  String get registerSubtitle => 'Start tracking your reading';

  @override
  String get orLoginWith => 'or sign in with';

  @override
  String get orSignUpWith => 'or sign up with';

  @override
  String get continueWithApple => 'Continue with Apple';

  @override
  String get loadingApp => 'Loading…';

  @override
  String get forgotPasswordTitle => 'Forgot password';

  @override
  String get forgotPasswordIntro =>
      'Enter your email. If an account exists, you will receive a link to set a new password.';

  @override
  String get sendResetLink => 'Send link';

  @override
  String get resetEmailSentTitle => 'Check your inbox';

  @override
  String resetEmailSentMessage(String email) {
    return 'If an account exists for $email, an email containing a link to set a new password has just been sent.\n\nThe link expires in 30 minutes.';
  }

  @override
  String get resetPasswordTitle => 'New password';

  @override
  String get resetPasswordIntro =>
      'Set a new password for your account. Once validated, you will be automatically signed in.';

  @override
  String get confirmReset => 'Confirm';

  @override
  String get resetTokenExpired =>
      'Invalid or expired link. Please request a new one.';

  @override
  String get resetPasswordSuccess => 'Password changed';

  @override
  String get resetPasswordSuccessHint => 'You are now signed in. Redirecting…';

  @override
  String get verifyingEmail => 'Verifying…';

  @override
  String get emailVerifiedSuccess => 'Email verified!';

  @override
  String get emailVerifiedHint => 'Signing in…';

  @override
  String get emailVerifyFailedTitle => 'Invalid or expired link';

  @override
  String get emailVerifyFailedHint =>
      'The link you used is no longer valid. Sign in and request a new link from your profile.';

  @override
  String get backToLogin => 'Back to sign in';

  @override
  String get verifyEmailBannerMessage =>
      'Verify your email address to activate all features.';

  @override
  String get emailSentShort => 'Sent';

  @override
  String get resendEmailShort => 'Resend';

  @override
  String get recommendedForYouHome => 'Recommended for you';

  @override
  String get seeMoreByGenre => 'See more by genre';

  @override
  String get recommendationsByGenreTitle => 'Recommendations by genre';

  @override
  String get recommendationsByGenreEmpty =>
      'No recommendations yet. Add some mangas to your library to get personalised picks.';

  @override
  String get recommendationsAllTitle => 'All recommendations';

  @override
  String get recommendationsAllEmpty => 'No recommendations for you yet.';

  @override
  String get seeAllRecommendations => 'See all';

  @override
  String get browseByGenre => 'By genre';

  @override
  String get recommendationsTabAll => 'All';

  @override
  String get recommendationsTabByGenre => 'By genre';

  @override
  String get statsTitle => 'My stats';

  @override
  String get statsTotalMangas => 'mangas in your library';

  @override
  String statsMemberSince(String date) {
    return 'Member since $date';
  }

  @override
  String get statsTotalChapters => 'Chapters read';

  @override
  String get statsReadingTime => 'Estimated reading time';

  @override
  String get statsCompletionRate => 'Completion rate';

  @override
  String get statsLastRead => 'Last read';

  @override
  String get statsByStatusTitle => 'Breakdown by status';

  @override
  String get statsByStatusEmpty => 'No manga in your library yet.';

  @override
  String get statsTopGenresTitle => 'Favourite genres';

  @override
  String get statsTopGenresEmpty =>
      'Add some mangas to discover your favourite genres.';

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
  String get statusReadLater => 'To read';

  @override
  String get statusReading => 'Reading';

  @override
  String get statusCaughtUp => 'Caught up';

  @override
  String get statusCompleted => 'Completed';

  @override
  String get statsSectionOverview => 'Overview';

  @override
  String get statsSectionBreakdown => 'Manga by status';

  @override
  String get statsSectionGenres => 'Favourite genres';

  @override
  String get statsLibraryTotal => 'Mangas in your library';

  @override
  String statsMonthsSinceJoin(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Member for $count months',
      one: 'Member for 1 month',
      zero: 'Member for less than a month',
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
  String get profileMyStats => 'My stats';

  @override
  String get profileEditTitle => 'Edit my profile';

  @override
  String get profileEditBackLabel => 'Profile';

  @override
  String get profileEditMenuTitle => 'Edit profile';

  @override
  String get profileEditMenuSubtitle => 'Photo, display name, bio, privacy';

  @override
  String get profileFieldAvatarUrl => 'Avatar URL';

  @override
  String get profileFieldDisplayName => 'Display name';

  @override
  String get profileFieldBio => 'Bio';

  @override
  String get profileFieldDateOfBirth => 'Date of birth';

  @override
  String get profileFieldGender => 'Gender';

  @override
  String get profileGenderNotSet => 'Not set';

  @override
  String get profileGenderMale => 'Male';

  @override
  String get profileGenderFemale => 'Female';

  @override
  String get profileGenderNonBinary => 'Non-binary';

  @override
  String get profileGenderPreferNotToSay => 'Prefer not to say';

  @override
  String get profileFieldIsPublic => 'Public profile';

  @override
  String get profileFieldIsPublicSubtitle => 'Visible to other users';

  @override
  String get profileSaved => 'Profile saved';

  @override
  String get profileSaveFailed => 'Could not save';

  @override
  String get friendsTitle => 'Friends';

  @override
  String get friendsTabAccepted => 'Friends';

  @override
  String get friendsTabPending => 'Requests';

  @override
  String get friendsSearchLabel => 'Find a friend';

  @override
  String get friendsSearchHint => 'Type a username (min 2 chars)';

  @override
  String get friendsAddRequest => 'Send request';

  @override
  String get friendsAccept => 'Accept';

  @override
  String get friendsReject => 'Reject';

  @override
  String get friendsRemove => 'Remove';

  @override
  String get friendsRequestSent => 'Request sent';

  @override
  String get friendsError => 'Error';

  @override
  String get friendsEmptyAccepted => 'No friends yet';

  @override
  String get friendsEmptyAcceptedSubtitle =>
      'Search for users above to add them.';

  @override
  String get friendsEmptyPending => 'No pending requests';

  @override
  String get friendsEmptyPendingSubtitle =>
      'Incoming requests will appear here.';

  @override
  String get friendsSectionAccepted => 'My friends';

  @override
  String get friendsSectionPending => 'Received requests';

  @override
  String get friendsSearchClear => 'Clear';

  @override
  String get friendsSearchResults => 'Results';

  @override
  String get friendsSearchEmpty => 'No user found.';

  @override
  String get profileMyFriends => 'My friends';

  @override
  String get commentsTitle => 'Comments';

  @override
  String get commentsEmpty => 'No comments yet. Be the first!';

  @override
  String get commentsSortRecent => 'Recent';

  @override
  String get commentsSortTop => 'Top';

  @override
  String get commentsInputHint => 'Share your thoughts (3-2000 characters)';

  @override
  String get commentsPost => 'Post';

  @override
  String get commentsDelete => 'Delete';

  @override
  String get commentsLoadMore => 'Load more';

  @override
  String commentsReplyCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count replies',
      one: '1 reply',
    );
    return '$_temp0';
  }

  @override
  String get timeJustNow => 'just now';

  @override
  String timeMinutesAgo(int count) {
    return '${count}m ago';
  }

  @override
  String timeHoursAgo(int count) {
    return '${count}h ago';
  }

  @override
  String timeDaysAgo(int count) {
    return '${count}d ago';
  }

  @override
  String get shareTitle => 'Share this manga';

  @override
  String get shareMessageHint => 'Add a message (optional)';

  @override
  String get shareCancel => 'Cancel';

  @override
  String get shareSend => 'Send';

  @override
  String get shareSuccess => 'Manga shared';

  @override
  String get shareFailed => 'Share failed';

  @override
  String get shareLoadError => 'Could not load your friends';

  @override
  String get shareNoFriends =>
      'You have no friends to share with yet. Add some from the Friends page.';

  @override
  String get inboxTitle => 'Inbox';

  @override
  String get inboxEmpty => 'No recommendations yet.';

  @override
  String get inboxBadgeNew => 'NEW';

  @override
  String inboxSenderRecommends(String sender) {
    return '$sender recommends';
  }

  @override
  String inboxSharedYouLabel(String sender) {
    return '$sender shared with you';
  }

  @override
  String get inboxFilterAll => 'All';

  @override
  String get inboxFilterUnread => 'Unread';

  @override
  String get inboxFilterRead => 'Read';

  @override
  String get inboxGroupToday => 'Today';

  @override
  String get inboxGroupYesterday => 'Yesterday';

  @override
  String get inboxGroupThisWeek => 'This week';

  @override
  String get inboxGroupOlder => 'Earlier';

  @override
  String get inboxEmptyTitle => 'No recommendations';

  @override
  String get inboxEmptySubtitle =>
      'Ask your friends to share their favourite reads with you.';

  @override
  String get inboxEmptyFilteredUnread => 'No unread recommendations.';

  @override
  String get inboxEmptyFilteredRead => 'No read recommendations.';

  @override
  String get profileMyInbox => 'Inbox';

  @override
  String get readingGroupsTitle => 'Reading buddies';

  @override
  String get readingGroupsEmpty =>
      'No reading groups yet. Create one from a manga\'s detail page.';

  @override
  String get readingGroupDetailTitle => 'Reading group';

  @override
  String get readingGroupMembersTitle => 'Members';

  @override
  String get readingGroupOwnerBadge => 'OWNER';

  @override
  String get readingGroupOpenManga => 'Open manga';

  @override
  String get readingGroupNotStarted => 'Not started';

  @override
  String readingGroupChaptersRead(int count) {
    return 'Ch. $count';
  }

  @override
  String get readingGroupChaptersReadLabel => 'read';

  @override
  String readingGroupMembersCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count members',
      one: '1 member',
    );
    return '$_temp0';
  }

  @override
  String get profileMyReadingGroups => 'Reading buddies';

  @override
  String get profileSectionPublicInfo => 'Public information';

  @override
  String get profileSectionAbout => 'About you';

  @override
  String get profileSectionPrivacy => 'Privacy';

  @override
  String get profileNotSet => 'Not set';

  @override
  String get profileSectionAvatar => 'Avatar';

  @override
  String get profileEditAvatarHeroHint =>
      'Preview updates when you paste an image URL.';

  @override
  String get profileEditPickPhoto => 'Choose a photo';

  @override
  String get profileEditClearAvatar => 'Clear';

  @override
  String get profileEditPhotoPickFailed => 'Could not pick the photo';

  @override
  String get profileGenderClear => 'Clear';

  @override
  String get avatarUrlLabel => 'Avatar URL';

  @override
  String get avatarUrlInvalid => 'URL must start with http:// or https://';

  @override
  String get profileSectionAccount => 'Account';

  @override
  String get profileFieldUsername => 'Username';

  @override
  String get profileFieldEmail => 'Email';

  @override
  String get profileFieldReadOnly => 'Read only';

  @override
  String get profileChangePhoto => 'Change photo';

  @override
  String get changelogCardTitle => 'Release notes';

  @override
  String get readingGroupCreateTitle => 'Read together';

  @override
  String get readingGroupCreateNameLabel => 'Group name (optional)';

  @override
  String get readingGroupCreateNameHint => 'e.g. Berserk with Lea';

  @override
  String get readingGroupCreateInviteSection => 'Invite friends';

  @override
  String get readingGroupCreateConfirm => 'Create group';

  @override
  String get readingGroupCreateFailed => 'Group creation failed';

  @override
  String get readingGroupCreateInviteRequired =>
      'Select at least one friend to create the group';

  @override
  String get readingGroupDelete => 'Delete group';

  @override
  String get readingGroupDeleteConfirmTitle => 'Delete this group?';

  @override
  String get readingGroupDeleteConfirm =>
      'This action is irreversible. All members will lose access to the group.';

  @override
  String get readingGroupDeleteSuccess => 'Group deleted';

  @override
  String get readingGroupDeleteFailed => 'Group deletion failed';

  @override
  String get readingGroupSharedReading => 'Shared reading';

  @override
  String get readingGroupViewGroup => 'View group';

  @override
  String get readingGroupChapterShort => 'ch.';

  @override
  String get profileHighlightTitle => 'New features';

  @override
  String get profileNewBadge => 'New';

  @override
  String get profileFooterBrand => 'MANGA TRACKER';

  @override
  String get readingGroupListSectionTitle => 'My groups';

  @override
  String readingGroupWithLabel(String name) {
    return 'With $name';
  }

  @override
  String get readingGroupYouLabel => 'You';

  @override
  String readingGroupProgressYouVsFriend(
    String you,
    String friend,
    String their,
  ) {
    return 'You: ch. $you · $friend: ch. $their';
  }

  @override
  String get readingGroupChapterDash => '—';

  @override
  String get readingGroupSectionHero => 'Currently reading';

  @override
  String get readingGroupSectionProgress => 'Progress';

  @override
  String get readingGroupSectionActions => 'Actions';

  @override
  String get readingGroupActionsMarkProgress => 'Update my progress';

  @override
  String get readingGroupActionsMarkProgressSubtitle =>
      'Open the manga page to read on';

  @override
  String get readingGroupActionsInvite => 'Invite a friend';

  @override
  String readingGroupActionsCopyFriendLink(String friend) {
    return 'Copy $friend\'s link';
  }

  @override
  String readingGroupActionsCopyFriendLinkSubtitle(int chapter) {
    return 'Adapted to chapter $chapter';
  }

  @override
  String readingGroupApplyLinkSuccess(int chapter) {
    return 'Link saved on chapter $chapter';
  }

  @override
  String readingGroupCopyLinkSuccess(int chapter) {
    return 'Link copied — chapter $chapter';
  }

  @override
  String get readingGroupCopyLinkFailed =>
      'Cannot adapt this link (unknown format)';

  @override
  String get readingGroupActionsInviteSubtitle => 'Add someone to the group';

  @override
  String get readingGroupActionsLeave => 'Leave group';

  @override
  String get readingGroupActionsLeaveSubtitle =>
      'You will no longer see shared progress';

  @override
  String get readingGroupActionsDeleteSubtitle =>
      'Permanently delete for all members';

  @override
  String get readingGroupLeaveConfirmTitle => 'Leave this group?';

  @override
  String get readingGroupLeaveConfirm =>
      'You will lose access to the shared progress.';

  @override
  String get readingGroupLeaveSuccess => 'You left the group';

  @override
  String get readingGroupLeaveFailed => 'Could not leave the group';

  @override
  String get readingGroupEmptyTitle => 'No shared readings yet';

  @override
  String get readingGroupEmptySubtitle =>
      'Start a manga with a friend and track your progress together.';

  @override
  String get readingGroupEmptyAction => 'Discover a manga';

  @override
  String get readingGroupTotalLabel => 'Total';

  @override
  String readingGroupChaptersTotal(int count) {
    return '$count ch.';
  }

  @override
  String get readingGroupInviteSoonTitle => 'Coming soon';

  @override
  String get readingGroupInviteSoonMessage =>
      'Inviting from inside a group is coming soon. For now, create a new group from the manga page.';

  @override
  String get libraryToggleListView => 'List view';

  @override
  String get libraryToggleCardView => 'Card view';

  @override
  String get libraryShowDownloadedOnly => 'Show downloaded only';

  @override
  String get libraryShowAllMangas => 'Show all mangas';

  @override
  String libraryProgressLabel(int read, int total) {
    return '$read out of $total chapters read';
  }

  @override
  String votesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count votes',
      one: '1 vote',
      zero: 'No votes',
    );
    return '$_temp0';
  }

  @override
  String get detailSectionSimilar => 'Similar mangas';

  @override
  String get rating => 'Rating';

  @override
  String get anonymousUser => 'Anonymous user';

  @override
  String get recommendationsColdStartTitle => 'Discover popular manga';

  @override
  String get recommendationsColdStartSubtitle =>
      'Add your first reads to get personalized recommendations';

  @override
  String get friendLibraryError => 'Unable to load this friend’s library.';

  @override
  String get friendLibraryEmpty => 'Their library is empty for now.';

  @override
  String friendLibraryCount(int count) {
    return '$count manga in their library';
  }

  @override
  String get statsHistoryTitle => 'Recent reads';

  @override
  String get statsActivityTitle => 'Reading activity';

  @override
  String get statsBonusTag => 'Side story';

  @override
  String get statsNoHistory =>
      'No reading recorded yet. Update your progress to start your history.';

  @override
  String get reportMoreChaptersCta => 'Report more chapters';

  @override
  String get reportMoreChaptersDialogTitle => 'Report more chapters';

  @override
  String get reportMoreChaptersExplainer =>
      'Read more chapters than the known total? Enter the new total: it will count towards your progress and be checked against other readers\' reports.';

  @override
  String get reportMoreChaptersInputLabel => 'New chapter total';

  @override
  String reportMoreChaptersInvalidLow(int total) {
    return 'The total must be greater than $total.';
  }

  @override
  String reportMoreChaptersInvalidHigh(int max) {
    return 'The total cannot exceed $max.';
  }

  @override
  String get reportMoreChaptersSubmit => 'Report';

  @override
  String get reportMoreChaptersSuccess =>
      'Thanks! The chapter count has been updated.';

  @override
  String get reportMoreChaptersError =>
      'Unable to send the report right now. Please try again later.';

  @override
  String get reportMoreChaptersOffline => 'Unavailable offline.';

  @override
  String get recommendationsSleepersTitle => '💎 Hidden gems';
}
