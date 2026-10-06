import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:mangatracker/core/router/app_router.dart';
import 'package:mangatracker/core/service_locator/service_locator.dart';
import 'package:mangatracker/core/services/deep_link_handler.dart';
import 'package:mangatracker/core/services/language_service.dart';
import 'package:mangatracker/core/services/theme_service.dart';
import 'package:mangatracker/features/manga/services/chapter_check_background_service.dart';
import 'package:mangatracker/features/manga/services/notification_service.dart';
import 'package:mangatracker/l10n/app_localizations.dart';

import 'package:mangatracker/core/components/system_bars_inset.dart';
import 'core/theme/app_theme.dart';

/// Re-export pour rétrocompatibilité — pointe vers le navigatorKey racine
/// géré par go_router (cf. `core/router/app_router.dart`). Les call sites
/// `navigatorKey.currentContext` (notifier, app_update_service) continuent
/// de fonctionner.
GlobalKey<NavigatorState> get navigatorKey => rootNavigatorKey;
/// Orientations autorisées dans toute l'application.
const List<DeviceOrientation> appOrientations = [
  DeviceOrientation.portraitUp,
  DeviceOrientation.portraitDown,
];

Future<void> main() async {
  // S'assure que les plugins de plateforme sont initialisés avant toute opération async
  WidgetsFlutterBinding.ensureInitialized();
  //
  if (kReleaseMode) {
    await dotenv.load(fileName: "assets/env/.env.production");
    debugPrint('ENV loaded: ${dotenv.env}');
  } else {

    await dotenv.load(fileName: "assets/env/.env.development");
    debugPrint('ENV loaded: ${dotenv.env}');
  }

  // Register all services
  setupServiceLocator();
  await getIt.allReady();

  // Initialiser le service de vérification en arrière-plan
  try {
    final backgroundService = ChapterCheckBackgroundService();
    await backgroundService.initialize();
    // Démarrer la vérification périodique (toutes les 6 heures)
    await backgroundService.startPeriodicCheck(intervalHours: 6);
    
    // Initialiser le service de notifications
    await NotificationService().initialize();
  } catch (e) {
    debugPrint('⚠️ Erreur lors de l\'initialisation du service de vérification en arrière-plan: $e');
  }

  // Portrait dans les deux sens : lire en chargeant, appareil retourné.
  // (Avant : portrait « à l'endroit » seulement.) Le système garde le
  // dernier mot — beaucoup de téléphones refusent le portrait inversé, les
  // tablettes l'acceptent — et le verrou de rotation de l'utilisateur est
  // respecté. Posé une fois ici (et non à chaque reconstruction).
  await SystemChrome.setPreferredOrientations(appOrientations);
  // Bord à bord partout (mode imposé par Android 15, explicite pour les
  // versions antérieures) : `SystemBarsInset` réserve la place des barres
  // du système, et les lecteurs rétablissent ce mode en les quittant.
  if (!kIsWeb) {
    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  }
  runApp(const MyApp());
}

const Color themePage = Color(0xffe0234f);

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  /// Créé une seule fois : une nouvelle instance à chaque rendu notifiait
  /// toutes les zones défilantes de l'application.
  static final ScrollBehavior _scrollBehavior = const ScrollBehavior().copyWith(
    physics: const BouncingScrollPhysics(
      parent: AlwaysScrollableScrollPhysics(),
    ),
  );

  Locale _locale = const Locale('fr', '');
  ThemeMode _themeMode = ThemeMode.system;
  DeepLinkHandler? _deepLinkHandler;
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    _router = buildAppRouter();
    _loadLocale();
    _loadTheme();
    // Écouter les changements de langue via un callback global
    _setupLanguageListener();
    // Écouter les changements de thème via un callback global
    _setupThemeListener();
    // Écouter les deep links (magic link email, reset password)
    _setupDeepLinks();
  }

  Future<void> _setupDeepLinks() async {
    _deepLinkHandler = DeepLinkHandler(navigatorKey: navigatorKey);
    await _deepLinkHandler!.initialize();
  }

  @override
  void dispose() {
    _deepLinkHandler?.dispose();
    super.dispose();
  }

  void _setupLanguageListener() async {
    // Écouter les changements de langue via le LanguageService
    try {
      final languageService = await getIt.getAsync<LanguageService>();
      languageService.onLanguageChanged = (Locale locale) {
        if (mounted) {
          setState(() {
            _locale = locale;
          });
        }
      };
    } catch (e) {
      // Si le service n'est pas encore prêt, réessayer après un délai
      Future.delayed(const Duration(milliseconds: 500), () {
        _setupLanguageListener();
      });
    }
}

  Future<void> _loadLocale() async {
    try {
      final languageService = await getIt.getAsync<LanguageService>();
      setState(() {
        _locale = languageService.getCurrentLocale();
      });
    } catch (e) {
      // Si le service n'est pas encore prêt, utiliser la locale par défaut
      _locale = const Locale('fr', '');
    }
  }

  void _setupThemeListener() async {
    // Écouter les changements de thème via le ThemeService
    try {
      final themeService = await getIt.getAsync<ThemeService>();
      themeService.onThemeChanged = (ThemeMode mode) {
        if (mounted) {
          setState(() {
            _themeMode = mode;
          });
        }
      };
    } catch (e) {
      // Si le service n'est pas encore prêt, réessayer après un délai
      Future.delayed(const Duration(milliseconds: 500), () {
        _setupThemeListener();
      });
    }
  }

  Future<void> _loadTheme() async {
    try {
      final themeService = await getIt.getAsync<ThemeService>();
      setState(() {
        _themeMode = themeService.getCurrentThemeMode();
      });
    } catch (e) {
      // Si le service n'est pas encore prêt, utiliser le thème par défaut
      _themeMode = ThemeMode.system;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Adapter SystemChrome selon le thème
    // `platformBrightnessOf` (et non `MediaQuery.of`) : l'application ne se
    // reconstruit plus à chaque image de l'animation du clavier ou du geste
    // retour — seulement quand la luminosité du système change.
    final isDark = _themeMode == ThemeMode.dark ||
        (_themeMode == ThemeMode.system &&
            MediaQuery.platformBrightnessOf(context) == Brightness.dark);
    
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
      // Barre de navigation transparente sur la bande peinte par
      // SystemBarsInset : boutons lisibles dans les deux thèmes.
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarIconBrightness:
          isDark ? Brightness.light : Brightness.dark,
      systemNavigationBarContrastEnforced: false,
    ));

    return MaterialApp.router(
      title: 'MangaTracker',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: _themeMode,
      locale: _locale,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('fr', ''),
        Locale('en', ''),
        Locale('de', ''),
        Locale('ja', ''),
        Locale('ko', ''),
        Locale('pt', ''),
        Locale('es', ''),
      ],
      routerConfig: _router,
      // Rien sous la barre de navigation du système (Android 15 bord à
      // bord, barre à boutons, indicateur d'accueil iOS) — sauf dans les
      // lecteurs, où la page occupe tout l'écran.
      builder: (context, child) => ListenableBuilder(
        listenable: _router.routerDelegate,
        builder: (context, _) => SystemBarsInset(
          enabled: !isFullscreenReaderRoute(
            _router.routerDelegate.currentConfiguration.lastOrNull?.route,
          ),
          child: child ?? const SizedBox.shrink(),
        ),
      ),
      scrollBehavior: _scrollBehavior,
    );
  }
}
