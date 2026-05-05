class UserInformationDto {
  final String email;
  final String username;

  /// `true` si l'email a été vérifié via le magic link reçu à l'inscription.
  /// Lu depuis `emailVerified` (bool) ou déduit de `emailVerifiedAt != null`.
  final bool emailVerified;

  const UserInformationDto({
    required this.email,
    required this.username,
    this.emailVerified = false,
  });

  factory UserInformationDto.fromJson(Map<String, dynamic> json) {
    return UserInformationDto(
      email: json['email'],
      username: json['username'],
      emailVerified: _parseEmailVerified(json),
    );
  }

  static bool _parseEmailVerified(Map<String, dynamic> json) {
    // L'API peut retourner soit `emailVerified` (bool) soit `emailVerifiedAt`
    // (timestamp ISO non-null). On accepte les deux pour résilience.
    final verified = json['emailVerified'];
    if (verified is bool) return verified;
    final verifiedAt = json['emailVerifiedAt'];
    if (verifiedAt is String && verifiedAt.isNotEmpty) return true;
    return false;
  }

  Map<String, dynamic> toJson() {
    return {
      'email': email,
      'username': username,
      'emailVerified': emailVerified,
    };
  }
}
