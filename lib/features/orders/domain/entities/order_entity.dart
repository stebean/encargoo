enum OrderStatus { pendiente, lista, entregada, atrasada }

extension OrderStatusExtension on OrderStatus {
  String get label {
    switch (this) {
      case OrderStatus.pendiente: return 'Pendiente';
      case OrderStatus.lista: return 'Lista';
      case OrderStatus.entregada: return 'Entregada';
      case OrderStatus.atrasada: return 'Atrasada';
    }
  }

  static OrderStatus fromString(String s) {
    switch (s) {
      case 'lista': return OrderStatus.lista;
      case 'entregada': return OrderStatus.entregada;
      case 'atrasada': return OrderStatus.atrasada;
      default: return OrderStatus.pendiente;
    }
  }
}

class OrderPhotoEntity {
  final String id;
  final String orderId;
  final String photoUrl;
  final String description;
  final int sortOrder;
  final double price;

  const OrderPhotoEntity({
    required this.id,
    required this.orderId,
    required this.photoUrl,
    required this.description,
    required this.sortOrder,
    this.price = 0,
  });
}

class OrderEntity {
  final String id;
  final String workspaceId;
  final String? clientId;
  final String? clientName;
  final String? clientPhone;
  final String createdBy;
  final String? createdByName;
  final DateTime createdAt;
  final DateTime? deliveryDate;
  final OrderStatus status;
  final String? notes;
  final List<OrderPhotoEntity> photos;

  const OrderEntity({
    required this.id,
    required this.workspaceId,
    this.clientId,
    this.clientName,
    this.clientPhone,
    required this.createdBy,
    this.createdByName,
    required this.createdAt,
    this.deliveryDate,
    required this.status,
    this.notes,
    this.photos = const [],
  });

  /// Total price = sum of all photo prices
  double get totalPrice => photos.fold(0, (sum, p) => sum + p.price);

  bool get isOverdue {
    if (deliveryDate == null) return false;
    if (status == OrderStatus.entregada) return false;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return DateTime(deliveryDate!.year, deliveryDate!.month, deliveryDate!.day).isBefore(today);
  }

  bool get isUrgent {
    if (deliveryDate == null) return false;
    if (status == OrderStatus.entregada) return false;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(deliveryDate!.year, deliveryDate!.month, deliveryDate!.day);
    final diff = target.difference(today).inDays;
    return diff >= 0 && diff <= 3;
  }

  OrderEntity copyWith({
    String? id,
    String? workspaceId,
    String? clientId,
    String? clientName,
    String? clientPhone,
    String? createdBy,
    String? createdByName,
    DateTime? createdAt,
    DateTime? deliveryDate,
    bool clearDeliveryDate = false,
    OrderStatus? status,
    String? notes,
    List<OrderPhotoEntity>? photos,
  }) {
    return OrderEntity(
      id: id ?? this.id,
      workspaceId: workspaceId ?? this.workspaceId,
      clientId: clientId ?? this.clientId,
      clientName: clientName ?? this.clientName,
      clientPhone: clientPhone ?? this.clientPhone,
      createdBy: createdBy ?? this.createdBy,
      createdByName: createdByName ?? this.createdByName,
      createdAt: createdAt ?? this.createdAt,
      deliveryDate: clearDeliveryDate ? null : (deliveryDate ?? this.deliveryDate),
      status: status ?? this.status,
      notes: notes ?? this.notes,
      photos: photos ?? this.photos,
    );
  }
}
