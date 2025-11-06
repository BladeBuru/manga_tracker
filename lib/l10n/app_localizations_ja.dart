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
}
