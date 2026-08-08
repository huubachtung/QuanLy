import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/models/notification_model.dart';
import '../../../../core/usecases/usecase.dart';
import '../repositories/notification_repository.dart';

class GetNotificationsUseCase implements UseCase<List<NotificationModel>, NoParams> {
  final NotificationRepository repository;
  GetNotificationsUseCase(this.repository);
  @override Future<Either<Failure, List<NotificationModel>>> call(NoParams params) => repository.getNotifications();
}

class MarkNotificationReadUseCase implements UseCase<void, String> {
  final NotificationRepository repository;
  MarkNotificationReadUseCase(this.repository);
  @override Future<Either<Failure, void>> call(String params) => repository.markAsRead(params);
}

class MarkAllNotificationsReadUseCase implements UseCase<void, NoParams> {
  final NotificationRepository repository;
  MarkAllNotificationsReadUseCase(this.repository);
  @override Future<Either<Failure, void>> call(NoParams params) => repository.markAllAsRead();
}
