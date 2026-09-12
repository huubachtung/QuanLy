import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';
import '../constants/api_constants.dart';
import '../errors/exceptions.dart';
import 'token_storage.dart';

class ApiClient {
  late final Dio _dio;
  final TokenStorage _tokenStorage;
  VoidCallback? onUnauthorized;
  bool _isNotifyingUnauthorized = false;

  ApiClient(this._tokenStorage) {
    _dio = Dio(BaseOptions(
      baseUrl: ApiConstants.baseUrl,
      connectTimeout: const Duration(milliseconds: ApiConstants.connectTimeout),
      receiveTimeout: const Duration(milliseconds: ApiConstants.receiveTimeout),
      responseType: ResponseType.json,
    ));

    _dio.interceptors.addAll([
      _AuthInterceptor(_tokenStorage),
      _TokenRefreshInterceptor(_dio, _tokenStorage, this),
      _ErrorInterceptor(this),
      // Bật full debug log để xem đầy đủ request và response trả về từ server
      if (kDebugMode)
        PrettyDioLogger(
          requestHeader: true,
          requestBody: true,
          responseBody: true,
          responseHeader: false,
          error: true,
          compact: false,
          maxWidth: 120,
        ),
    ]);
  }

  void notifyUnauthorized() {
    if (_isNotifyingUnauthorized) return;
    _isNotifyingUnauthorized = true;
    _tokenStorage.clearAll();
    onUnauthorized?.call();
    Future.delayed(const Duration(seconds: 2), () {
      _isNotifyingUnauthorized = false;
    });
  }

  Dio get dio => _dio;
}

class _AuthInterceptor extends Interceptor {
  final TokenStorage _tokenStorage;

  _AuthInterceptor(this._tokenStorage);

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    // Không thêm token vào route đăng nhập, đăng ký
    if (!options.path.contains(ApiConstants.login) &&
        !options.path.contains(ApiConstants.signup) &&
        !options.path.contains(ApiConstants.refreshToken)) {
      final token = await _tokenStorage.getAccessToken();
      if (token != null) {
        options.headers['Authorization'] = 'Bearer $token';
      }
    }
    return super.onRequest(options, handler);
  }
}

class _TokenRefreshInterceptor extends Interceptor {
  final Dio _dio;
  final TokenStorage _tokenStorage;
  final ApiClient _apiClient;
  bool _isRefreshing = false;

  _TokenRefreshInterceptor(this._dio, this._tokenStorage, this._apiClient);

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    if (err.response?.statusCode == 401 && 
        !err.requestOptions.path.contains(ApiConstants.login) &&
        !err.requestOptions.path.contains(ApiConstants.refreshToken)) {
      
      if (!_isRefreshing) {
        _isRefreshing = true;
        try {
          final refreshToken = await _tokenStorage.getRefreshToken();
          if (refreshToken != null) {
            final response = await Dio(BaseOptions(baseUrl: ApiConstants.baseUrl)).post(
              ApiConstants.refreshToken,
              data: {
                'refreshToken': refreshToken,
                'refresh_token': refreshToken,
              },
            );
            
            if (response.statusCode == 200) {
              final newAccessToken = response.data['accessToken'] ?? response.data['access_token'];
              final newRefreshToken = response.data['refreshToken'] ?? response.data['refresh_token'];
              
              if (newAccessToken != null) {
                await _tokenStorage.saveTokens(
                  accessToken: newAccessToken.toString(),
                  refreshToken: newRefreshToken?.toString() ?? refreshToken,
                );

                // Retry the original request
                err.requestOptions.headers['Authorization'] = 'Bearer $newAccessToken';
                final opts = Options(
                  method: err.requestOptions.method,
                  headers: err.requestOptions.headers,
                );
                final cloneReq = await _dio.request(
                  err.requestOptions.path,
                  options: opts,
                  data: err.requestOptions.data,
                  queryParameters: err.requestOptions.queryParameters,
                );
                return handler.resolve(cloneReq);
              }
            }
          }
          // Refresh token null hoặc response không có newAccessToken -> Hết quyền truy cập
          _apiClient.notifyUnauthorized();
          return handler.next(err);
        } catch (e) {
          // Xoá token nếu refresh lỗi (sẽ bị logout)
          _apiClient.notifyUnauthorized();
          return handler.next(err);
        } finally {
          _isRefreshing = false;
        }
      }
    }
    return super.onError(err, handler);
  }
}

class _ErrorInterceptor extends Interceptor {
  final ApiClient _apiClient;

  _ErrorInterceptor(this._apiClient);

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    Exception exception;
    switch (err.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        exception = TimeoutException();
        break;
      case DioExceptionType.connectionError:
        exception = NetworkException();
        break;
      case DioExceptionType.badResponse:
        final statusCode = err.response?.statusCode;
        if (statusCode == 401 || statusCode == 403) {
          exception = UnauthorizedException();
          if (!err.requestOptions.path.contains(ApiConstants.login) &&
              !err.requestOptions.path.contains(ApiConstants.refreshToken)) {
            _apiClient.notifyUnauthorized();
          }
        } else {
          final message = _extractMessage(err.response?.data) ?? 'Lỗi máy chủ ($statusCode)';
          exception = ServerException(message);
        }
        break;
      default:
        exception = ServerException('Lỗi không xác định: ${err.message}');
    }
    // Dùng handler.reject thay vì throw để Dio không bọc lại exception
    handler.reject(DioException(
      requestOptions: err.requestOptions,
      response: err.response,
      type: err.type,
      error: exception,
    ));
  }

  String? _extractMessage(dynamic data) {
    if (data is Map<String, dynamic> && data.containsKey('message')) {
      return data['message']?.toString();
    }
    return null;
  }
}
