// ── Asset Model ───────────────────────────────────────────────
class AssetModel {
  final String id;
  final String assetCode;
  final String name;
  final String category;
  final String brand;
  final String model;
  final String serialNumber;
  final DateTime? purchaseDate;
  final double purchasePrice;
  final DateTime? warrantyExpiry;
  final AssetStatus status;
  final String location;
  final String notes;
  final List<String> images;
  final DateTime? assignedAt;

  const AssetModel({
    required this.id,
    required this.assetCode,
    required this.name,
    required this.category,
    this.brand = '',
    this.model = '',
    this.serialNumber = '',
    this.purchaseDate,
    this.purchasePrice = 0,
    this.warrantyExpiry,
    required this.status,
    this.location = '',
    this.notes = '',
    this.images = const [],
    this.assignedAt,
  });
}

enum AssetStatus { available, inUse, maintenance, broken, disposed }

extension AssetStatusExt on AssetStatus {
  String get label {
    switch (this) {
      case AssetStatus.available: return 'Có sẵn';
      case AssetStatus.inUse: return 'Đang sử dụng';
      case AssetStatus.maintenance: return 'Đang bảo trì';
      case AssetStatus.broken: return 'Hỏng hóc';
      case AssetStatus.disposed: return 'Đã thanh lý';
    }
  }
}
