class ServerException implements Exception {
  final String message;
  ServerException([this.message = 'Server Error']);
}

class CacheException implements Exception {}

class UnauthorizedException implements Exception {}

class NetworkException implements Exception {}

class TimeoutException implements Exception {}
