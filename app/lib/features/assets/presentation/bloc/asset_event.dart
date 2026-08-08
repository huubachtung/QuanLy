import 'package:equatable/equatable.dart';

abstract class AssetEvent extends Equatable {
  const AssetEvent();
  @override List<Object?> get props => [];
}

class LoadAssets extends AssetEvent {}
