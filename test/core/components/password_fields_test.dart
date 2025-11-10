import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mangatracker/features/auth/services/validator.service.dart';
import 'package:mangatracker/core/components/password_fields.dart';
import 'package:mangatracker/l10n/app_localizations.dart';

Future<void> _pumpPasswordFields(WidgetTester tester,
    TextEditingController passwordController,
    TextEditingController confirmController) async {
  final view = tester.view;
  view.devicePixelRatio = 1.0;
  view.physicalSize = const Size(800, 1200);
  addTearDown(() {
    view.resetPhysicalSize();
    view.resetDevicePixelRatio();
  });

  await tester.pumpWidget(
    MaterialApp(
      locale: const Locale('fr'),
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: PasswordFields(
          passwordControler: passwordController,
          confirmPasswordControler: confirmController,
          validatorService: ValidatorService(),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('affiche l\'indicateur de robustesse du mot de passe',
      (tester) async {
    final passwordController = TextEditingController();
    final confirmController = TextEditingController();

    await _pumpPasswordFields(tester, passwordController, confirmController);

    await tester.enterText(
        find.widgetWithText(TextFormField, 'Mot de passe'), 'abc');
    await tester.pump();

    expect(find.text('Faible'), findsOneWidget);

    await tester.enterText(
        find.widgetWithText(TextFormField, 'Mot de passe'),
        'Motdepasse1!');
    await tester.pump();

    expect(find.text('Fort'), findsOneWidget);
    expect(find.byType(LinearProgressIndicator), findsOneWidget);
  });

  testWidgets('permet d\'afficher le mot de passe via l\'icône dédiée',
      (tester) async {
    final passwordController = TextEditingController();
    final confirmController = TextEditingController();

    await _pumpPasswordFields(tester, passwordController, confirmController);

    final passwordFieldFinder =
        find.widgetWithText(TextFormField, 'Mot de passe');

    EditableText editable = tester.widget(
      find.descendant(
        of: passwordFieldFinder,
        matching: find.byType(EditableText),
      ),
    );
    expect(editable.obscureText, isTrue);

    await tester.tap(
      find.descendant(
        of: passwordFieldFinder,
        matching: find.byIcon(Icons.visibility_outlined),
      ),
    );
    await tester.pump();

    editable = tester.widget(
      find.descendant(
        of: passwordFieldFinder,
        matching: find.byType(EditableText),
      ),
    );
    expect(editable.obscureText, isFalse);
  });
}
