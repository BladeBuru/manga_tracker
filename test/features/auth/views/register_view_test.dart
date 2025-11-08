import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:mangatracker/core/components/auth_button.dart';
import 'package:mangatracker/core/notifier/notifier.dart';
import 'package:mangatracker/core/service_locator/service_locator.dart';
import 'package:mangatracker/core/services/language_service.dart';
import 'package:mangatracker/features/auth/exceptions/email_already_used.exception.dart';
import 'package:mangatracker/features/auth/services/auth.service.dart';
import 'package:mangatracker/features/auth/services/biometric.service.dart';
import 'package:mangatracker/features/auth/services/validator.service.dart';
import 'package:mangatracker/features/auth/views/login.view.dart';
import 'package:mangatracker/features/auth/views/register.view.dart';
import 'package:mangatracker/l10n/app_localizations.dart';
import 'package:mangatracker/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _MockAuthService extends Mock implements AuthService {}

class _MockBiometricService extends Mock implements BiometricService {}

class _SilentNotifier extends Notifier {
  @override
  void show({required String message, NotifierType type = NotifierType.info}) {}
}

Future<void> _registerRegisterDependencies({
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

Future<void> _pumpRegisterView(WidgetTester tester) async {
  final binding = TestWidgetsFlutterBinding.ensureInitialized()
      as TestWidgetsFlutterBinding;
  binding.window.devicePixelRatioTestValue = 1.0;
  binding.window.physicalSizeTestValue = const Size(1200, 2200);
  addTearDown(() {
    binding.window.clearPhysicalSizeTestValue();
    binding.window.clearDevicePixelRatioTestValue();
  });

  await tester.pumpWidget(
    MaterialApp(
      navigatorKey: navigatorKey,
      locale: const Locale('fr'),
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: const RegisterView(emailText: ''),
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

  tearDown(() async {
    await getIt.reset();
  });

  testWidgets('affiche une erreur lorsque le champ email est vide',
      (tester) async {
    final authService = _MockAuthService();
    final biometricService = _MockBiometricService();
    await _registerRegisterDependencies(
      authService: authService,
      biometricService: biometricService,
    );

    await _pumpRegisterView(tester);

    await tester.ensureVisible(find.byType(AuthButton));
    await tester.tap(find.byType(AuthButton));
    await tester.pumpAndSettle();

    expect(find.text('Veuillez entrer votre adresse e-mail'), findsOneWidget);
    verifyNever(() => authService.attemptSignUp(any(), any(), any()));
  });

  testWidgets('affiche un message lorsque l\'email est déjà utilisé',
      (tester) async {
    final authService = _MockAuthService();
    final biometricService = _MockBiometricService();
    await _registerRegisterDependencies(
      authService: authService,
      biometricService: biometricService,
    );

    when(() => authService.attemptSignUp(any(), any(), any()))
        .thenThrow(EmailAlreadyUsedException());

    await _pumpRegisterView(tester);

    final emailField = find.byType(TextFormField).at(0);
    final usernameField = find.byType(TextFormField).at(1);
    final passwordField = find.byType(TextFormField).at(2);
    final confirmField = find.byType(TextFormField).at(3);

    await tester.ensureVisible(emailField);
    await tester.enterText(emailField, 'test@example.com');
    await tester.ensureVisible(usernameField);
    await tester.enterText(usernameField, 'utilisateur');
    await tester.ensureVisible(passwordField);
    await tester.enterText(passwordField, 'Motdepasse1!');
    await tester.ensureVisible(confirmField);
    await tester.enterText(confirmField, 'Motdepasse1!');

    await tester.ensureVisible(find.byType(AuthButton));
    await tester.tap(find.byType(AuthButton));
    await tester.pumpAndSettle();

    expect(find.text('Cette adresse e-mail est déjà utilisée'), findsOneWidget);
  });
}
