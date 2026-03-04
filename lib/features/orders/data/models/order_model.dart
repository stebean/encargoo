import '../../domain/entities/order_entity.dart';

class OrderPhotoModel extends OrderPhotoEntity {
  const OrderPhotoModel({
    required super.id,
    required super.orderId,
    required super.photoUrl,
    required super.description,
    required super.sortOrder,
  });

  factory OrderPhotoModel.fromJson(Map<String, dynamic> json) {
    return OrderPhotoModel(
      id: json['id'] as String,
      orderId: json['order_id'] as String,
      photoUrl: json['photo_url'] as String,
      description: json['description'] as String? ?? '',
      sortOrder: json['sort_order'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'order_id': orderId,
      'photo_url': photoUrl,
      'description': description,
      'sort_order': sortOrder,
    };
  }
}

class OrderModel extends OrderEntity {
  const OrderModel({
    required super.id,
    required super.workspaceId,
    super.clientId,
    super.clientName,
    required super.createdBy,
    super.createdByName,
    required super.createdAt,
    super.deliveryDate,
    required super.status,
    super.notes,
    super.photos,
  });

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    final status = OrderStatusExtension.fromString(json['status'] as String? ?? 'pendiente');
    final photosJson = json['order_photos'] as List<dynamic>? ?? [];

    // Auto-compute atrasada based on delivery date
    final deliveryDate = json['delivery_date'] != null
        ? DateTime.parse(json['delivery_date'] as String)
        : null;
    OrderStatus effectiveStatus = status;
    if (status == OrderStatus.pendiente && deliveryDate != null) {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      if (DateTime(deliveryDate.year, deliveryDate.month, deliveryDate.day).isBefore(today)) {
        effectiveStatus = OrderStatus.atrasada;
      }
    }

    return OrderModel(
      id: json['id'] as String,
      workspaceId: json['workspace_id'] as String,
      clientId: json['client_id'] as String?,
      clientName: json['clients'] != null ? (json['clients'] as Map<String, dynamic>)['name'] as String? : null,
      createdBy: json['created_by'] as String,
      createdByName: json['profiles'] is Map ? (json['profiles'] as Map)['full_name'] as String? : (json['profiles'] is List && (json['profiles'] as List).isNotEmpty) ? ((json['profiles'] as List).first as Map)['full_name'] as String? : null,
      createdAt: DateTime.parse(json['created_at'] as String),
      deliveryDate: deliveryDate,
      status: effectiveStatus,
      notes: json['notes'] as String?,
      photos: photosJson.map((p) => OrderPhotoModel.fromJson(p as Map<String, dynamic>)).toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'workspace_id': workspaceId,
      'client_id': clientId,
      'created_by': createdBy,
      'delivery_date': deliveryDate?.toIso8601String().split('T')[0],
      'status': status.name,
      'notes': notes,
    };
  }
}
