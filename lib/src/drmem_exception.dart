sealed class DrMemException implements Exception {
  final String desc;

  const DrMemException(this.desc);

  @override
  String toString() => desc;
}

/// GraphQL-level errors (query/mutation/subscription errors from the server)
final class DrMemServerException extends DrMemException {
  final Object? originalError;

  const DrMemServerException(super.desc, {this.originalError});
}

/// Network-level errors (socket, HTTP, connection failures)
final class DrMemNetworkException extends DrMemException {
  final Object? originalError;
  final StackTrace? stackTrace;

  const DrMemNetworkException(super.desc, {this.originalError, this.stackTrace});
}

/// Stream-level errors (unexpected stream termination, data parsing)
final class DrMemStreamException extends DrMemException {
  final Object? originalError;
  final StackTrace? stackTrace;

  const DrMemStreamException(super.desc, {this.originalError, this.stackTrace});
}
