import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/usecases/usecase.dart';
import '../../domain/usecases/notification_usecases.dart';
import 'notification_event.dart';
import 'notification_state.dart';

class NotificationBloc extends Bloc<NotificationEvent, NotificationState> {
  final GetNotificationsUseCase getNotifications;
  final MarkNotificationReadUseCase markRead;
  final MarkAllNotificationsReadUseCase markAllRead;

  NotificationBloc({
    required this.getNotifications,
    required this.markRead,
    required this.markAllRead,
  }) : super(NotificationInitial()) {
    on<LoadNotifications>(_onLoadData);
    on<MarkNotificationRead>(_onMarkRead);
    on<MarkAllNotificationsRead>(_onMarkAllRead);
  }

  Future<void> _onLoadData(LoadNotifications event, Emitter<NotificationState> emit) async {
    emit(NotificationLoading());
    final failureOrData = await getNotifications(NoParams());
    failureOrData.fold(
      (f) => emit(NotificationError(f.message)),
      (data) => emit(NotificationLoaded(data)),
    );
  }

  Future<void> _onMarkRead(MarkNotificationRead event, Emitter<NotificationState> emit) async {
    if (state is NotificationLoaded) {
      await markRead(event.id);
      add(LoadNotifications());
    }
  }

  Future<void> _onMarkAllRead(MarkAllNotificationsRead event, Emitter<NotificationState> emit) async {
    if (state is NotificationLoaded) {
      await markAllRead(NoParams());
      add(LoadNotifications());
    }
  }
}
