import 'dart:async';
import 'package:flutter/widgets.dart';

/// Service quản lý chu kỳ kiểm tra thông báo định kỳ (Polling).
///
/// Tuân thủ Clean Architecture:
/// - Thuộc tầng Core, chỉ đóng vai trò cơ chế điều phối thời gian (pure scheduler).
/// - KHÔNG chứa logic nghiệp vụ (không gọi API, không diff dữ liệu, không import BLoC).
/// - Giao tiếp với Presentation layer thông qua [VoidCallback] khi đến chu kỳ.
class NotificationPollingService with WidgetsBindingObserver {
  NotificationPollingService._internal();

  static final NotificationPollingService instance =
      NotificationPollingService._internal();

  static const Duration pollingInterval = Duration(minutes: 5);

  Timer? _timer;
  VoidCallback? _onPollTick;
  DateTime? _lastPollTime;
  bool _isObserverRegistered = false;

  /// Bắt đầu chu kỳ polling với callback được cung cấp.
  void startPolling({required VoidCallback onPollTick}) {
    _onPollTick = onPollTick;

    if (!_isObserverRegistered) {
      WidgetsBinding.instance.addObserver(this);
      _isObserverRegistered = true;
    }

    _timer?.cancel();
    _lastPollTime = DateTime.now();

    _timer = Timer.periodic(pollingInterval, (_) {
      _onTick();
    });

    debugPrint('🔔 [PollingService] Đã khởi động polling định kỳ (mỗi ${pollingInterval.inMinutes} phút)');
  }

  /// Dừng chu kỳ polling và dọn dẹp tài nguyên.
  void stopPolling() {
    _timer?.cancel();
    _timer = null;
    _onPollTick = null;
    _lastPollTime = null;

    if (_isObserverRegistered) {
      WidgetsBinding.instance.removeObserver(this);
      _isObserverRegistered = false;
    }

    debugPrint('🔔 [PollingService] Đã dừng polling');
  }

  void _onTick() {
    _lastPollTime = DateTime.now();
    debugPrint('🔔 [PollingService] Kích hoạt tick kiểm tra thông báo...');
    _onPollTick?.call();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _timer != null && _lastPollTime != null) {
      final elapsed = DateTime.now().difference(_lastPollTime!);
      if (elapsed >= pollingInterval) {
        debugPrint(
          '🔔 [PollingService] App resume sau ${elapsed.inMinutes} phút (>= ${pollingInterval.inMinutes}m), kích hoạt poll ngay...',
        );
        _timer?.cancel();
        _onTick();
        _timer = Timer.periodic(pollingInterval, (_) {
          _onTick();
        });
      }
    }
  }
}
