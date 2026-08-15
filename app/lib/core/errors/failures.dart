import 'package:equatable/equatable.dart';
import 'package:dio/dio.dart';
import 'exceptions.dart';

abstract class Failure extends Equatable {
  final String message;
  const Failure(this.message);

  @override
  List<Object> get props => [message];

  factory Failure.fromException(Exception e) {
    // Nếu là DioException, lấy custom exception từ bên trong
    if (e is DioException) {
      final innerError = e.error;
      if (innerError is ServerException) return ServerFailure(innerError.message);
      if (innerError is UnauthorizedException) return const UnauthorizedFailure();
      if (innerError is TimeoutException) return const TimeoutFailure();
      if (innerError is NetworkException) return const NetworkFailure();
      // Fallback: thử lấy message từ response body
      final responseData = e.response?.data;
      if (responseData is Map<String, dynamic> && responseData.containsKey('message')) {
        return ServerFailure(responseData['message'].toString());
      }
      return ServerFailure('Lỗi kết nối: ${e.message ?? "không xác định"}');
    }
    if (e is ServerException) return ServerFailure(e.message);
    if (e is UnauthorizedException) return const UnauthorizedFailure();
    if (e is TimeoutException) return const TimeoutFailure();
    if (e is NetworkException) return const NetworkFailure();
    return const ServerFailure('Lỗi không xác định');
  }
}

class ServerFailure extends Failure {
  const ServerFailure([super.message = 'Lỗi máy chủ']);
}

class CacheFailure extends Failure {
  const CacheFailure([super.message = 'Lỗi lưu trữ cục bộ']);
}

class NetworkFailure extends Failure {
  const NetworkFailure([super.message = 'Không có kết nối mạng']);
}

class UnauthorizedFailure extends Failure {
  const UnauthorizedFailure([super.message = 'Phiên đăng nhập hết hạn']);
}

class TimeoutFailure extends Failure {
  const TimeoutFailure([super.message = 'Hết thời gian kết nối']);
}
