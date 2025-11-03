import 'package:equatable/equatable.dart';

/// DTO pour les informations utilisateur
class UserDto extends Equatable {
  final String username;
  final String email;
  final String? avatar;
  final DateTime? lastLogin;
  
  const UserDto({
    required this.username,
    required this.email,
    this.avatar,
    this.lastLogin,
  });
  
  @override
  List<Object?> get props => [username, email, avatar, lastLogin];
  
  factory UserDto.fromJson(Map<String, dynamic> json) {
    return UserDto(
      username: json['username'] ?? '',
      email: json['email'] ?? '',
      avatar: json['avatar'],
      lastLogin: json['lastLogin'] != null 
          ? DateTime.parse(json['lastLogin']) 
          : null,
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'username': username,
      'email': email,
      'avatar': avatar,
      'lastLogin': lastLogin?.toIso8601String(),
    };
  }
}
