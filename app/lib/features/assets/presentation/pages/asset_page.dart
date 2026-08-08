import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:app/core/utils/app_colors.dart';
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
    if (category.contains('IT') || category.contains('Thiết bị')) return Icons.computer_rounded;
    if (category.contains('Điện thoại')) return Icons.smartphone_rounded;
    if (category.contains('Nội thất') || category.contains('Ghế')) return Icons.chair_rounded;
    if (category.contains('Xe')) return Icons.directions_car_rounded;
    return Icons.inventory_2_rounded;
  }

  Color _statusColor(AssetStatus status) {
    switch (status) {
      case AssetStatus.inUse: return AppColors.success;
      case AssetStatus.maintenance: return AppColors.warning;
      case AssetStatus.broken: return AppColors.error;
      case AssetStatus.disposed: return AppColors.statusCancelled;
      default: return AppColors.info;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return BlocBuilder<AssetBloc, AssetState>(
      builder: (context, state) {
        if (state is AssetLoading || state is AssetInitial) {
          return ListView.builder(itemCount: 4, itemBuilder: (_, __) => const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 6), child: CardShimmer()));
        }
        
        if (state is AssetLoaded) {
          if (state.assets.isEmpty) {
            return const EmptyState(icon: Icons.inventory_2_rounded, title: 'Chưa có tài sản nào được giao');
          }
          
          return Column(children: [
            // Summary
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(children: [
                _StatChip('Tổng tài sản', '${state.assets.length}', AppColors.info, isDark),
                const SizedBox(width: 8),
                _StatChip('Đang dùng', '${state.assets.where((a) => a.status == AssetStatus.inUse).length}', AppColors.success, isDark),
                const SizedBox(width: 8),
                _StatChip('Bảo trì', '${state.assets.where((a) => a.status == AssetStatus.maintenance).length}', AppColors.warning, isDark),
              ]),
            ),
            Expanded(child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              itemCount: state.assets.length,
              itemBuilder: (_, i) {
                final asset = state.assets[i];
                final color = _statusColor(asset.status);
                return GestureDetector(
                  onTap: () => context.push('/assets/${asset.id}'),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkCard : AppColors.lightCard,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
                    ),
                    child: Row(children: [
                      Container(width: 48, height: 48, decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(12)),
                        child: Icon(_categoryIcon(asset.category), color: color, size: 24)),
                      const SizedBox(width: 12),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(asset.name, style: Theme.of(context).textTheme.titleSmall,
                          maxLines: 1, overflow: TextOverflow.ellipsis),
                        const SizedBox(height: 3),
                        Text('${asset.assetCode} • ${asset.brand}', style: Theme.of(context).textTheme.bodySmall),
                        const SizedBox(height: 6),
                        Row(children: [
                          StatusBadge(label: asset.status.label, color: color, fontSize: 10,
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3)),
                          if (asset.assignedAt != null) ...[
                            const Spacer(),
                            Text('Từ ${DateFormat('dd/MM/yyyy').format(asset.assignedAt!)}',
                              style: Theme.of(context).textTheme.labelSmall),
                          ],
                        ]),
                      ])),
                      const SizedBox(width: 8),
                      const Icon(Icons.arrow_forward_ios_rounded, size: 14),
                    ]),
                  ),
                );
              },
            )),
          ]);
        }
        
        return const SizedBox.shrink();
      }
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label, value;
  final Color color;
  final bool isDark;
  const _StatChip(this.label, this.value, this.color, this.isDark);
  @override Widget build(BuildContext ctx) => Expanded(child: Container(
    padding: const EdgeInsets.symmetric(vertical: 10),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10),
      border: Border.all(color: color.withValues(alpha: 0.3)),
    ),
    child: Column(children: [
      Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: color)),
      Text(label, style: TextStyle(fontSize: 10, color: Theme.of(ctx).textTheme.bodySmall?.color), textAlign: TextAlign.center),
    ]),
  ));
}
