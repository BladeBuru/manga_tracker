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
  String get accountInformation => 'アカウント情報';

  @override
  String get email => 'メール';

  @override
  String get notifications => '通知';

  @override
  String get manageNotifications => '通知を管理';

  @override
  String get theme => 'テーマ';

  @override
  String get lightMode => 'ライトモード';

  @override
  String get darkMode => 'ダークモード';

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
}
