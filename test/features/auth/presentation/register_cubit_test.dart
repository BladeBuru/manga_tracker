import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:mangatracker/features/auth/exceptions/email_already_used.exception.dart';
import 'package:mangatracker/features/auth/presentation/cubit/auth_submission_status.dart';
import 'package:mangatracker/features/auth/presentation/cubit/register_cubit.dart';
import 'package:mangatracker/features/auth/presentation/cubit/register_state.dart';
import 'package:mangatracker/features/auth/services/auth.service.dart';
import 'package:mangatracker/features/profile/services/gdpr.service.dart';

class _MockAuthService extends Mock implements AuthService {}
class _MockGdprService extends Mock implements GdprService {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _MockAuthService authService;
  late _MockGdprService gdprService;
  late RegisterCubit cubit;

  setUp(() {
    authService = _MockAuthService();
    gdprService = _MockGdprService();
    // Stubs neutres : le cubit appelle ces méthodes après inscription
    // réussie. On veut juste que ça ne plante pas.
    when(() => gdprService.getConsentStatus())
        .thenAnswer((_) async => null);
    when(() => gdprService.recordConsent(
          tosVersion: any(named: 'tosVersion'),
          privacyVersion: any(named: 'privacyVersion'),
        )).thenAnswer((_) async => true);

    cubit = RegisterCubit(
      authService: authService,
      gdprService: gdprService,
    );
    // Les tests historiques supposent que l'utilisateur a accepté CGU/Privacy.
    // On valide le consentement côté UI avant submit.
    cubit.setAcceptedTos(true);
    cubit.setAcceptedPrivacy(true);
  });

  tearDown(() {
    cubit.close();
  });

  test('émet un état success après inscription réussie', () async {
    when(() => authService.attemptSignUp(any(), any(), any()))
        .thenAnswer((_) async {});
    when(() => authService.attemptLogIn(any(), any()))
        .thenAnswer((_) async => true);

    final emitted = <RegisterState>[];
    final sub = cubit.stream.listen(emitted.add);

    await cubit.submit(
      username: 'utilisateur',
      email: 'test@example.com',
      password: 'Motdepasse1!',
      l10n: null,
    );
    await Future<void>.delayed(Duration.zero);

    // emitted contient au moins loading puis success (potentiellement
    // d'autres états copyWith si setAcceptedTos/Privacy n'ont pas été
    // émis avant l'écoute — on filtre par status uniquement).
    final statuses = emitted.map((e) => e.status).toList();
    expect(statuses, contains(AuthSubmissionStatus.loading));
    expect(statuses.last, AuthSubmissionStatus.success);

    await sub.cancel();
  });

  test('émet un état failure lorsque l\'email est déjà utilisé', () async {
    when(() => authService.attemptSignUp(any(), any(), any()))
        .thenThrow(EmailAlreadyUsedException());

    final emitted = <RegisterState>[];
    final sub = cubit.stream.listen(emitted.add);

    await cubit.submit(
      username: 'utilisateur',
      email: 'test@example.com',
      password: 'Motdepasse1!',
      l10n: null,
    );
    await Future<void>.delayed(Duration.zero);

    final statuses = emitted.map((e) => e.status).toList();
    expect(statuses, contains(AuthSubmissionStatus.loading));
    expect(statuses.last, AuthSubmissionStatus.failure);
    expect(
      emitted.last.errorMessage,
      'Cette adresse e-mail est déjà utilisée',
    );

    await sub.cancel();
  });

  test(
      'refuse de soumettre si CGU/Privacy non cochés (consentement manquant)',
      () async {
    final freshCubit = RegisterCubit(
      authService: authService,
      gdprService: gdprService,
    );
    final emitted = <RegisterState>[];
    final sub = freshCubit.stream.listen(emitted.add);

    await freshCubit.submit(
      username: 'utilisateur',
      email: 'test@example.com',
      password: 'Motdepasse1!',
      l10n: null,
    );
    await Future<void>.delayed(Duration.zero);

    expect(emitted.last.status, AuthSubmissionStatus.failure);
    expect(emitted.last.errorMessage, contains('accepter'));
    verifyNever(() => authService.attemptSignUp(any(), any(), any()));

    await sub.cancel();
    await freshCubit.close();
  });
}
