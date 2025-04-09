class AuthorDto {
  final String name;
  final String authorId;
  final String type;

  const AuthorDto(
      {required this.name, required this.authorId, required this.type});

  factory AuthorDto.fromJson(Map<String, dynamic> json) {
    return AuthorDto(
        name: json['name'], authorId: json['author_id'], type: json['type']);
  }
}
