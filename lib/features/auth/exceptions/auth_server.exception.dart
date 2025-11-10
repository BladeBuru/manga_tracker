class AuthServerException implements Exception {
  final int statusCode;
  final String? message;

  AuthServerException(this.statusCode, [this.message]);

  @override
  String toString() =>
      'AuthServerException(statusCode: $statusCode, message: $message)';
}

