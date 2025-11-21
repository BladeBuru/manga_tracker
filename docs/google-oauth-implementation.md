# Guide d'implémentation : Connexion Google OAuth

Ce guide détaille l'implémentation complète de la connexion via Google OAuth pour l'application Manga Tracker, côté frontend (Flutter) et backend (NestJS/Node.js).

## Vue d'ensemble

L'authentification Google OAuth permet aux utilisateurs de se connecter à l'application en utilisant leur compte Google, sans avoir à créer un compte spécifique. Le flow suit le standard OAuth 2.0.

## Architecture

```
Flutter App → Google Sign-In SDK → Google OAuth Server
                ↓
         Token ID reçu
                ↓
         Backend API (/auth/google)
                ↓
         Vérification du token avec Google
                ↓
         Création/Connexion du compte
                ↓
         Génération des tokens JWT
                ↓
         Retour à l'application
```

---

## Partie 1 : Frontend (Flutter)

### 1.1 Installation du package

Ajoutez le package `google_sign_in` dans `pubspec.yaml` :

```yaml
dependencies:
  google_sign_in: ^6.2.1
```

Puis exécutez :
```bash
flutter pub get
```

### 1.2 Configuration Android

#### Étape 1 : Créer un projet Google Cloud

1. Allez sur [Google Cloud Console](https://console.cloud.google.com/)
2. Créez un nouveau projet ou sélectionnez un projet existant
3. Activez l'API "Google Sign-In" pour votre projet

#### Étape 2 : Créer les OAuth 2.0 Client IDs

1. Allez dans **APIs & Services** → **Credentials**
2. Cliquez sur **Create Credentials** → **OAuth client ID**
3. Configurez l'écran de consentement OAuth si nécessaire
4. Créez un Client ID pour **Android** :
   - **Application type** : Android
   - **Package name** : Votre package name (ex: `com.example.manga_tracker`)
   - **SHA-1 certificate fingerprint** : Obtenez-le avec :
     ```bash
     keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android
     ```
5. Créez un Client ID pour **Web** (nécessaire pour le backend) :
   - **Application type** : Web application
   - **Authorized redirect URIs** : `http://localhost:3000/auth/google/callback` (ou votre URL backend)

#### Étape 3 : Configuration dans Flutter (Android)

Le package `google_sign_in` utilise automatiquement le SHA-1 de votre keystore. Pour la production, vous devrez ajouter le SHA-1 de votre keystore de production.

Aucune configuration supplémentaire n'est nécessaire dans le code Android.

### 1.3 Configuration iOS

#### Étape 1 : Créer un OAuth 2.0 Client ID pour iOS

1. Dans Google Cloud Console, créez un Client ID pour **iOS** :
   - **Application type** : iOS
   - **Bundle ID** : Votre bundle ID (ex: `com.example.mangaTracker`)

#### Étape 2 : Télécharger GoogleService-Info.plist

1. Téléchargez le fichier `GoogleService-Info.plist` depuis Google Cloud Console
2. Ajoutez-le dans `ios/Runner/GoogleService-Info.plist`
3. Ajoutez-le au projet Xcode (glisser-déposer dans Xcode)

#### Étape 3 : Configuration dans Xcode

1. Ouvrez `ios/Runner.xcworkspace` dans Xcode
2. Vérifiez que `GoogleService-Info.plist` est ajouté au target "Runner"
3. Assurez-vous que l'URL scheme est configurée dans `Info.plist` (généralement fait automatiquement)

### 1.4 Configuration Web

#### Étape 1 : Créer un OAuth 2.0 Client ID pour Web

1. Dans Google Cloud Console, créez un Client ID pour **Web application**
2. Notez le **Client ID** et le **Client Secret**

#### Étape 2 : Configuration dans Flutter Web

Le package `google_sign_in` nécessite une configuration spécifique pour le web. Vous devrez passer le Client ID lors de l'initialisation.

### 1.5 Implémentation du service Google Sign-In

Créez un nouveau service : `lib/features/auth/services/google_auth.service.dart`

```dart
import 'package:google_sign_in/google_sign_in.dart';
import 'package:mangatracker/core/service_locator/service_locator.dart';
import 'package:mangatracker/core/network/http_service.dart';
import 'package:mangatracker/core/notifier/notifier.dart';

class GoogleAuthService {
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
    // Pour le web, ajoutez :
    // clientId: 'YOUR_WEB_CLIENT_ID.apps.googleusercontent.com',
  );
  final HttpService _httpService = getIt<HttpService>();
  final Notifier _notifier = getIt<Notifier>();

  /// Lance le processus de connexion Google
  Future<Map<String, dynamic>?> signInWithGoogle() async {
    try {
      // Déconnecter d'une session précédente si nécessaire
      await _googleSignIn.signOut();
      
      // Lancer la connexion Google
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      
      if (googleUser == null) {
        // L'utilisateur a annulé la connexion
        return null;
      }

      // Obtenir les détails d'authentification
      final GoogleSignInAuthentication googleAuth = 
          await googleUser.authentication;

      // Envoyer le token ID au backend
      final response = await _httpService.postWithAuthTokens(
        '/auth/google',
        body: {
          'idToken': googleAuth.idToken,
          'accessToken': googleAuth.accessToken,
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = response.data;
        return {
          'accessToken': data['accessToken'],
          'refreshToken': data['refreshToken'],
          'user': data['user'],
        };
      } else {
        _notifier.error('Erreur lors de la connexion Google');
        return null;
      }
    } catch (e) {
      _notifier.error('Erreur lors de la connexion Google: $e');
      return null;
    }
  }

  /// Déconnecte l'utilisateur de Google
  Future<void> signOut() async {
    await _googleSignIn.signOut();
  }
}
```

### 1.6 Enregistrement du service

Dans `lib/core/service_locator/service_locator.dart` :

```dart
import '../../features/auth/services/google_auth.service.dart';

// Dans setupServiceLocator() :
getIt.registerLazySingleton<GoogleAuthService>(() => GoogleAuthService());
```

### 1.7 Intégration dans les pages Login/Register

Dans `lib/features/auth/views/login.view.dart` et `register.view.dart`, modifiez les `SquareTile` pour Google :

```dart
SquareTile(
  imagePath: 'assets/images/google_logo.png',
  onTap: () async {
    final googleAuthService = getIt<GoogleAuthService>();
    final result = await googleAuthService.signInWithGoogle();
    
    if (result != null && mounted) {
      // Sauvegarder les tokens
      final storageService = getIt<StorageService>();
      await storageService.writeSecureData('accessToken', result['accessToken']);
      await storageService.writeSecureData('refreshToken', result['refreshToken']);
      
      // Naviguer vers l'application
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const BottomNavbar()),
      );
    }
  },
),
```

---

## Partie 2 : Backend (NestJS/Node.js)

### 2.1 Installation des dépendances

```bash
npm install @nestjs/passport passport passport-google-oauth20
npm install --save-dev @types/passport-google-oauth20
```

### 2.2 Configuration des variables d'environnement

Dans votre fichier `.env` :

```env
GOOGLE_CLIENT_ID=your_web_client_id.apps.googleusercontent.com
GOOGLE_CLIENT_SECRET=your_client_secret
GOOGLE_CALLBACK_URL=http://localhost:3000/auth/google/callback
```

### 2.3 Création de la stratégie Google OAuth

Créez `src/auth/strategies/google.strategy.ts` :

```typescript
import { Injectable } from '@nestjs/common';
import { PassportStrategy } from '@nestjs/passport';
import { Strategy, VerifyCallback } from 'passport-google-oauth20';
import { ConfigService } from '@nestjs/config';

@Injectable()
export class GoogleStrategy extends PassportStrategy(Strategy, 'google') {
  constructor(private configService: ConfigService) {
    super({
      clientID: configService.get<string>('GOOGLE_CLIENT_ID'),
      clientSecret: configService.get<string>('GOOGLE_CLIENT_SECRET'),
      callbackURL: configService.get<string>('GOOGLE_CALLBACK_URL'),
      scope: ['email', 'profile'],
    });
  }

  async validate(
    accessToken: string,
    refreshToken: string,
    profile: any,
    done: VerifyCallback,
  ): Promise<any> {
    const { name, emails, photos } = profile;
    const user = {
      email: emails[0].value,
      firstName: name.givenName,
      lastName: name.familyName,
      picture: photos[0].value,
      accessToken,
    };
    done(null, user);
  }
}
```

### 2.4 Création du contrôleur d'authentification Google

Créez ou modifiez `src/auth/auth.controller.ts` :

```typescript
import { Controller, Post, Body, UseGuards, Req } from '@nestjs/common';
import { AuthGuard } from '@nestjs/passport';
import { AuthService } from './auth.service';
import { GoogleAuthService } from './google-auth.service';

@Controller('auth')
export class AuthController {
  constructor(
    private readonly authService: AuthService,
    private readonly googleAuthService: GoogleAuthService,
  ) {}

  @Post('google')
  async googleAuth(@Body() body: { idToken: string; accessToken: string }) {
    // Vérifier le token ID avec Google
    const googleUser = await this.googleAuthService.verifyToken(
      body.idToken,
    );

    if (!googleUser) {
      throw new UnauthorizedException('Token Google invalide');
    }

    // Chercher ou créer l'utilisateur
    let user = await this.userService.findByEmail(googleUser.email);

    if (!user) {
      // Créer un nouvel utilisateur
      user = await this.userService.create({
        email: googleUser.email,
        name: googleUser.name,
        picture: googleUser.picture,
        provider: 'google',
        providerId: googleUser.sub,
      });
    } else if (user.provider !== 'google') {
      // L'utilisateur existe mais avec un autre provider
      // Option 1 : Lier les comptes
      // Option 2 : Refuser la connexion
      throw new ConflictException(
        'Un compte existe déjà avec cet email. Connectez-vous avec votre méthode habituelle.',
      );
    }

    // Générer les tokens JWT
    const tokens = await this.authService.generateTokens(user);

    return {
      accessToken: tokens.accessToken,
      refreshToken: tokens.refreshToken,
      user: {
        id: user.id,
        email: user.email,
        name: user.name,
        picture: user.picture,
      },
    };
  }
}
```

### 2.5 Service de vérification Google

Créez `src/auth/google-auth.service.ts` :

```typescript
import { Injectable, UnauthorizedException } from '@nestjs/common';
import { OAuth2Client } from 'google-auth-library';
import { ConfigService } from '@nestjs/config';

@Injectable()
export class GoogleAuthService {
  private client: OAuth2Client;

  constructor(private configService: ConfigService) {
    this.client = new OAuth2Client(
      configService.get<string>('GOOGLE_CLIENT_ID'),
    );
  }

  async verifyToken(idToken: string) {
    try {
      const ticket = await this.client.verifyIdToken({
        idToken,
        audience: this.configService.get<string>('GOOGLE_CLIENT_ID'),
      });

      const payload = ticket.getPayload();
      return {
        sub: payload.sub,
        email: payload.email,
        name: payload.name,
        picture: payload.picture,
        emailVerified: payload.email_verified,
      };
    } catch (error) {
      throw new UnauthorizedException('Token Google invalide');
    }
  }
}
```

### 2.6 Mise à jour du module Auth

Dans `src/auth/auth.module.ts` :

```typescript
import { Module } from '@nestjs/common';
import { PassportModule } from '@nestjs/passport';
import { GoogleStrategy } from './strategies/google.strategy';
import { GoogleAuthService } from './google-auth.service';

@Module({
  imports: [PassportModule],
  providers: [GoogleStrategy, GoogleAuthService],
  exports: [GoogleAuthService],
})
export class AuthModule {}
```

### 2.7 Mise à jour du schéma de base de données

Ajoutez les champs nécessaires dans votre modèle User :

```typescript
// user.entity.ts ou user.schema.ts
{
  // ... champs existants
  provider: {
    type: String,
    enum: ['local', 'google', 'apple'],
    default: 'local',
  },
  providerId: {
    type: String,
    nullable: true,
  },
  picture: {
    type: String,
    nullable: true,
  },
}
```

---

## Gestion des erreurs

### Erreurs courantes

1. **Token invalide** : Vérifiez que le Client ID correspond entre Flutter et le backend
2. **SHA-1 mismatch** : Assurez-vous que le SHA-1 dans Google Cloud Console correspond à votre keystore
3. **Redirect URI mismatch** : Vérifiez que l'URI de callback correspond exactement

### Messages d'erreur à gérer

- Utilisateur annule la connexion
- Token expiré
- Compte existant avec un autre provider
- Erreur réseau

---

## Sécurité

1. **Toujours vérifier le token côté backend** : Ne jamais faire confiance au token côté client
2. **Utiliser HTTPS en production** : Les tokens doivent être transmis via HTTPS uniquement
3. **Valider l'email** : Vérifier que l'email est vérifié par Google si nécessaire
4. **Gérer les conflits de compte** : Décider de la stratégie si un email existe déjà avec un autre provider

---

## Tests

### Tests frontend

```dart
// test/features/auth/services/google_auth_service_test.dart
void main() {
  test('signInWithGoogle should return tokens on success', () async {
    // Mock Google Sign-In
    // Test du flow complet
  });
}
```

### Tests backend

```typescript
// auth.controller.spec.ts
describe('AuthController', () => {
  it('should authenticate user with Google token', async () => {
    // Mock Google token verification
    // Test de la création/connexion
  });
});
```

---

## Ressources

- [Google Sign-In Documentation](https://developers.google.com/identity/sign-in/web/sign-in)
- [google_sign_in Flutter Package](https://pub.dev/packages/google_sign_in)
- [NestJS Passport Documentation](https://docs.nestjs.com/recipes/passport)
- [Google OAuth 2.0](https://developers.google.com/identity/protocols/oauth2)

