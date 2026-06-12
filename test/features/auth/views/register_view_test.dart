import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:mangatracker/features/auth/widgets/auth_submit_button.dart';
import 'package:mangatracker/core/notifier/notifier.dart';
import 'package:mangatracker/core/service_locator/service_locator.dart';
import 'package:mangatracker/core/services/language_service.dart';
import 'package:mangatracker/features/auth/exceptions/email_already_used.exception.dart';
import 'package:mangatracker/features/auth/services/auth.service.dart';
import 'package:mangatracker/features/auth/services/biometric.service.dart';
import 'package:mangatracker/features/auth/services/validator.service.dart';
import 'package:mangatracker/features/auth/views/register.view.dart';
import 'package:mangatracker/features/profile/services/gdpr.service.dart';
import 'package:mangatracker/l10n/app_localizations.dart';
import 'package:mangatracker/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _MockAuthService extends Mock implements AuthService {}

class _MockBiometricService extends Mock implements BiometricService {}

class _MockGdprService extends Mock implements GdprService {}

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
  // Le RegisterCubit exige un GdprService (consentement CGU/Privacy).
  getIt.registerSingleton<GdprService>(_MockGdprService());
}

Future<void> _pumpRegisterView(WidgetTester tester) async {
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

    // Le flow RGPD exige les 2 consentements cochés AVANT que le bouton
    // déclenche la validation du formulaire (sinon → snackbar consent).
    await _acceptConsents(tester);

    await tester.ensureVisible(find.byType(AuthSubmitButton));
    await tester.tap(find.byType(AuthSubmitButton));
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

    // Ordre V1 « Refined Classic » : username(0), email(1), password(2),
    // confirm(3) — l'ancien design avait l'email en premier.
    final usernameField = find.byType(TextFormField).at(0);
    final emailField = find.byType(TextFormField).at(1);
    final passwordField = find.byType(TextFormField).at(2);
    final confirmField = find.byType(TextFormField).at(3);

    await tester.ensureVisible(usernameField);
    await tester.enterText(usernameField, 'utilisateur');
    await tester.ensureVisible(emailField);
    await tester.enterText(emailField, 'test@example.com');
    await tester.ensureVisible(passwordField);
    await tester.enterText(passwordField, 'Motdepasse1!');
    await tester.ensureVisible(confirmField);
    await tester.enterText(confirmField, 'Motdepasse1!');

    await _acceptConsents(tester);

    await tester.ensureVisible(find.byType(AuthSubmitButton));
    await tester.tap(find.byType(AuthSubmitButton));
    await tester.pumpAndSettle();

    expect(find.text('Cette adresse e-mail est déjà utilisée'), findsOneWidget);
  });
}

/// Coche les 2 cases de consentement RGPD (CGU + Politique de
/// confidentialité) — prérequis pour que le submit déclenche la validation.
Future<void> _acceptConsents(WidgetTester tester) async {
  final checkboxes = find.byType(Checkbox);
  expect(checkboxes, findsNWidgets(2));
  for (var i = 0; i < 2; i++) {
    await tester.ensureVisible(checkboxes.at(i));
    await tester.tap(checkboxes.at(i));
    await tester.pump();
  }
}
