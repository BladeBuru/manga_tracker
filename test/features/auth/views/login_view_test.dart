import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:mangatracker/core/components/auth_button.dart';
import 'package:mangatracker/core/notifier/notifier.dart';
import 'package:mangatracker/core/service_locator/service_locator.dart';
import 'package:mangatracker/core/services/language_service.dart';
import 'package:mangatracker/features/auth/exceptions/invalid_credentials.exception.dart';
import 'package:mangatracker/features/auth/services/auth.service.dart';
import 'package:mangatracker/features/auth/services/biometric.service.dart';
import 'package:mangatracker/features/auth/services/validator.service.dart';
import 'package:mangatracker/features/auth/views/login.view.dart';
import 'package:mangatracker/l10n/app_localizations.dart';
import 'package:mangatracker/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _MockAuthService extends Mock implements AuthService {}

class _MockBiometricService extends Mock implements BiometricService {}

class _SilentNotifier extends Notifier {
  @override
  void show({required String message, NotifierType type = NotifierType.info}) {}
}

class _FakeRoute extends Fake implements Route<dynamic> {}

Future<void> _registerLoginDependencies({
  required _MockAuthService authService,
  required _MockBiometricService biometricService,
}) async {
  await getIt.reset();

  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();

  when(() => authService.biometricService).thenReturn(biometricService);
  when(() => authService.hasBiometricPreference())
      .thenAnswer((_) async => true);
  when(() => authService.isBiometricEnabled())
      .thenAnswer((_) async => false);
  when(() => biometricService.hasBiometricSupport())
      .thenAnswer((_) async => false);
  when(() => authService.setBiometricEnabled(any(), email: any(named: 'email'), password: any(named: 'password')))
      .thenAnswer((_) async {});
  when(() => authService.setBiometricEnabled(false))
      .thenAnswer((_) async {});

  getIt.registerSingleton<AuthService>(authService);
  getIt.registerSingleton<ValidatorService>(ValidatorService());
  getIt.registerSingleton<BiometricService>(biometricService);
  getIt.registerSingleton<LanguageService>(LanguageService(prefs));
  getIt.registerSingleton<Notifier>(_SilentNotifier());
}

Future<void> _pumpLoginView(WidgetTester tester,
    {NavigatorObserver? observer}) async {
  final view = tester.view;
  view.devicePixelRatio = 1.0;
  view.physicalSize = const Size(1200, 2200);
  addTearDown(() {
    view.resetPhysicalSize();
    view.resetDevicePixelRatio();
  });

  await tester.pumpWidget(
    MaterialApp(
      navigatorKey: navigatorKey,
      locale: const Locale('en'),
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: const LoginView(),
      navigatorObservers: observer != null ? [observer] : const [],
      builder: (context, child) {
        final data = MediaQuery.of(context)
            .copyWith(textScaler: const TextScaler.linear(0.9));
        return MediaQuery(data: data, child: child!);
      },
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() {
    registerFallbackValue(_FakeRoute());
  });

  tearDown(() async {
    await getIt.reset();
  });

  testWidgets('affiche un message de validation lorsque l\'email est vide',
      (tester) async {
    final authService = _MockAuthService();
    final biometricService = _MockBiometricService();
    await _registerLoginDependencies(
      authService: authService,
      biometricService: biometricService,
    );

    await _pumpLoginView(tester);

    await tester.tap(find.byType(AuthButton));
    await tester.pump();

    expect(find.text('Please enter your email address'), findsOneWidget);
  });

  testWidgets('affiche l\'erreur renvoyée par le service d\'authentification',
      (tester) async {
    final authService = _MockAuthService();
    final biometricService = _MockBiometricService();
    await _registerLoginDependencies(
      authService: authService,
      biometricService: biometricService,
    );

    when(() => authService.attemptLogIn(any(), any()))
        .thenThrow(InvalidCredentialsException(''));

    await _pumpLoginView(tester);

    final emailField = find.byType(TextFormField).at(0);
    final passwordField = find.byType(TextFormField).at(1);

    await tester.ensureVisible(emailField);
    await tester.enterText(emailField, 'test@example.com');
    await tester.ensureVisible(passwordField);
    await tester.enterText(passwordField, 'motdepasse1!');

    await tester.tap(find.byType(AuthButton));
    await tester.pump();

    expect(find.text('Invalid credentials'), findsOneWidget);
  });
}
