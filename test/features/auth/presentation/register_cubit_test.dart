import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:mangatracker/features/auth/exceptions/email_already_used.exception.dart';
import 'package:mangatracker/features/auth/presentation/cubit/auth_submission_status.dart';
import 'package:mangatracker/features/auth/presentation/cubit/register_cubit.dart';
import 'package:mangatracker/features/auth/presentation/cubit/register_state.dart';
import 'package:mangatracker/features/auth/services/auth.service.dart';

class _MockAuthService extends Mock implements AuthService {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _MockAuthService authService;
  late RegisterCubit cubit;

  setUp(() {
    authService = _MockAuthService();
    cubit = RegisterCubit(authService: authService);
  });

  tearDown(() {
    cubit.close();
  });

  test('émet un état success après inscription réussie', () async {
    when(() => authService.attemptSignUp(any(), any(), any()))
        .thenAnswer((_) async {});

    final emitted = <RegisterState>[];
    final sub = cubit.stream.listen(emitted.add);

    await cubit.submit(
      username: 'utilisateur',
      email: 'test@example.com',
      password: 'Motdepasse1!',
      l10n: null,
    );
    await Future<void>.delayed(Duration.zero);

    expect(emitted.length, 2);
    expect(emitted.first.status, AuthSubmissionStatus.loading);
    expect(emitted.last.status, AuthSubmissionStatus.success);

    await sub.cancel();
  });

  test('émet un état failure lorsque l’email est déjà utilisé', () async {
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

    expect(emitted.length, 2);
    expect(emitted.first.status, AuthSubmissionStatus.loading);
    expect(emitted.last.status, AuthSubmissionStatus.failure);
    expect(
      emitted.last.errorMessage,
      'Cette adresse e-mail est déjà utilisée',
    );

    await sub.cancel();
  });
}
