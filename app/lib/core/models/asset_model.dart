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

  factory AssetModel.fromJson(Map<String, dynamic> json) {
    return AssetModel(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      assetCode: json['assetCode']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      category: json['category']?.toString() ?? '',
      brand: json['brand']?.toString() ?? '',
      model: json['model']?.toString() ?? '',
      serialNumber: json['serialNumber']?.toString() ?? '',
      purchaseDate: json['purchaseDate'] != null ? DateTime.tryParse(json['purchaseDate'].toString())?.toLocal() : null,
      purchasePrice: (json['purchasePrice'] ?? 0).toDouble(),
      warrantyExpiry: json['warrantyExpiry'] != null ? DateTime.tryParse(json['warrantyExpiry'].toString())?.toLocal() : null,
      status: _parseAssetStatus(json['status']?.toString()),
      location: json['location']?.toString() ?? '',
      notes: json['notes']?.toString() ?? '',
      images: (json['images'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      assignedAt: json['assignedAt'] != null ? DateTime.tryParse(json['assignedAt'].toString())?.toLocal() : null,
    );
  }
}

AssetStatus _parseAssetStatus(String? status) {
  switch (status?.toUpperCase()) {
    case 'IN_USE':
    case 'IN USE':
      return AssetStatus.inUse;
    case 'MAINTENANCE':
      return AssetStatus.maintenance;
    case 'BROKEN':
      return AssetStatus.broken;
    case 'DISPOSED':
      return AssetStatus.disposed;
    case 'AVAILABLE':
    default:
      return AssetStatus.available;
  }
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
