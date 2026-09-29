import 'package:equatable/equatable.dart';

/// DTO pour les informations utilisateur
class UserDto extends Equatable {
  final String username;

  /// Nom à afficher choisi par l'utilisateur (page « Modifier le profil »).
  /// `null` = non renseigné : l'identifiant sert alors de nom.
  final String? displayName;
  final String email;
  final String? avatar;
  final DateTime? lastLogin;

  /// `true` si l'email a été vérifié via le magic link reçu à l'inscription.
  /// Quand `false`, le client affiche le `VerifyEmailBanner` et propose
  /// le bouton « Renvoyer le mail ».
  final bool emailVerified;

  const UserDto({
    required this.username,
    this.displayName,
    required this.email,
    this.avatar,
    this.lastLogin,
    this.emailVerified = false,
  });

  @override
  List<Object?> get props =>
      [username, displayName, email, avatar, lastLogin, emailVerified];

  /// Nom montré à l'utilisateur (salutation) : le nom à afficher s'il existe.
  /// Afficher `username` ici rendait toute modification du nom invisible.
  String get greetingName =>
      (displayName?.trim().isNotEmpty ?? false) ? displayName!.trim() : username;

  factory UserDto.fromJson(Map<String, dynamic> json) {
    return UserDto(
      username: json['username'] ?? '',
      displayName: json['displayName'] as String?,
      email: json['email'] ?? '',
      avatar: json['avatar'],
      lastLogin: json['lastLogin'] != null
          ? DateTime.parse(json['lastLogin'])
          : null,
      emailVerified: json['emailVerified'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'username': username,
      'displayName': displayName,
      'email': email,
      'avatar': avatar,
      'lastLogin': lastLogin?.toIso8601String(),
      'emailVerified': emailVerified,
    };
  }
}
