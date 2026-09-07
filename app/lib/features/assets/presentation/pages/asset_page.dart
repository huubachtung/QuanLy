import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:app/core/utils/app_colors.dart';
import 'package:app/core/utils/app_tokens.dart';
import '../../../../core/models/asset_model.dart';
import '../bloc/asset_bloc.dart';
import '../bloc/asset_event.dart';
import '../bloc/asset_state.dart';
import '../../../../shared/widgets/status_badge.dart';
import '../../../../shared/widgets/loading_shimmer.dart';
import '../../../../shared/widgets/empty_state.dart';

class AssetPage extends StatefulWidget {
  const AssetPage({super.key});
  @override State<AssetPage> createState() => _AssetPageState();
}

class _AssetPageState extends State<AssetPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AssetBloc>().add(LoadAssets());
    });
  }

  IconData _categoryIcon(String category) {
    if (category.contains('IT') || category.contains('Thiết bị')) {
      return Icons.computer_outlined;
    }
    if (category.contains('Điện thoại')) {
      return Icons.smartphone_outlined;
    }
    if (category.contains('Nội thất') || category.contains('Ghế')) {
      return Icons.chair_outlined;
    }
    if (category.contains('Xe')) {
      return Icons.directions_car_outlined;
    }
    return Icons.inventory_2_outlined;
  }

  Color _statusColor(AssetStatus status) {
    switch (status) {
      case AssetStatus.inUse:
        return AppColors.success;
      case AssetStatus.maintenance:
        return AppColors.warning;
      case AssetStatus.broken:
        return AppColors.error;
      case AssetStatus.disposed:
        return AppColors.statusCancelled;
      default:
        return AppColors.info;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return BlocBuilder<AssetBloc, AssetState>(
      builder: (context, state) {
        if (state is AssetLoading || state is AssetInitial) {
          return ListView.builder(
            padding: const EdgeInsets.all(AppTokens.s16),
            itemCount: 4,
            itemBuilder: (_, __) => const Padding(
              padding: EdgeInsets.only(bottom: AppTokens.s8),
              child: CardShimmer(),
            ),
          );
        }
        
        if (state is AssetLoaded) {
          if (state.assets.isEmpty) {
            return const EmptyState(
              icon: Icons.inventory_2_outlined,
              title: 'Chưa có tài sản nào được giao',
            );
          }
          
          return Column(
            children: [
              // Summary chips
              Padding(
                padding: const EdgeInsets.all(AppTokens.s16),
                child: Row(
                  children: [
                    _StatChip('Tổng tài sản', '${state.assets.length}', AppColors.info, isDark),
                    const SizedBox(width: AppTokens.s8),
                    _StatChip(
                      'Đang dùng',
                      '${state.assets.where((a) => a.status == AssetStatus.inUse).length}',
                      AppColors.success,
                      isDark,
                    ),
                    const SizedBox(width: AppTokens.s8),
                    _StatChip(
                      'Bảo trì',
                      '${state.assets.where((a) => a.status == AssetStatus.maintenance).length}',
                      AppColors.warning,
                      isDark,
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.fromLTRB(AppTokens.s16, 0, AppTokens.s16, AppTokens.s16),
                  itemCount: state.assets.length,
                  itemBuilder: (_, i) {
                    final asset = state.assets[i];
                    final color = _statusColor(asset.status);
                    return Container(
                      margin: const EdgeInsets.only(bottom: AppTokens.s8),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.darkCard : AppColors.lightCard,
                        borderRadius: BorderRadius.circular(AppTokens.rCard),
                        border: Border.all(
                          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                          width: 1.0,
                        ),
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () => context.push('/assets/${asset.id}'),
                          borderRadius: BorderRadius.circular(AppTokens.rCard),
                          child: Padding(
                            padding: const EdgeInsets.all(AppTokens.s12),
                            child: Row(
                              children: [
                                Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: color.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(AppTokens.rInput),
                                  ),
                                  child: Icon(_categoryIcon(asset.category), color: color, size: 20),
                                ),
                                const SizedBox(width: AppTokens.s12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        asset.name,
                                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                          fontWeight: FontWeight.w600,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: AppTokens.s4),
                                      Text(
                                        '${asset.assetCode} • ${asset.brand}',
                                        style: Theme.of(context).textTheme.bodySmall,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: AppTokens.s8),
                                      Row(
                                        children: [
                                          StatusBadge(
                                            label: asset.status.label,
                                            color: color,
                                          ),
                                          if (asset.assignedAt != null) ...[
                                            const Spacer(),
                                            Text(
                                              'Từ ${DateFormat('dd/MM/yyyy').format(asset.assignedAt!)}',
                                              style: Theme.of(context).textTheme.labelSmall,
                                            ),
                                          ],
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: AppTokens.s8),
                                Icon(
                                  Icons.chevron_right_rounded,
                                  size: 18,
                                  color: Theme.of(context).textTheme.bodySmall?.color,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        }
        
        return const SizedBox.shrink();
      },
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label, value;
  final Color color;
  final bool isDark;
  const _StatChip(this.label, this.value, this.color, this.isDark);

  @override
  Widget build(BuildContext ctx) => Expanded(
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: AppTokens.s8, horizontal: AppTokens.s4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppTokens.rInput),
        border: Border.all(color: color.withValues(alpha: 0.25), width: 1.0),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          const SizedBox(height: AppTokens.s4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: Theme.of(ctx).textTheme.bodySmall?.color,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    ),
  );
}
