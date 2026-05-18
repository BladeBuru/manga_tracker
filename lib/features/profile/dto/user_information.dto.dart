/// Genre déclaré par l'utilisateur (Phase 3). Optionnel, RGPD opt-in.
enum UserGender {
  male('male'),
  female('female'),
  nonBinary('non_binary'),
  preferNotToSay('prefer_not_to_say');

  final String value;
  const UserGender(this.value);

  static UserGender? fromString(String? raw) {
    if (raw == null) return null;
    for (final g in UserGender.values) {
      if (g.value == raw) return g;
    }
    return null;
  }
}

class UserInformationDto {
  final int? id;
  final String email;
  final String username;

  /// `true` si l'email a été vérifié via le magic link reçu à l'inscription.
  /// Lu depuis `emailVerified` (bool) ou déduit de `emailVerifiedAt != null`.
  final bool emailVerified;

  // ─────── Phase 3 : profil étendu ───────

  /// Nom à afficher publiquement (commentaires, profil public). Si null,
  /// fallback côté UI sur `username`.
  final String? displayName;

  /// Courte description (max 500 chars).
  final String? bio;

  /// URL avatar (placeholder si null).
  final String? avatarUrl;

  /// Date de naissance — RGPD opt-in. Stockée ISO YYYY-MM-DD.
  final String? dateOfBirth;

  /// Genre déclaré — RGPD opt-in.
  final UserGender? gender;

  /// `true` si le profil est visible par les amis (Phase 6). Default false.
  final bool isProfilePublic;

  const UserInformationDto({
    this.id,
    required this.email,
    required this.username,
    this.emailVerified = false,
    this.displayName,
    this.bio,
    this.avatarUrl,
    this.dateOfBirth,
    this.gender,
    this.isProfilePublic = false,
  });

  /// Helper pour l'affichage : utilise `displayName` s'il est défini, sinon
  /// fallback sur `username`. Toujours non-null.
  String get effectiveDisplayName =>
      (displayName?.isNotEmpty ?? false) ? displayName! : username;

  factory UserInformationDto.fromJson(Map<String, dynamic> json) {
    return UserInformationDto(
      id: (json['id'] as num?)?.toInt(),
      email: json['email'] as String? ?? '',
      username: json['username'] as String? ?? '',
      emailVerified: _parseEmailVerified(json),
      displayName: json['displayName'] as String?,
      bio: json['bio'] as String?,
      avatarUrl: json['avatarUrl'] as String?,
      dateOfBirth: json['dateOfBirth'] as String?,
      gender: UserGender.fromString(json['gender'] as String?),
      isProfilePublic: json['isProfilePublic'] as bool? ?? false,
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
      if (id != null) 'id': id,
      'email': email,
      'username': username,
      'emailVerified': emailVerified,
      if (displayName != null) 'displayName': displayName,
      if (bio != null) 'bio': bio,
      if (avatarUrl != null) 'avatarUrl': avatarUrl,
      if (dateOfBirth != null) 'dateOfBirth': dateOfBirth,
      if (gender != null) 'gender': gender!.value,
      'isProfilePublic': isProfilePublic,
    };
  }

  UserInformationDto copyWith({
    int? id,
    String? email,
    String? username,
    bool? emailVerified,
    String? displayName,
    String? bio,
    String? avatarUrl,
    String? dateOfBirth,
    UserGender? gender,
    bool? isProfilePublic,
  }) {
    return UserInformationDto(
      id: id ?? this.id,
      email: email ?? this.email,
      username: username ?? this.username,
      emailVerified: emailVerified ?? this.emailVerified,
      displayName: displayName ?? this.displayName,
      bio: bio ?? this.bio,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      gender: gender ?? this.gender,
      isProfilePublic: isProfilePublic ?? this.isProfilePublic,
    );
  }
}
