class EmailAlreadyUsedException implements Exception {
  final String? message;

  EmailAlreadyUsedException([this.message]);

  @override
  String toString() => message ?? 'Email already used';
}

