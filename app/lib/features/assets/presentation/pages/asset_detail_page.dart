import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:app/core/utils/app_colors.dart';
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
      body: BlocBuilder<AssetBloc, AssetState>(builder: (context, state) {
        if (state is AssetLoaded) {
          final asset = state.assets.firstWhere((a) => a.id == assetId);
          final color = _statusColor(asset.status);

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              // Header
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkCard : AppColors.lightCard,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: color.withValues(alpha: 0.4)),
                ),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        Container(
                            width: 56,
                            height: 56,
                            decoration: BoxDecoration(
                                color: color.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(14)),
                            child: Icon(Icons.inventory_2_rounded,
                                color: color, size: 28)),
                        const SizedBox(width: 14),
                        Expanded(
                            child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                              Text(asset.name,
                                  style: Theme.of(context)
                                      .textTheme
                                      .headlineSmall),
                              const SizedBox(height: 4),
                              Text(asset.assetCode,
                                  style: Theme.of(context).textTheme.bodySmall),
                            ])),
                        StatusBadge(label: asset.status.label, color: color),
                      ]),
                      if (asset.notes.isNotEmpty) ...[
                        const SizedBox(height: 14),
                        Text(asset.notes,
                            style: Theme.of(context).textTheme.bodySmall),
                      ],
                    ]),
              ),
              const SizedBox(height: 16),
              // Details
              _Section(
                  'Thông tin thiết bị',
                  [
                    _Row('Danh mục', asset.category),
                    _Row('Thương hiệu', asset.brand),
                    _Row('Model', asset.model),
                    if (asset.serialNumber.isNotEmpty)
                      _Row('Serial', asset.serialNumber),
                    _Row(
                        'Vị trí',
                        asset.location.isEmpty
                            ? 'Chưa cập nhật'
                            : asset.location),
                  ],
                  isDark,
                  context),
              const SizedBox(height: 12),
              _Section(
                  'Thông tin mua sắm',
                  [
                    if (asset.purchaseDate != null)
                      _Row('Ngày mua', fmt.format(asset.purchaseDate!)),
                    if (asset.purchasePrice > 0)
                      _Row('Giá mua',
                          '${NumberFormat('#,###', 'vi').format(asset.purchasePrice)} VNĐ'),
                    if (asset.warrantyExpiry != null)
                      _Row('Bảo hành đến', fmt.format(asset.warrantyExpiry!),
                          valueColor:
                              asset.warrantyExpiry!.isBefore(DateTime.now())
                                  ? AppColors.error
                                  : null),
                  ],
                  isDark,
                  context),
              const SizedBox(height: 12),
              _Section(
                  'Lịch sử bàn giao',
                  [
                    _Row(
                        'Ngày nhận',
                        asset.assignedAt != null
                            ? fmt.format(asset.assignedAt!)
                            : 'N/A'),
                  ],
                  isDark,
                  context),
              const SizedBox(height: 24),
            ]),
          );
        }
        return const Center(child: CircularProgressIndicator());
      }),
    );
  }

  Widget _Section(
      String title, List<Widget> rows, bool isDark, BuildContext ctx) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: Theme.of(ctx).textTheme.titleSmall),
        const SizedBox(height: 12),
        ...rows,
      ]),
    );
  }
}

class _Row extends StatelessWidget {
  final String label, value;
  final Color? valueColor;
  const _Row(this.label, this.value, {this.valueColor});
  @override
  Widget build(BuildContext ctx) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(children: [
        SizedBox(
            width: 120,
            child: Text('$label:', style: Theme.of(ctx).textTheme.bodySmall)),
        Expanded(
            child: Text(value,
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: valueColor ??
                        Theme.of(ctx).textTheme.bodyMedium?.color))),
      ]));
}
