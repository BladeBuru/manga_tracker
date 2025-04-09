class InvalidCredentialsException implements Exception {
  String cause;
  InvalidCredentialsException(this.cause);
}
