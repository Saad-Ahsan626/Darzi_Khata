class LocalDatabaseException implements Exception {
  final String message;

  LocalDatabaseException([this.message = 'A local database error occurred']);

  @override
  String toString() => 'LocalDatabaseException: $message';
}
