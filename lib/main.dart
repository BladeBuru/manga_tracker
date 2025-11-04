import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:mangatracker/core/service_locator/service_locator.dart';
import 'package:mangatracker/core/services/language_service.dart';
import 'package:mangatracker/features/auth/views/startup_page.dart';
import 'package:mangatracker/l10n/app_localizations.dart';

import 'core/theme/app_theme.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
Future<void> main() async {
  // S'assure que les plugins de plateforme sont initialisés avant toute opération async
  WidgetsFlutterBinding.ensureInitialized();
  //
  if (kReleaseMode) {
    await dotenv.load(fileName: "assets/env/.env.production");
    print('ENV loaded: ${dotenv.env}');
  } else {

    await dotenv.load(fileName: "assets/env/.env.development");
    print('ENV loaded: ${dotenv.env}');
  }

  // Register all services
  setupServiceLocator();
  await getIt.allReady();

  runApp(const MyApp());
}

const Color themePage = Color(0xffe0234f);

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  Locale _locale = const Locale('fr', '');

  @override
  void initState() {
    super.initState();
    _loadLocale();
    // Écouter les changements de langue via un callback global
    _setupLanguageListener();
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

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark));

    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

    return MaterialApp(
      title: 'MangaTracker',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      // darkTheme: AppTheme.dark,
      // themeMode: ThemeMode.system,
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
      home: const StartupPage(),
      scrollBehavior: ScrollConfiguration.of(context).copyWith(
        physics: const BouncingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        ),
      ),
      navigatorKey: navigatorKey,
    );
  }
}
