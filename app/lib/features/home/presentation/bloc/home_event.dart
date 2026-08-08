import 'package:equatable/equatable.dart';

abstract class HomeEvent extends Equatable {
  const HomeEvent();
  @override
  List<Object> get props => [];
}

class ChangeTabEvent extends HomeEvent {
  final int index;
  const ChangeTabEvent(this.index);
  @override
  List<Object> get props => [index];
}
