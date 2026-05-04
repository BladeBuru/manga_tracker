import 'package:equatable/equatable.dart';

/// DTO pour les informations utilisateur
class UserDto extends Equatable {
  final String username;
  final String email;
  final String? avatar;
  final DateTime? lastLogin;

  /// `true` si l'email a été vérifié via le magic link reçu à l'inscription.
  /// Quand `false`, le client affiche le `VerifyEmailBanner` et propose
  /// le bouton « Renvoyer le mail ».
  final bool emailVerified;

  const UserDto({
    required this.username,
    required this.email,
    this.avatar,
    this.lastLogin,
    this.emailVerified = false,
  });

  @override
  List<Object?> get props =>
      [username, email, avatar, lastLogin, emailVerified];

  factory UserDto.fromJson(Map<String, dynamic> json) {
    return UserDto(
      username: json['username'] ?? '',
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
      'email': email,
      'avatar': avatar,
      'lastLogin': lastLogin?.toIso8601String(),
      'emailVerified': emailVerified,
    };
  }
}
