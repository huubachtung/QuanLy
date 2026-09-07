import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:app/core/utils/app_colors.dart';
import 'package:app/core/utils/app_tokens.dart';
import '../../../../core/models/asset_model.dart';
import '../bloc/asset_bloc.dart';
import '../bloc/asset_state.dart';
import '../../../../shared/widgets/status_badge.dart';

class AssetDetailPage extends StatelessWidget {
  final String assetId;
  const AssetDetailPage({super.key, required this.assetId});

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
    final fmt = DateFormat('dd/MM/yyyy');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Chi tiết tài sản'),
      ),
      body: BlocBuilder<AssetBloc, AssetState>(builder: (context, state) {
        if (state is AssetLoaded) {
          final asset = state.assets.firstWhere((a) => a.id == assetId);
          final color = _statusColor(asset.status);

          return SingleChildScrollView(
            padding: const EdgeInsets.all(AppTokens.s16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header card
                Container(
                  padding: const EdgeInsets.all(AppTokens.s16),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkCard : AppColors.lightCard,
                    borderRadius: BorderRadius.circular(AppTokens.rCard),
                    border: Border.all(
                      color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                      width: 1.0,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: color.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(AppTokens.rInput),
                            ),
                            child: Icon(Icons.inventory_2_outlined, color: color, size: 24),
                          ),
                          const SizedBox(width: AppTokens.s12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  asset.name,
                                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w700,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: AppTokens.s4),
                                Text(
                                  asset.assetCode,
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: AppTokens.s8),
                          StatusBadge(label: asset.status.label, color: color),
                        ],
                      ),
                      if (asset.notes.isNotEmpty) ...[
                        const SizedBox(height: AppTokens.s12),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(AppTokens.s8),
                          decoration: BoxDecoration(
                            color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                            borderRadius: BorderRadius.circular(AppTokens.rMicro),
                            border: Border.all(
                              color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                            ),
                          ),
                          child: Text(
                            asset.notes,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: AppTokens.s12),
                // Details
                _buildSection(
                  'Thông tin thiết bị',
                  [
                    _Row('Danh mục', asset.category),
                    _Row('Thương hiệu', asset.brand),
                    _Row('Model', asset.model),
                    if (asset.serialNumber.isNotEmpty)
                      _Row('Serial', asset.serialNumber),
                    _Row(
                      'Vị trí',
                      asset.location.isEmpty ? 'Chưa cập nhật' : asset.location,
                    ),
                  ],
                  isDark,
                  context,
                ),
                const SizedBox(height: AppTokens.s12),
                _buildSection(
                  'Thông tin mua sắm',
                  [
                    if (asset.purchaseDate != null)
                      _Row('Ngày mua', fmt.format(asset.purchaseDate!)),
                    if (asset.purchasePrice > 0)
                      _Row(
                        'Giá mua',
                        '${NumberFormat('#,###', 'vi').format(asset.purchasePrice)} VNĐ',
                      ),
                    if (asset.warrantyExpiry != null)
                      _Row(
                        'Bảo hành đến',
                        fmt.format(asset.warrantyExpiry!),
                        valueColor: asset.warrantyExpiry!.isBefore(DateTime.now())
                            ? AppColors.error
                            : null,
                      ),
                  ],
                  isDark,
                  context,
                ),
                const SizedBox(height: AppTokens.s12),
                _buildSection(
                  'Lịch sử bàn giao',
                  [
                    _Row(
                      'Ngày nhận',
                      asset.assignedAt != null
                          ? fmt.format(asset.assignedAt!)
                          : 'N/A',
                    ),
                  ],
                  isDark,
                  context,
                ),
                const SizedBox(height: AppTokens.s24),
              ],
            ),
          );
        }
        return const Center(child: CircularProgressIndicator());
      }),
    );
  }

  Widget _buildSection(
    String title,
    List<Widget> rows,
    bool isDark,
    BuildContext ctx,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppTokens.s16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        borderRadius: BorderRadius.circular(AppTokens.rCard),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          width: 1.0,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(ctx).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppTokens.s8),
          ...rows,
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  final String label, value;
  final Color? valueColor;
  const _Row(this.label, this.value, {this.valueColor});

  @override
  Widget build(BuildContext ctx) => Padding(
    padding: const EdgeInsets.symmetric(vertical: AppTokens.s4),
    child: Row(
      children: [
        SizedBox(
          width: 120,
          child: Text(
            '$label:',
            style: Theme.of(ctx).textTheme.bodySmall,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: valueColor ?? Theme.of(ctx).textTheme.bodyMedium?.color,
            ),
          ),
        ),
      ],
    ),
  );
}
