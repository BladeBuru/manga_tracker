// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Japanese (`ja`).
class AppLocalizationsJa extends AppLocalizations {
  AppLocalizationsJa([String locale = 'ja']) : super(locale);

  @override
  String get appTitle => 'MangaTracker';

  @override
  String get welcomeBack => 'おかえりなさい';

  @override
  String get emailAddress => 'メールアドレス';

  @override
  String get password => 'パスワード';

  @override
  String get forgotPassword => 'パスワードをお忘れですか？';

  @override
  String get login => 'サインイン';

  @override
  String get googleLoginFailed => 'Googleログインに失敗しました';

  @override
  String get googleLoginConfigError => 'Googleログインを利用できません（アプリ設定エラー）';

  @override
  String get googlePopupBlocked =>
      'ログインウィンドウがブラウザにブロックされました。このサイトのポップアップを許可して再試行してください';

  @override
  String get loginWithGoogle => 'Googleでサインイン';

  @override
  String get back => '戻る';

  @override
  String get signUp => 'サインアップ';

  @override
  String get invalidCredentials => '無効な認証情報';

  @override
  String get unknownError => '不明なエラー';

  @override
  String get trending => 'トレンド';

  @override
  String get popular => '人気';

  @override
  String get newMangas => '新着';

  @override
  String get offlineMode => 'オフラインモード';

  @override
  String get offlineModeNoCache => 'オフラインモード - キャッシュデータなし';

  @override
  String get offlineModeActionQueued => 'オフラインモード - アクションキュー';

