import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/usecases/usecase.dart';
import '../../domain/usecases/get_assets.dart';
import 'asset_event.dart';
import 'asset_state.dart';

class AssetBloc extends Bloc<AssetEvent, AssetState> {
  final GetAssetsUseCase getAssets;

  AssetBloc({required this.getAssets}) : super(AssetInitial()) {
    on<LoadAssets>(_onLoadAssets);
  }

  Future<void> _onLoadAssets(LoadAssets event, Emitter<AssetState> emit) async {
    emit(AssetLoading());
    final failureOrData = await getAssets(NoParams());
    failureOrData.fold(
      (f) => emit(AssetError(f.message)),
      (data) => emit(AssetLoaded(data)),
    );
  }
}
