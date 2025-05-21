class AuthorDto {
  final String name;
  final int? authorId;
  final String? url;
  final String type;


  const AuthorDto(
      {required this.name, this.authorId,this.url, required this.type});

  factory AuthorDto.fromJson(Map<String, dynamic> json) {
    return AuthorDto(
        name: json['name'], authorId: json['author_id'], url: json['url'], type: json['type'] );
  }
}
