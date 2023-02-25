class ApiException implements Exception {}

class IoException implements ApiException {
  final Exception cause;

  IoException(this.cause);

  @override
  String toString() {
    return 'IoException: $cause';
  }
}

class ResponseStatusException implements ApiException {
  final int status;

  const ResponseStatusException(this.status);

  @override
  String toString() {
    return 'Received unsuccessful response status $status';
  }
}
