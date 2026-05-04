import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:mangatracker/features/auth/exceptions/invalid_credentials.exception.dart';
import 'package:mangatracker/features/auth/presentation/cubit/auth_submission_status.dart';
import 'package:mangatracker/features/auth/presentation/cubit/login_cubit.dart';
import 'package:mangatracker/features/auth/presentation/cubit/login_state.dart';
import 'package:mangatracker/features/auth/services/auth.service.dart';
import 'package:mangatracker/features/auth/services/biometric.service.dart';

class _MockAuthService extends Mock implements AuthService {}

class _MockBiometricService extends Mock implements BiometricService {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _MockAuthService authService;
  late _MockBiometricService biometricService;
  late LoginCubit cubit;

  setUp(() {
    authService = _MockAuthService();
    biometricService = _MockBiometricService();
    when(() => authService.biometricService).thenReturn(biometricService);
    cubit = LoginCubit(authService: authService);
  });

  tearDown(() {
    cubit.close();
  });

  test('émet un état failure lorsque la connexion échoue', () async {
    when(() => authService.attemptLogIn(any(), any()))
        .thenThrow(InvalidCredentialsException(''));

    final emitted = <LoginState>[];
    final sub = cubit.stream.listen(emitted.add);

    await cubit.submit('test@example.com', 'motdepasse', null);
    await Future<void>.delayed(Duration.zero);

    expect(emitted.length, 2);
    expect(emitted.first.status, AuthSubmissionStatus.loading);
    expect(emitted.last.status, AuthSubmissionStatus.failure);
    expect(emitted.last.errorMessage, 'Identifiants invalides');

    await sub.cancel();
  });

  test('demande l’activation biométrique lorsque aucune préférence n’est définie',
      () async {
    when(() => authService.attemptLogIn(any(), any()))
        .thenAnswer((_) async => {});
    when(() => authService.hasBiometricPreference())
        .thenAnswer((_) async => false);
    when(() => biometricService.hasBiometricSupport())
        .thenAnswer((_) async => true);
    when(() => authService.setBiometricEnabled(true,
            email: any(named: 'email'), password: any(named: 'password')))
        .thenAnswer((_) async {});
    when(() => authService.setBiometricEnabled(false))
        .thenAnswer((_) async {});

    await cubit.submit('test@example.com', 'motdepasse', null);
    await Future<void>.delayed(Duration.zero);

    expect(cubit.state.status, AuthSubmissionStatus.success);
    expect(cubit.state.requiresBiometricPrompt, isTrue);
    expect(cubit.state.pendingEmail, 'test@example.com');

    await cubit.completeBiometricPrompt(true);

    verify(() => authService.setBiometricEnabled(true,
        email: 'test@example.com', password: 'motdepasse')).called(1);
    expect(cubit.state.requiresBiometricPrompt, isFalse);
  });
}