  @override
  String pendingActions(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count件',
      one: '$count件',
      zero: '',
    );
    return '保留中のアクション $_temp0';
  }

  @override
  String get retry => '再試行';

  @override
  String get searchNoResults => '結果が見つかりません';

  @override
  String searchResultsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count件の結果',
    );
    return '$_temp0';
  }

  @override
  String get searchLoadFailed => '検索に失敗しました';

  @override
  String get searchLoadMoreFailed => '続きを読み込めませんでした';

  @override
  String get error => 'エラー';

  @override
  String get library => 'ライブラリ';

  @override
  String get search => '検索';

  @override
  String get profile => 'プロフィール';

  @override
  String get account => 'アカウント';

  @override
  String get settings => '設定';

  @override
  String get actions => 'アクション';

  @override
  String get changePassword => 'パスワードを変更';

  @override
  String get changePasswordSubtitle => 'ログインパスワードを変更';

  @override
  String get changePasswordTitle => 'パスワードを変更';

  @override
  String get changePasswordIntro =>
      '現在のパスワードを入力し、新しいパスワードを設定してください。他の端末はログアウトされます。';

  @override
  String get currentPasswordLabel => '現在のパスワード';

  @override
  String get newPasswordLabel => '新しいパスワード';

  @override
  String get confirmNewPasswordLabel => '新しいパスワード（確認）';

  @override
  String get changePasswordSuccess => 'パスワードを変更しました';

  @override
  String get changePasswordSuccessHint => '他の端末はログアウトされました。プロフィールに戻ります…';

  @override
  String get changePasswordWrongCurrent => '現在のパスワードが正しくありません';

  @override
  String get changePasswordSocialAccount =>
      'このアカウントはGoogleログインを使用しているため、変更できるパスワードはありません';

  @override
  String get accountInformation => 'アカウント情報';

  @override
  String get email => 'メール';

  @override
  String get notifications => '通知';

  @override
  String get newChapterNotifications => '新しい章の通知';

  @override
  String get newChapterNotificationsEnabled => '有効';

  @override
  String get newChapterNotificationsDisabled => '無効';

  @override
  String get manageNotifications => '通知を管理';

  @override
  String get notifSectionApp => 'アプリの通知';

  @override
  String get notifSectionInfo => '情報';

  @override
  String get notifNewChaptersTitle => '新しい章';

  @override
  String get notifNewChaptersSubtitle => 'フォロー中の漫画が新しい章を公開したときに通知を受け取ります';

  @override
  String get notifFriendReqTitle => '友達リクエスト';

  @override
  String get notifFriendReqSubtitle => '誰かがあなたを友達に追加したいと言っています';

  @override
  String get notifSharesTitle => '受け取ったおすすめ';

  @override
  String get notifSharesSubtitle => '友達があなたに漫画を共有します';

  @override
  String get notifPermissionExplanation =>
      '通知はアプリがシステム権限を持っている場合にのみ表示されます。受け取れない場合は、電話の設定から有効にしてください。';

  @override
  String get notifOpenSystemSettings => 'システム設定を開く';

  @override
  String get pushNotifFriendRequestTitle => '新しい友達リクエスト';

  @override
  String pushNotifFriendRequestBody(String senderUsername) {
    return '$senderUsernameがあなたを友達に追加したいと思っています';
  }

  @override
  String get pushNotifShareTitle => '新しい漫画が共有されました';

  @override
  String pushNotifShareBody(String senderUsername, String mangaTitle) {
    return '$senderUsernameが$mangaTitleをおすすめしています';
  }

  @override
  String get theme => 'テーマ';

  @override
  String get lightMode => 'ライトモード';

  @override
  String get darkMode => 'ダークモード';

  @override
  String get systemMode => 'システム';

  @override
  String get language => '言語';

  @override
  String get selectLanguage => '言語を選択';

  @override
  String get french => 'フランス語';

  @override
  String get english => '英語';

  @override
  String get logout => 'サインアウト';

  @override
  String get logoutSubtitle => 'アカウントからサインアウト';

  @override
  String get confirmLogout => 'サインアウト';

  @override
  String get confirmLogoutMessage => '本当にサインアウトしますか？';

  @override
  String get deleteAccount => 'アカウントを削除';

  @override
  String get deleteAccountSubtitle => '元に戻せない操作';

  @override
  String get confirmDeleteAccount => 'アカウントを削除';

  @override
  String get confirmDeleteAccountMessage =>
      'この操作は元に戻せません。すべてのデータが永久に削除され、復元できません。';

  @override
  String get cancel => 'キャンセル';

  @override
  String get save => '保存';

  @override
  String get delete => '削除';

  @override
  String get passwordChangedSuccess => 'パスワードが正常に変更されました';

  @override
  String get passwordChangeError => 'パスワード変更エラー';

  @override
  String get accountDeletedSuccess => 'アカウントが正常に削除されました';

  @override
  String get accountDeleteError => 'アカウント削除エラー';

  @override
  String get userInfoLoadError => 'ユーザー情報を読み込めません';

  @override
  String get user => 'ユーザー';

  @override
  String get comingSoon => '近日公開';

  @override
  String get comingSoonAvatar => '近日公開：アバター変更';

  @override
  String get whatsNew => '新機能';

  @override
  String get version => 'バージョン';

  @override
  String get newFeaturesAvailable => '新機能が利用可能';

  @override
  String get currentVersion => '現在のバージョン';

  @override
  String get great => '素晴らしい！';

  @override
  String get authorizationRequired => '認証が必要です';

  @override
  String get modifyLink => 'リンクを変更';

  @override
  String get removeLink => 'リンクを削除';

  @override
  String get chapterSkip => '章をスキップ';

  @override
  String get validateReading => '読書を検証';

  @override
  String get addToLibrary => 'ライブラリに追加';

  @override
  String get removeFromLibrary => 'ライブラリから削除';

  @override
  String get updateStatus => 'ステータスを更新';

  @override
  String get reading => '読書中';

  @override
  String get completed => '完了';

  @override
  String get onHold => '保留中';

  @override
  String get dropped => 'ドロップ';

  @override
  String get planToRead => '読む予定';

  @override
  String get reReading => '再読';

  @override
  String get chapters => '章';

  @override
  String get readChapters => '読んだ章';

  @override
  String get totalChapters => '総章数';

  @override
  String get associatedNames => '関連する名前';

  @override
  String associatedNamesCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count名前',
      one: '$count名前',
      zero: '名前なし',
    );
    return '$_temp0';
  }

  @override
  String get saveProgress => '進捗を保存';

  @override
  String get description => '説明';

  @override
  String get authors => '著者';

  @override
  String get genres => 'ジャンル';

  @override
  String get recommendations => 'おすすめ';

  @override
  String get loading => '読み込み中...';

  @override
  String get noData => 'データがありません';

  @override
  String get noResults => '結果がありません';

  @override
  String get noAccount => 'アカウントをお持ちでないですか？';

  @override
  String get home => 'ホーム';

  @override
  String get myAccount => 'マイアカウント';

  @override
  String get offlineModeCached => 'オフラインモード - キャッシュデータ';

  @override
  String get biometricAuthFailed => '生体認証に失敗しました';

  @override
  String get biometricAuth => '生体認証ログイン';

  @override
  String get addLink => 'リンクを追加';

  @override
  String get addOrModifyLink => 'リンクを追加または変更';

  @override
  String get linkUrlPlaceholder => 'https://example.com';

  @override
  String get validate => '検証';

  @override
  String get invalidLink => '無効なリンク。リンクは http:// または https:// で始まる必要があります';

  @override
  String get linkSaved => 'リンクが保存されました！';

  @override
  String get linkRemoved => 'リンクが削除されました！';

  @override
  String get readOnline => 'オンラインで読む';

  @override
  String get manageLink => 'リンクを管理';

  @override
  String get recommendedMangas => 'おすすめマンガ';

  @override
  String get noRecommendationsAvailable => 'おすすめがありません。';

  @override
  String get close => '閉じる';

  @override
  String get changeStatus => 'ステータスを変更';

  @override
  String get mangaAddedToLibrary => 'マンガがライブラリに追加されました';

  @override
  String get mangaMarkedAs => 'マンガをマーク';

  @override
  String get readLater => '後で読む';

  @override
  String get upToDate => '最新';

  @override
  String get addToReadLater => '\"後で読む\"に追加';

  @override
  String get mangaRemovedFromLibrary => 'マンガがライブラリから削除されました';

  @override
  String get searchPlaceholder => 'マンガ、マンファを検索...';

  @override
  String get year => '年';

  @override
  String get status => 'ステータス';

  @override
  String get author => '著者';

  @override
  String get artist => 'アーティスト';

  @override
  String get synopsis => 'あらすじ';

  @override
  String get seeMore => 'もっと見る';

  @override
  String get seeLess => '折りたたむ';

  @override
  String get all => 'すべて';

  @override
  String get newReleases => '新刊';

  @override
  String get chapter => '章';

  @override
  String chaptersCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count章',
      one: '$count章',
      zero: '章なし',
    );
    return '$_temp0';
  }

  @override
  String chapterSaved(String chapter) {
    return '章 $chapter が保存されました';
  }

  @override
  String get chapterRead => '読了';

  @override
  String get chapterUnread => '未読';

  @override
  String mangaAddedToLibrarySuccess(String title) {
    return '$title がライブラリに追加されました！';
  }

  @override
  String get errorAddingToLibrary => 'ライブラリへの追加エラー。';

  @override
  String get errorUpdatingChapter => '章の更新エラー。';

  @override
  String cannotOpenLink(String url) {
    return 'リンクを開けません：$url';
  }

  @override
  String get searchHistoryTitle => '検索履歴';

  @override
  String get searchEmptyStateMessage => 'マンガ、マンファ、またはマンファを検索';

  @override
  String get clear => 'クリア';

  @override
  String get searchTitle => '検索';

  @override
  String get searchEmptyHistory => '最近の検索はありません';

  @override
  String get searchPopularGenres => '人気のジャンル';

  @override
  String get biometricAuthTitle => '生体認証';

  @override
  String get biometricAuthSubtitle => '指紋またはFace IDを使用してすばやくサインイン';

  @override
  String get enableBiometricAuth => '生体認証が有効になりました';

  @override
  String get disableBiometricAuth => '生体認証が無効になりました';

  @override
  String get biometricAuthEnabled => '有効';

  @override
  String get biometricAuthDisabled => '無効';

  @override
  String get biometricAuthFirstTimeTitle => '生体認証を有効にしますか？';

  @override
  String get biometricAuthFirstTimeMessage =>
      '今後、指紋またはFace IDを使用してすばやくサインインしますか？';

  @override
  String get biometricAuthNotAvailable => 'このデバイスでは生体認証は利用できません';

  @override
  String get biometricAuthRequiresReconnect => '生体認証を有効にするには、再度サインインしてください';

  @override
  String get or => 'または';

  @override
  String get startTrackingNow => '今すぐ読書を追跡し始めましょう';

  @override
  String get username => 'ユーザー名';

  @override
  String get confirmPassword => '確認';

  @override
  String get alreadyHaveAccount => 'すでにアカウントをお持ちですか？';

  @override
  String get newPassword => '新しいパスワード';

  @override
  String get validationEmailRequired => 'メールアドレスを入力してください';

  @override
  String get validationEmailInvalid => '有効なメールアドレスを入力してください';

  @override
  String get validationPasswordRequired => 'パスワードを入力してください';

  @override
  String get validationPasswordLength => 'パスワードは8文字以上64文字以下である必要があります';

  @override
  String get validationPasswordComplexity =>
      'パスワードには、少なくとも1つの小文字、1つの大文字、1つの特殊文字が含まれている必要があります';

  @override
  String get validationConfirmPasswordRequired => 'パスワードを確認してください';

  @override
  String get validationPasswordsDoNotMatch => 'パスワードが一致しません';

  @override
  String get showPassword => 'パスワードを表示';

  @override
  String get hidePassword => 'パスワードを非表示';

  @override
  String get emailAlreadyUsed => 'このメールアドレスは既に登録されています';

  @override
  String get networkError => 'インターネット接続を確認してください';

  @override
  String get timeoutError => 'サーバーの応答に時間がかかっています。もう一度お試しください。';

  @override
  String get passwordStrengthLabel => 'パスワードの強度';

  @override
  String get passwordStrengthWeak => '弱い';

  @override
  String get passwordStrengthMedium => '普通';

  @override
  String get passwordStrengthStrong => '強い';

  @override
  String get yes => 'はい';

  @override
  String get no => 'いいえ';

  @override
  String get yesValidate => 'はい、確認する';

  @override
  String chapterSkipMessage(String prev, String next) {
    return '章 $prev から $next にジャンプします。\n$prev を読了としてマークしますか？';
  }

  @override
  String validateReadingMessage(String chapter) {
    return '章 $chapter を読み終えましたか？';
  }

  @override
  String get validateReadingHint => '進行状況は自動的に保存されます。';

  @override
  String get adBlockerTitle => '広告ブロッカー';

  @override
  String get adBlockerDescription =>
      '広告ブロッカーは、読書サイトの広告を自動的にブロックします。\n\nリンクを追加したり、広告ブロッキングの改善を提案したい場合は、Discordサーバーに参加してください！';

  @override
  String get adBlockerTooltip => '広告ブロッカー情報';

  @override
  String get joinDiscord => 'Discordに参加';

  @override
  String get joinDiscordSubtitle => '提案を共有し、問題を報告する';

  @override
  String get contactUs => 'お問い合わせ';

  @override
  String get downloads => 'Téléchargements';

  @override
  String get manageDownloads => 'Gérer les téléchargements';

  @override
  String get manageDownloadsSubtitle =>
      'Voir et supprimer les chapitres téléchargés';

  @override
  String get discordLinkError => 'Discordリンクを開けません';

  @override
  String get urlCopied => 'URLがクリップボードにコピーされました';

  @override
  String get urlCopyError => 'URLのコピーエラー';

  @override
  String get copyUrl => 'URLをコピー';

  @override
  String get progressUpdated => '進行状況が更新されました';

  @override
  String get invalidUrl => '無効なURL';

  @override
  String get webModeProgressTracking => 'Webモード - 進行状況の追跡';

  @override
  String get webModeProgressDescription =>
      '進行状況を追跡するには、現在読んでいる章のURLを貼り付けてください。';

  @override
  String get chapterUrlLabel => '章のURL';

  @override
  String get updateProgress => '進行状況を更新';

  @override
  String get openInNewTab => '新しいタブで開く';

  @override
  String get linkUrlLabel => 'スキャンサイトのURL';

  @override
  String get linkFormatInfo => '章の形式が必要';

  @override
  String get linkFormatDescription =>
      '自動進行状況保存を有効にするには、URLに章番号を含めてください。\n\n受け入れられる形式:\n• /章-23/ または /chapter-23/\n• /c23/ または /ch23/\n• /ep-23/ または /episode-23/\n• ?chapter=23 または ?num=24';

  @override
  String get linkFormatWarning =>
      '章の形式が検出されませんでした。リンクはマンガページにリダイレクトされます（特定の章ではありません）。';

  @override
  String get linkFormatDetected => '章の形式が検出されました！進行状況は自動的に保存されます。';

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
  String get captchaDetected => 'CAPTCHAが検出されました - 広告ブロッカーが一時的に無効になりました';

  @override
  String get captchaResolved => 'CAPTCHAが解決されました - 広告ブロッカーが再有効化されました';

  @override
  String get scrollPositionSaved => 'スクロール位置が保存されました';

  @override
  String get chapterProgressSaved => '章の進行状況が保存されました';

  @override
  String get readingOffline => 'オフラインで読む';

  @override
  String get chapterDownloaded => '章がダウンロードされました';

  @override
  String get offlineReadingMode => 'オフライン読書モード';

  @override
  String get deleteChapterTitle => '章を削除';

  @override
  String deleteChapterMessage(int chapterNumber) {
    return '本当に章 $chapterNumber を削除しますか？';
  }

  @override
  String get deleteAllChaptersTitle => 'すべての章を削除';

  @override
  String get deleteAllChaptersMessage => 'この漫画のすべてのダウンロード済み章を本当に削除しますか？';

  @override
  String get deleteAllDownloadsTitle => 'すべてのダウンロードを削除';

  @override
  String get deleteAllDownloadsMessage => '本当にすべてのダウンロードを削除しますか？この操作は元に戻せません。';

  @override
  String get deleteAll => 'すべて削除';

  @override
  String get chapterDeleted => '章が削除されました';

  @override
  String get allChaptersDeleted => 'すべての章が削除されました';

  @override
  String get allDownloadsDeleted => 'すべてのダウンロードが削除されました';

  @override
  String get noChaptersDownloaded => 'ダウンロードされた章はありません';

  @override
  String chaptersDownloadedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count章がダウンロードされました',
      one: '1章がダウンロードされました',
      zero: 'ダウンロードされた章はありません',
    );
    return '$_temp0';
  }

  @override
  String get readChapter => '読む';

  @override
  String get deleteAllChaptersAction => 'すべての章を削除';

  @override
  String get deleteAllDownloadsTooltip => 'すべてのダウンロードを削除';

  @override
  String get recommendedForYou => 'あなたへのおすすめ';

  @override
  String get recommendedForYouEmpty => 'ライブラリに漫画を追加して\nパーソナライズされたおすすめを取得しましょう。';

  @override
  String recommendedForYouCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count件',
    );
    return '$_temp0';
  }

  @override
  String get recommendedForYouCached => 'キャッシュされたおすすめ（オフラインモード）';

  @override
  String errorWithMessage(String message) {
    return 'エラー: $message';
  }

  @override
  String recommendedBecauseOf(String titles) {
    return '$titles がお気に入りだったため';
  }

  @override
  String get yourRating => 'あなたの評価';

  @override
  String get myDataTitle => 'マイデータ';

  @override
  String get myDataSubtitle => 'データの表示、エクスポート、削除（GDPR）';

  @override
  String get gdprIntro =>
      'GDPRに基づき、あなたは個人データに関する権利を持っています。このページでそれらを簡単に行使できます。';

  @override
  String get gdprAccessTitle => 'データを表示';

  @override
  String get gdprAccessSubtitle => '第15条 — 保存された情報の概要';

  @override
  String get gdprExportTitle => 'データをエクスポート';

  @override
  String get gdprExportSubtitle => '第20条 — 完全なJSONがクリップボードにコピーされます';

  @override
  String get gdprLegalDocs => '法的文書';

  @override
  String get gdprDeleteHint =>
      'アカウントを完全に削除するには、プロフィール → アカウント削除に移動してください。この操作は元に戻せません。';

  @override
  String get privacyPolicyTitle => 'プライバシーポリシー';

  @override
  String get termsOfServiceTitle => '利用規約';

  @override
  String get myDataInfoBanner => 'GDPRに基づき、データへのアクセス、エクスポート、削除を要求する権利があります。';

  @override
  String get myDataSectionPersonalData => '個人データ';

  @override
  String get myDataSectionMyRights => '私の権利';

  @override
  String get myDataSectionDeletion => '削除';

  @override
  String get myDataSummaryTitle => 'データの概要';

  @override
  String get myDataSummarySubtitle => '保存されたデータの概要を表示';

  @override
  String get myDataExportSubtitle => '完全なJSONファイルをダウンロード（第20条）';

  @override
  String get privacyPolicySubtitle => '完全な文書を読む';

  @override
  String get termsOfServiceSubtitle => '利用規約を表示';

  @override
  String get myDataDeleteAccountSubtitle => 'この操作は元に戻せません';

  @override
  String get gdprExportSuccessSnack => 'データがクリップボードにコピーされました（JSON）。';

  @override
  String get gdprExportFailedSnack => 'エクスポートに失敗しました';

  @override
  String get gdprSummaryLoadFailed => '読み込みエラー';

  @override
  String get myDataBackLabel => 'プロフィール';

  @override
  String get tosShortVersion =>
      'Manga Trackerは現状のまま、保証なしで提供されます。編集者は、ユーザーによる非準拠の使用（違法コンテンツ、スクレイピングなど）に関するすべての責任を否認します。\n\n完全な文書は公式ウェブサイトにあります。';

  @override
  String get privacyShortVersion =>
      '収集データ：メール、パスワード（ハッシュ化）、漫画ライブラリ、設定。データは第三者に販売されません。データはいつでもエクスポートまたは削除できます。\n\n完全な文書は公式ウェブサイトにあります。';

  @override
  String get iAcceptTos => '利用規約に同意します';

  @override
  String get iAcceptPrivacy => 'プライバシーポリシーに同意します';

  @override
  String get iAccept => '同意する';

  @override
  String get consentRequired => '利用規約とプライバシーポリシーに同意する必要があります。';

  @override
  String get consentRefreshTitle => '規約が更新されました';

  @override
  String get consentRefreshIntro => '利用規約とプライバシーポリシーが更新されました。続行するには同意してください。';

  @override
  String get refuseAndLogout => '拒否してログアウト';

  @override
  String get versionLabel => 'バージョン';

  @override
  String get welcomeTitle => 'ようこそ！';

  @override
  String get loginSubtitle => 'アカウントにサインインしてください';

  @override
  String get createAccountTitle => 'アカウントを作成';

  @override
  String get registerSubtitle => '読書の記録を始めましょう';

  @override
  String get orLoginWith => '別の方法でサインイン';

  @override
  String get orSignUpWith => '別の方法で登録';

  @override
  String get continueWithApple => 'Appleで続行';

  @override
  String get loadingApp => '読み込み中…';

  @override
  String get forgotPasswordTitle => 'パスワードをお忘れですか';

  @override
  String get forgotPasswordIntro =>
      'メールアドレスを入力してください。アカウントが存在する場合、新しいパスワードを設定するリンクをお送りします。';

  @override
  String get sendResetLink => 'リンクを送信';

  @override
  String get resetEmailSentTitle => '受信ボックスをご確認ください';

  @override
  String resetEmailSentMessage(String email) {
    return '$email のアカウントが存在する場合、新しいパスワードを設定するためのリンクを含むメールが送信されました。\n\nリンクは30分で期限切れになります。';
  }

  @override
  String get resetPasswordTitle => '新しいパスワード';

  @override
  String get resetPasswordIntro => 'アカウントの新しいパスワードを設定してください。確認後、自動的にログインされます。';

  @override
  String get confirmReset => '確認';

  @override
  String get resetTokenExpired => 'リンクが無効または期限切れです。再度リクエストしてください。';

  @override
  String get resetPasswordSuccess => 'パスワードが変更されました';

  @override
  String get resetPasswordSuccessHint => 'ログインしました。リダイレクト中…';

  @override
  String get verifyingEmail => '確認中…';

  @override
  String get emailVerifiedSuccess => 'メールが確認されました！';

  @override
  String get emailVerifiedHint => 'ログイン中…';

  @override
  String get emailVerifyFailedTitle => 'リンクが無効または期限切れです';

  @override
  String get emailVerifyFailedHint =>
      'ご使用のリンクは有効ではありません。ログインしてプロフィールから新しいリンクをリクエストしてください。';

  @override
  String get backToLogin => 'ログインに戻る';

  @override
  String get verifyEmailBannerMessage => 'すべての機能を有効にするには、メールアドレスを確認してください。';

  @override
  String get emailSentShort => '送信済み';

  @override
  String get resendEmailShort => '再送信';

  @override
  String get recommendedForYouHome => 'あなたへのおすすめ';

  @override
  String get seeMoreByGenre => 'ジャンル別にもっと見る';

  @override
  String get recommendationsByGenreTitle => 'ジャンル別のおすすめ';

  @override
  String get recommendationsByGenreEmpty =>
      'まだおすすめがありません。ライブラリに漫画を追加してパーソナライズされた候補を取得してください。';

  @override
  String get recommendationsAllTitle => 'すべてのおすすめ';

  @override
  String get recommendationsAllEmpty => 'まだあなたへのおすすめはありません。';

  @override
  String get seeAllRecommendations => 'すべて見る';

  @override
  String get browseByGenre => 'ジャンル別';

  @override
  String get recommendationsTabAll => 'すべて';

  @override
  String get recommendationsTabByGenre => 'ジャンル別';

  @override
  String get statsTitle => 'マイ統計';

  @override
  String get statsTotalMangas => '冊がライブラリにあります';

  @override
  String statsMemberSince(String date) {
    return '$dateからのメンバー';
  }

  @override
  String get statsTotalChapters => '読了話数';

  @override
  String get statsReadingTime => '推定読書時間';

  @override
  String get statsCompletionRate => '完了率';

  @override
  String get statsLastRead => '最後に読んだ作品';

  @override
  String get statsByStatusTitle => 'ステータス別';

  @override
  String get statsByStatusEmpty => 'ライブラリに漫画がまだありません。';

  @override
  String get statsTopGenresTitle => '好きなジャンル';

  @override
  String get statsTopGenresEmpty => '漫画を追加して、お気に入りのジャンルを見つけましょう。';

  @override
  String statsMinutesShort(int count) {
    return '$count分';
  }

  @override
  String statsHoursAndMinutesShort(int hours, int minutes) {
    return '$hours時間$minutes分';
  }

  @override
  String statsDaysAndHoursShort(int days, int hours) {
    return '$days日$hours時間';
  }

  @override
  String get statusReadLater => 'あとで読む';

  @override
  String get statusReading => '読書中';

  @override
  String get statusCaughtUp => '最新まで';

  @override
  String get statusCompleted => '完結済み';

  @override
  String get statsSectionOverview => '概要';

  @override
  String get statsSectionBreakdown => 'ステータス別マンガ';

  @override
  String get statsSectionGenres => 'お気に入りのジャンル';

  @override
  String get statsLibraryTotal => 'ライブラリのマンガ';

  @override
  String statsMonthsSinceJoin(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '登録から$countヶ月',
      zero: '登録から1ヶ月未満',
    );
    return '$_temp0';
  }

  @override
  String statsHeroBadge(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count冊',
    );
    return '$_temp0';
  }

  @override
  String get profileMyStats => 'マイ統計';

  @override
  String get profileEditTitle => 'プロフィールを編集';

  @override
  String get profileEditBackLabel => 'プロフィール';

  @override
  String get profileEditMenuTitle => 'プロフィール編集';

  @override
  String get profileEditMenuSubtitle => '写真、表示名、自己紹介、プライバシー';

  @override
  String get profileFieldAvatarUrl => 'アバターURL';

  @override
  String get profileFieldDisplayName => '表示名';

  @override
  String get profileFieldBio => '自己紹介';

  @override
  String get profileFieldDateOfBirth => '生年月日';

  @override
  String get profileFieldGender => '性別';

  @override
  String get profileGenderNotSet => '未設定';

  @override
  String get profileGenderMale => '男性';

  @override
  String get profileGenderFemale => '女性';

  @override
  String get profileGenderNonBinary => 'ノンバイナリー';

  @override
  String get profileGenderPreferNotToSay => '回答しない';

  @override
  String get profileFieldIsPublic => '公開プロフィール';

  @override
  String get profileFieldIsPublicSubtitle => '他のユーザーに表示されます';

  @override
  String get profileSaved => 'プロフィールを保存しました';

  @override
  String get profileSaveFailed => '保存に失敗しました';

  @override
  String get friendsTitle => 'フレンド';

  @override
  String get friendsTabAccepted => 'フレンド';

  @override
  String get friendsTabPending => 'リクエスト';

  @override
  String get friendsSearchLabel => 'フレンドを検索';

  @override
  String get friendsSearchHint => 'ユーザー名を入力（2文字以上）';

  @override
  String get friendsAddRequest => 'リクエストを送信';

  @override
  String get friendsAccept => '承認';

  @override
  String get friendsReject => '拒否';

  @override
  String get friendsRemove => '削除';

  @override
  String get friendsRequestSent => 'リクエストを送信しました';

  @override
  String get friendsError => 'エラー';

  @override
  String get friendsEmptyAccepted => 'フレンドがいません';

  @override
  String get friendsEmptyAcceptedSubtitle => '上の検索でユーザーを追加しましょう。';

  @override
  String get friendsEmptyPending => '保留中のリクエストはありません';

  @override
  String get friendsEmptyPendingSubtitle => '受信したリクエストはここに表示されます。';

  @override
  String get friendsSectionAccepted => 'マイフレンド';

  @override
  String get friendsSectionPending => '受信したリクエスト';

  @override
  String get friendsSearchClear => 'クリア';

  @override
  String get friendsSearchResults => '検索結果';

  @override
  String get friendsSearchEmpty => 'ユーザーが見つかりません。';

  @override
  String get profileMyFriends => 'マイフレンド';

  @override
  String get commentsTitle => 'コメント';

  @override
  String get commentsEmpty => 'まだコメントがありません。最初に投稿しましょう！';

  @override
  String get commentsSortRecent => '新着';

  @override
  String get commentsSortTop => '人気';

  @override
  String get commentsInputHint => '感想を書きましょう（3〜2000文字）';

  @override
  String get commentsPost => '投稿';

  @override
  String get commentsDelete => '削除';

  @override
  String get commentsLoadMore => 'もっと見る';

  @override
  String commentsReplyCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count件の返信',
      one: '1件の返信',
    );
    return '$_temp0';
  }

  @override
  String get timeJustNow => 'たった今';

  @override
  String timeMinutesAgo(int count) {
    return '$count分前';
  }

  @override
  String timeHoursAgo(int count) {
    return '$count時間前';
  }

  @override
  String timeDaysAgo(int count) {
    return '$count日前';
  }

  @override
  String get shareTitle => 'この漫画を共有';

  @override
  String get shareMessageHint => 'メッセージを追加（任意）';

  @override
  String get shareCancel => 'キャンセル';

  @override
  String get shareSend => '送信';

  @override
  String get shareSuccess => '共有しました';

  @override
  String get shareFailed => '共有に失敗しました';

  @override
  String get shareLoadError => 'フレンドを読み込めませんでした';

  @override
  String get shareNoFriends => 'まだ共有できるフレンドがいません。フレンドページから追加してください。';

  @override
  String get inboxTitle => '受信箱';

  @override
  String get inboxEmpty => 'まだおすすめはありません。';

  @override
  String get inboxBadgeNew => '新着';

  @override
  String inboxSenderRecommends(String sender) {
    return '$senderさんがおすすめしています';
  }

  @override
  String inboxSharedYouLabel(String sender) {
    return '$senderさんがシェアしました';
  }

  @override
  String get inboxFilterAll => 'すべて';

  @override
  String get inboxFilterUnread => '未読';

  @override
  String get inboxFilterRead => '既読';

  @override
  String get inboxGroupToday => '今日';

  @override
  String get inboxGroupYesterday => '昨日';

  @override
  String get inboxGroupThisWeek => '今週';

  @override
  String get inboxGroupOlder => 'それ以前';

  @override
  String get inboxEmptyTitle => 'おすすめはありません';

  @override
  String get inboxEmptySubtitle => '友達にお気に入りの作品を共有してもらいましょう。';

  @override
  String get inboxEmptyFilteredUnread => '未読のおすすめはありません。';

  @override
  String get inboxEmptyFilteredRead => '既読のおすすめはありません。';

  @override
  String get profileMyInbox => '受信箱';

  @override
  String get readingGroupsTitle => '一緒に読む';

  @override
  String get readingGroupsEmpty => 'まだ読書グループがありません。漫画の詳細ページから作成しましょう。';

  @override
  String get readingGroupDetailTitle => '読書グループ';

  @override
  String get readingGroupMembersTitle => 'メンバー';

  @override
  String get readingGroupOwnerBadge => 'オーナー';

  @override
  String get readingGroupOpenManga => '漫画を開く';

  @override
  String get readingGroupNotStarted => '未開始';

  @override
  String readingGroupChaptersRead(int count) {
    return '第$count話';
  }

  @override
  String get readingGroupChaptersReadLabel => '読了';

  @override
  String readingGroupMembersCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count人のメンバー',
      one: '1人のメンバー',
    );
    return '$_temp0';
  }

  @override
  String get profileMyReadingGroups => '一緒に読む';

  @override
  String get profileSectionPublicInfo => '公開情報';

  @override
  String get profileSectionAbout => 'あなたについて';

  @override
  String get profileSectionPrivacy => 'プライバシー';

  @override
  String get profileNotSet => '未設定';

  @override
  String get profileSectionAvatar => 'アバター';

  @override
  String get profileEditAvatarHeroHint => '画像URLを貼り付けるとプレビューが更新されます。';

  @override
  String get profileEditPickPhoto => '写真を選ぶ';

  @override
  String get profileEditClearAvatar => 'クリア';

  @override
  String get profileEditPhotoPickFailed => '写真を選択できませんでした';

  @override
  String get profileGenderClear => 'クリア';

  @override
  String get avatarUrlLabel => 'アバターのURL';

  @override
  String get avatarUrlInvalid => 'URLはhttp://またはhttps://で始まる必要があります';

  @override
  String get profileSectionAccount => 'アカウント';

  @override
  String get profileFieldUsername => 'ユーザー名';

  @override
  String get profileFieldEmail => 'メールアドレス';

  @override
  String get profileFieldReadOnly => '変更不可';

  @override
  String get profileChangePhoto => '写真を変更';

  @override
  String get changelogCardTitle => 'リリースノート';

  @override
  String get readingGroupCreateTitle => '一緒に読む';

  @override
  String get readingGroupCreateNameLabel => 'グループ名（任意）';

  @override
  String get readingGroupCreateNameHint => '例：Berserk とレア';

  @override
  String get readingGroupCreateInviteSection => 'フレンドを招待';

  @override
  String get readingGroupCreateConfirm => 'グループを作成';

  @override
  String get readingGroupCreateFailed => 'グループ作成に失敗しました';

  @override
  String get readingGroupCreateInviteRequired =>
      'グループを作成するには少なくとも1人のフレンドを選択してください';

  @override
  String get readingGroupDelete => 'グループを削除';

  @override
  String get readingGroupDeleteConfirmTitle => 'このグループを削除しますか？';

  @override
  String get readingGroupDeleteConfirm =>
      'この操作は取り消せません。すべてのメンバーがグループへのアクセスを失います。';

  @override
  String get readingGroupDeleteSuccess => 'グループを削除しました';

  @override
  String get readingGroupDeleteFailed => 'グループの削除に失敗しました';

  @override
  String get readingGroupSharedReading => '共有読書';

  @override
  String get readingGroupViewGroup => 'グループを見る';

  @override
  String get readingGroupChapterShort => '話';

  @override
  String get profileHighlightTitle => '新機能';

  @override
  String get profileNewBadge => '新着';

  @override
  String get profileFooterBrand => 'MANGA TRACKER';

  @override
  String get readingGroupListSectionTitle => 'マイグループ';

  @override
  String readingGroupWithLabel(String name) {
    return '$name と';
  }

  @override
  String get readingGroupYouLabel => 'あなた';

  @override
  String readingGroupProgressYouVsFriend(
    String you,
    String friend,
    String their,
  ) {
    return 'あなた：$you話 ・ $friend：$their話';
  }

  @override
  String get readingGroupChapterDash => '—';

  @override
  String get readingGroupSectionHero => '読書中';

  @override
  String get readingGroupSectionProgress => '進捗';

  @override
  String get readingGroupSectionActions => '操作';

  @override
  String get readingGroupActionsMarkProgress => '自分の進捗を更新';

  @override
  String get readingGroupActionsMarkProgressSubtitle => 'マンガページを開いて続きを読む';

  @override
  String get readingGroupActionsInvite => '友達を招待';

  @override
  String readingGroupActionsCopyFriendLink(String friend) {
    return '$friendのリンクをコピー';
  }

  @override
  String readingGroupActionsCopyFriendLinkSubtitle(int chapter) {
    return '第$chapter話に調整済み';
  }

  @override
  String readingGroupApplyLinkSuccess(int chapter) {
    return '第$chapter話のリンクを保存しました';
  }

  @override
  String readingGroupCopyLinkSuccess(int chapter) {
    return 'リンクをコピーしました — 第$chapter話';
  }

  @override
  String get readingGroupCopyLinkFailed => 'このリンクを調整できません（不明な形式）';

  @override
  String get readingGroupActionsInviteSubtitle => 'グループに人を追加';

  @override
  String get readingGroupActionsLeave => 'グループを退会';

  @override
  String get readingGroupActionsLeaveSubtitle => '共有された進捗が見えなくなります';

  @override
  String get readingGroupActionsDeleteSubtitle => '全メンバーに対して完全削除します';

  @override
  String get readingGroupLeaveConfirmTitle => 'このグループを退会しますか？';

  @override
  String get readingGroupLeaveConfirm => '共有された進捗にアクセスできなくなります。';

  @override
  String get readingGroupLeaveSuccess => 'グループを退会しました';

  @override
  String get readingGroupLeaveFailed => 'グループを退会できませんでした';

  @override
  String get readingGroupEmptyTitle => '共有読書はまだありません';

  @override
  String get readingGroupEmptySubtitle => '友達と一緒にマンガを始めて、進捗を共有しましょう。';

  @override
  String get readingGroupEmptyAction => 'マンガを探す';

  @override
  String get readingGroupTotalLabel => '合計';

  @override
  String readingGroupChaptersTotal(int count) {
    return '$count 話';
  }

  @override
  String get readingGroupInviteSoonTitle => '近日公開';

  @override
  String get readingGroupInviteSoonMessage =>
      'グループからの招待機能はもうすぐ登場します。現時点ではマンガページから新しいグループを作成してください。';

  @override
  String get libraryToggleListView => 'リスト表示';

  @override
  String get libraryToggleCardView => 'カード表示';

  @override
  String get libraryShowDownloadedOnly => 'ダウンロード済みのみ表示';

  @override
  String get libraryShowAllMangas => 'すべてのマンガを表示';

  @override
  String libraryProgressLabel(int read, int total) {
    return '$total話中$read話を読了';
  }

  @override
  String votesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count票',
      zero: '投票なし',
    );
    return '$_temp0';
  }

  @override
  String get detailSectionSimilar => '類似の漫画';

  @override
  String get rating => '評価';

  @override
  String get anonymousUser => '匿名ユーザー';

  @override
  String get recommendationsColdStartTitle => '人気のマンガを見つけよう';

  @override
  String get recommendationsColdStartSubtitle =>
      '最初の作品を追加すると、あなた好みのおすすめが表示されます';

  @override
  String get friendLibraryError => 'この友達のライブラリを読み込めませんでした。';

  @override
  String get friendLibraryEmpty => 'ライブラリはまだ空です。';

  @override
  String friendLibraryCount(int count) {
    return 'ライブラリに$count作品';
  }

  @override
  String get statsHistoryTitle => '最近の読書';

  @override
  String get statsActivityTitle => '読書アクティビティ';

  @override
  String get statsBonusTag => '番外編';

  @override
  String get statsNoHistory => 'まだ読書記録がありません。リーダーで章を読み終えると履歴が始まります。';

  @override
  String get recommendationsSleepersTitle => '💎 隠れた名作';
}
