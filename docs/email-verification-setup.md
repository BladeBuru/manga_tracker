# Guide de configuration : Validation d'email

Ce guide détaille les différentes options pour implémenter la validation d'email dans l'application Manga Tracker, incluant la configuration avec poste.io et les alternatives avec des services externes.

## Vue d'ensemble

La validation d'email permet de :
- Vérifier que l'adresse email fournie est valide et appartient à l'utilisateur
- Réduire les comptes frauduleux
- Améliorer la sécurité et la qualité des données utilisateur

## Architecture

```
Utilisateur s'inscrit
    ↓
Backend génère un token de vérification
    ↓
Backend envoie un email avec un lien de vérification
    ↓
Utilisateur clique sur le lien
    ↓
Backend vérifie le token et marque l'email comme vérifié
```

---

## Option 1 : Configuration avec poste.io

### 1.1 Vérification de la disponibilité SMTP

Poste.io est principalement un serveur de messagerie pour recevoir des emails, mais il peut aussi envoyer des emails via SMTP si configuré correctement.

**Limitations possibles** :
- Poste.io peut ne pas être configuré pour l'envoi SMTP sortant
- Peut nécessiter une configuration DNS supplémentaire (SPF, DKIM, DMARC)
- Risque que les emails soient marqués comme spam

### 1.2 Configuration SMTP dans poste.io

