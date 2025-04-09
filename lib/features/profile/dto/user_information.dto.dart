class UserInformationDto {
  final String email;
  final String username;

  const UserInformationDto({required this.email, required this.username});

  factory UserInformationDto.fromJson(Map<String, dynamic> json) {
    return UserInformationDto(email: json['email'], username: json['username']);
  }
}