1. **Accéder à l'interface d'administration poste.io**
2. **Créer un compte email dédié** pour l'application (ex: `noreply@votre-domaine.com`)
3. **Configurer les paramètres SMTP** :
   - Serveur SMTP : `smtp.votre-domaine.com` (ou l'IP de votre serveur)
   - Port : `587` (TLS) ou `465` (SSL)
   - Authentification : Utilisateur et mot de passe du compte créé

### 1.3 Configuration DNS (Recommandé)

Pour améliorer la délivrabilité :

1. **SPF Record** :
   ```
   v=spf1 mx ip4:VOTRE_IP ~all
   ```

2. **DKIM** : Générer une clé DKIM dans poste.io et l'ajouter au DNS

3. **DMARC** :
   ```
   v=DMARC1; p=quarantine; rua=mailto:admin@votre-domaine.com
   ```

### 1.4 Configuration backend

Si poste.io est configuré pour l'envoi SMTP, utilisez la configuration suivante :

```typescript
// .env
SMTP_HOST=smtp.votre-domaine.com
SMTP_PORT=587
SMTP_SECURE=false // true pour SSL (port 465)
SMTP_USER=noreply@votre-domaine.com
SMTP_PASS=votre_mot_de_passe
SMTP_FROM=noreply@votre-domaine.com
SMTP_FROM_NAME=Manga Tracker
```

---

## Option 2 : Services externes (Recommandé)

### 2.1 SendGrid (Gratuit jusqu'à 100 emails/jour)

#### Avantages
- Gratuit jusqu'à 100 emails/jour
- Excellente délivrabilité
- API simple et bien documentée
- Templates d'emails

#### Configuration

1. **Créer un compte** sur [SendGrid](https://sendgrid.com/)

2. **Créer une API Key** :
   - Allez dans **Settings** → **API Keys**
   - Créez une nouvelle clé avec les permissions "Mail Send"

3. **Installer le package** :
   ```bash
   npm install @sendgrid/mail
   ```

4. **Configuration backend** :
   ```typescript
   // .env
   SENDGRID_API_KEY=SG.votre_cle_api
   EMAIL_FROM=noreply@votre-domaine.com
   EMAIL_FROM_NAME=Manga Tracker
   ```

5. **Service d'envoi d'email** :
   ```typescript
   // src/common/services/email.service.ts
   import * as sgMail from '@sendgrid/mail';

   @Injectable()
   export class EmailService {
     constructor(private configService: ConfigService) {
       sgMail.setApiKey(this.configService.get<string>('SENDGRID_API_KEY'));
     }

     async sendVerificationEmail(
       email: string,
       token: string,
       name: string,
     ): Promise<void> {
       const verificationUrl = `${this.configService.get<string>('FRONTEND_URL')}/verify-email?token=${token}`;
       
       const msg = {
         to: email,
         from: {
           email: this.configService.get<string>('EMAIL_FROM'),
           name: this.configService.get<string>('EMAIL_FROM_NAME'),
         },
         subject: 'Vérifiez votre adresse email - Manga Tracker',
         html: `
           <h1>Bonjour ${name},</h1>
           <p>Merci de vous être inscrit sur Manga Tracker !</p>
           <p>Veuillez cliquer sur le lien ci-dessous pour vérifier votre adresse email :</p>
           <a href="${verificationUrl}">Vérifier mon email</a>
           <p>Ce lien expirera dans 24 heures.</p>
           <p>Si vous n'avez pas créé de compte, ignorez cet email.</p>
         `,
         text: `
           Bonjour ${name},
           
           Merci de vous être inscrit sur Manga Tracker !
           
           Veuillez cliquer sur le lien suivant pour vérifier votre adresse email :
           ${verificationUrl}
           
           Ce lien expirera dans 24 heures.
           
           Si vous n'avez pas créé de compte, ignorez cet email.
         `,
       };

       await sgMail.send(msg);
     }
   }
   ```

### 2.2 Mailgun (Gratuit jusqu'à 5000 emails/mois)

#### Avantages
- Gratuit jusqu'à 5000 emails/mois
- Très bonne délivrabilité
- API REST simple
- Support des templates

#### Configuration

1. **Créer un compte** sur [Mailgun](https://www.mailgun.com/)

2. **Vérifier votre domaine** ou utiliser le domaine de test (sandbox)

3. **Installer le package** :
   ```bash
   npm install mailgun.js form-data
   ```

4. **Configuration backend** :
   ```typescript
   // .env
   MAILGUN_API_KEY=votre_cle_api
   MAILGUN_DOMAIN=votre-domaine.com
   EMAIL_FROM=noreply@votre-domaine.com
   ```

5. **Service d'envoi d'email** :
   ```typescript
   // src/common/services/email.service.ts
   import formData from 'form-data';
   import Mailgun from 'mailgun.js';

   @Injectable()
   export class EmailService {
     private mailgun: Mailgun;
     private mg: any;

     constructor(private configService: ConfigService) {
       this.mailgun = new Mailgun(formData);
       this.mg = this.mailgun.client({
         username: 'api',
         key: this.configService.get<string>('MAILGUN_API_KEY'),
       });
     }

     async sendVerificationEmail(
       email: string,
       token: string,
       name: string,
     ): Promise<void> {
       const verificationUrl = `${this.configService.get<string>('FRONTEND_URL')}/verify-email?token=${token}`;
       
       const messageData = {
         from: `${this.configService.get<string>('EMAIL_FROM_NAME')} <${this.configService.get<string>('EMAIL_FROM')}>`,
         to: email,
         subject: 'Vérifiez votre adresse email - Manga Tracker',
         html: `
           <h1>Bonjour ${name},</h1>
           <p>Merci de vous être inscrit sur Manga Tracker !</p>
           <p>Veuillez cliquer sur le lien ci-dessous pour vérifier votre adresse email :</p>
           <a href="${verificationUrl}">Vérifier mon email</a>
           <p>Ce lien expirera dans 24 heures.</p>
         `,
         text: `
           Bonjour ${name},
           Veuillez vérifier votre email en cliquant sur : ${verificationUrl}
         `,
       };

       await this.mg.messages.create(
         this.configService.get<string>('MAILGUN_DOMAIN'),
         messageData,
       );
     }
   }
   ```

### 2.3 AWS SES (Très économique)

#### Avantages
- Très économique (environ $0.10 pour 1000 emails)
- Excellente délivrabilité
- Intégration facile avec d'autres services AWS
- Scalable

#### Configuration

1. **Créer un compte AWS** et activer SES

2. **Vérifier votre domaine** ou utiliser le sandbox (limité aux emails vérifiés)

3. **Créer des credentials IAM** pour l'accès API

4. **Installer le package** :
   ```bash
   npm install @aws-sdk/client-ses
   ```

5. **Configuration backend** :
   ```typescript
   // .env
   AWS_REGION=us-east-1
   AWS_ACCESS_KEY_ID=votre_access_key
   AWS_SECRET_ACCESS_KEY=votre_secret_key
   EMAIL_FROM=noreply@votre-domaine.com
   ```

6. **Service d'envoi d'email** :
   ```typescript
   // src/common/services/email.service.ts
   import { SESClient, SendEmailCommand } from '@aws-sdk/client-ses';

   @Injectable()
   export class EmailService {
     private sesClient: SESClient;

     constructor(private configService: ConfigService) {
       this.sesClient = new SESClient({
         region: this.configService.get<string>('AWS_REGION'),
         credentials: {
           accessKeyId: this.configService.get<string>('AWS_ACCESS_KEY_ID'),
           secretAccessKey: this.configService.get<string>('AWS_SECRET_ACCESS_KEY'),
         },
       });
     }

     async sendVerificationEmail(
       email: string,
       token: string,
       name: string,
     ): Promise<void> {
       const verificationUrl = `${this.configService.get<string>('FRONTEND_URL')}/verify-email?token=${token}`;
       
       const params = {
         Source: this.configService.get<string>('EMAIL_FROM'),
         Destination: {
           ToAddresses: [email],
         },
         Message: {
           Subject: {
             Data: 'Vérifiez votre adresse email - Manga Tracker',
             Charset: 'UTF-8',
           },
           Body: {
             Html: {
               Data: `
                 <h1>Bonjour ${name},</h1>
                 <p>Merci de vous être inscrit sur Manga Tracker !</p>
                 <p>Veuillez cliquer sur le lien ci-dessous pour vérifier votre adresse email :</p>
                 <a href="${verificationUrl}">Vérifier mon email</a>
                 <p>Ce lien expirera dans 24 heures.</p>
               `,
               Charset: 'UTF-8',
             },
             Text: {
               Data: `Bonjour ${name}, vérifiez votre email : ${verificationUrl}`,
               Charset: 'UTF-8',
             },
           },
         },
       };

       await this.sesClient.send(new SendEmailCommand(params));
     }
   }
   ```

---

## Partie 3 : Implémentation backend complète

### 3.1 Mise à jour du modèle User

```typescript
// user.entity.ts
{
  // ... champs existants
  emailVerified: {
    type: Boolean,
    default: false,
  },
  emailVerificationToken: {
    type: String,
    nullable: true,
  },
  emailVerificationExpires: {
    type: Date,
    nullable: true,
  },
}
```

### 3.2 Service de génération de token

```typescript
// src/auth/auth.service.ts
import { randomBytes } from 'crypto';

async generateEmailVerificationToken(userId: string): Promise<string> {
  const token = randomBytes(32).toString('hex');
  const expires = new Date();
  expires.setHours(expires.getHours() + 24); // Expire dans 24h

  await this.userRepository.update(userId, {
    emailVerificationToken: token,
    emailVerificationExpires: expires,
  });

  return token;
}
```

### 3.3 Endpoint d'envoi d'email de vérification

```typescript
// src/auth/auth.controller.ts
@Post('send-verification-email')
@UseGuards(JwtAuthGuard)
async sendVerificationEmail(@Req() req) {
  const user = req.user;
  
  if (user.emailVerified) {
    throw new BadRequestException('Email déjà vérifié');
  }

  const token = await this.authService.generateEmailVerificationToken(user.id);
  await this.emailService.sendVerificationEmail(
    user.email,
    token,
    user.name,
  );

  return { message: 'Email de vérification envoyé' };
}
```

### 3.4 Endpoint de vérification

```typescript
// src/auth/auth.controller.ts
@Get('verify-email')
async verifyEmail(@Query('token') token: string) {
  const user = await this.userRepository.findOne({
    where: {
      emailVerificationToken: token,
      emailVerificationExpires: MoreThan(new Date()),
    },
  });

  if (!user) {
    throw new BadRequestException('Token invalide ou expiré');
  }

  await this.userRepository.update(user.id, {
    emailVerified: true,
    emailVerificationToken: null,
    emailVerificationExpires: null,
  });

  return { message: 'Email vérifié avec succès' };
}
```

### 3.5 Middleware de vérification (Optionnel)

Pour protéger certaines routes nécessitant un email vérifié :

```typescript
// src/auth/guards/email-verified.guard.ts
@Injectable()
export class EmailVerifiedGuard implements CanActivate {
  canActivate(context: ExecutionContext): boolean {
    const request = context.switchToHttp().getRequest();
    const user = request.user;

    if (!user.emailVerified) {
      throw new ForbiddenException('Email non vérifié');
    }

    return true;
  }
}
```

---

## Partie 4 : Intégration frontend (Flutter)

### 4.1 Page de vérification d'email

Créez `lib/features/auth/views/email_verification.view.dart` :

```dart
class EmailVerificationView extends StatefulWidget {
  final String token;
  
  const EmailVerificationView({super.key, required this.token});

  @override
  State<EmailVerificationView> createState() => _EmailVerificationViewState();
}

class _EmailVerificationViewState extends State<EmailVerificationView> {
  bool _isVerifying = true;
  bool _isVerified = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _verifyEmail();
  }

  Future<void> _verifyEmail() async {
    try {
      final httpService = getIt<HttpService>();
      final response = await httpService.getWithAuthTokens(
        '/auth/verify-email?token=${widget.token}',
      );

      if (response.statusCode == 200) {
        setState(() {
          _isVerified = true;
          _isVerifying = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Erreur lors de la vérification';
        _isVerifying = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isVerifying) {
      return Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_isVerified) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.check_circle, color: Colors.green, size: 64),
              SizedBox(height: 16),
              Text('Email vérifié avec succès !'),
              SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => const LoginView()),
                  );
                },
                child: Text('Se connecter'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error, color: Colors.red, size: 64),
            SizedBox(height: 16),
            Text(_error ?? 'Erreur lors de la vérification'),
          ],
        ),
      ),
    );
  }
}
```

### 4.2 Envoi d'email de vérification après inscription

Dans `register.view.dart`, après l'inscription réussie :

```dart
// Après l'inscription
await authService.attemptSignUp(...);

// Envoyer l'email de vérification
try {
  final httpService = getIt<HttpService>();
  await httpService.postWithAuthTokens('/auth/send-verification-email');
  
  // Afficher un message à l'utilisateur
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: Text('Email de vérification envoyé'),
      content: Text('Veuillez vérifier votre boîte mail pour confirmer votre adresse email.'),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text('OK'),
        ),
      ],
    ),
  );
} catch (e) {
  // Gérer l'erreur
}
```

---

## Recommandations

### Pour le développement
- **SendGrid** : Facile à configurer, généreux en gratuit, parfait pour commencer

### Pour la production
- **AWS SES** : Si vous utilisez déjà AWS, très économique et scalable
- **Mailgun** : Bon compromis entre facilité et coût
- **SendGrid** : Si vous restez sous la limite gratuite

### Configuration minimale recommandée
1. Utiliser **SendGrid** pour commencer (gratuit, facile)
2. Configurer un domaine personnalisé pour améliorer la délivrabilité
3. Migrer vers AWS SES si le volume augmente

---

## Sécurité

1. **Tokens uniques et aléatoires** : Utiliser `crypto.randomBytes()` pour générer des tokens sécurisés
2. **Expiration des tokens** : Limiter la validité à 24-48 heures
3. **Rate limiting** : Limiter le nombre d'emails de vérification par utilisateur
4. **Validation côté serveur** : Toujours vérifier le token côté backend

---

## Templates d'emails

Créez des templates HTML professionnels pour :
- Email de vérification
- Email de bienvenue
- Email de réinitialisation de mot de passe (si implémenté)

Utilisez des services comme [MJML](https://mjml.io/) pour créer des templates responsive.

---

## Ressources

- [SendGrid Documentation](https://docs.sendgrid.com/)
- [Mailgun Documentation](https://documentation.mailgun.com/)
- [AWS SES Documentation](https://docs.aws.amazon.com/ses/)
- [Poste.io Documentation](https://poste.io/doc)

