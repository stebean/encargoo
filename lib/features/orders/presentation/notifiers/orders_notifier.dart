import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/datasources/order_remote_datasource.dart';
import '../../domain/entities/order_entity.dart';
import '../../../auth/presentation/notifiers/auth_notifier.dart';

class OrdersState {
  final List<OrderEntity> orders;
  final bool loading;
  final String? error;

  const OrdersState({this.orders = const [], this.loading = false, this.error});

  OrdersState copyWith({List<OrderEntity>? orders, bool? loading, String? error, bool clearError = false}) {
    return OrdersState(
      orders: orders ?? this.orders,
      loading: loading ?? this.loading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class OrdersNotifier extends StateNotifier<OrdersState> {
  final Ref _ref;
  final _dataSource = OrderRemoteDataSource();

  OrdersNotifier(this._ref) : super(const OrdersState());

  String? get _workspaceId => _ref.read(authProvider).user?.workspaceId;
  String? get _userId => _ref.read(authProvider).user?.id;

  Future<void> loadOrders() async {
    final wid = _workspaceId;
    if (wid == null) return;
    state = state.copyWith(loading: true, clearError: true);
    try {
      final orders = await _dataSource.getOrders(wid);
      state = state.copyWith(orders: orders, loading: false);
    } catch (e) {
      state = state.copyWith(loading: false, error: e.toString());
    }
  }

  Future<bool> createOrder({
    String? clientId,
    DateTime? deliveryDate,
    String? notes,
    List<(File, String)> photos = const [],
  }) async {
    final wid = _workspaceId;
    final uid = _userId;
    if (wid == null || uid == null) return false;
    state = state.copyWith(loading: true, clearError: true);
    try {
      final order = await _dataSource.createOrder({
        'workspace_id': wid,
        'client_id': clientId,
        'created_by': uid,
        'delivery_date': deliveryDate?.toIso8601String().split('T')[0],
        'status': 'pendiente',
        'notes': notes,
      });
      // Upload photos
      for (final (file, desc) in photos) {
        final url = await _dataSource.uploadPhoto(file, order.id);
        await _dataSource.addPhoto({
          'order_id': order.id,
          'photo_url': url,
          'description': desc,
          'sort_order': photos.indexOf((file, desc)),
        });
      }
      await loadOrders();
      return true;
    } catch (e) {
      state = state.copyWith(loading: false, error: e.toString());
      return false;
    }
  }

  Future<bool> updateOrder(String id, {
    String? clientId,
    DateTime? deliveryDate,
    bool clearDeliveryDate = false,
    OrderStatus? status,
    String? notes,
  }) async {
    state = state.copyWith(loading: true, clearError: true);
    try {
      final data = <String, dynamic>{};
      if (clientId != null) data['client_id'] = clientId;
      if (clearDeliveryDate) {
        data['delivery_date'] = null;
      } else if (deliveryDate != null) {
        data['delivery_date'] = deliveryDate.toIso8601String().split('T')[0];
      }
      if (status != null) data['status'] = status.name;
      if (notes != null) data['notes'] = notes;
      await _dataSource.updateOrder(id, data);
      await loadOrders();
      return true;
    } catch (e) {
      state = state.copyWith(loading: false, error: e.toString());
      return false;
    }
  }

  Future<bool> addPhotoToOrder(String orderId, File file, String description) async {
    try {
      final url = await _dataSource.uploadPhoto(file, orderId);
      final existingOrder = state.orders.firstWhere((o) => o.id == orderId);
      await _dataSource.addPhoto({
        'order_id': orderId,
        'photo_url': url,
        'description': description,
        'sort_order': existingOrder.photos.length,
      });
      await loadOrders();
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  Future<bool> deletePhoto(String photoId, String photoUrl) async {
    try {
      await _dataSource.deletePhoto(photoId, photoUrl);
      await loadOrders();
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  Future<bool> updatePhotoDescription(String photoId, String description) async {
    try {
      await _dataSource.updatePhotoDescription(photoId, description);
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  Future<bool> deleteOrder(String id) async {
    try {
      final existingOrder = state.orders.where((o) => o.id == id).firstOrNull;
      final photoUrls = existingOrder?.photos.map((p) => p.photoUrl).toList() ?? [];

      await _dataSource.deleteOrder(id, photoUrls);
      await loadOrders();
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  List<OrderEntity> get upcoming {
    return state.orders
        .where((o) => o.status != OrderStatus.entregada)
        .where((o) => o.deliveryDate != null)
        .toList()
      ..sort((a, b) => a.deliveryDate!.compareTo(b.deliveryDate!));
  }

  List<OrderEntity> get overdue {
    return state.orders.where((o) => o.isOverdue).toList();
  }

  List<OrderEntity> get urgent {
    return state.orders.where((o) => o.isUrgent && !o.isOverdue).toList();
  }

  List<DateTime> get deliveryDates {
    return state.orders
        .where((o) => o.deliveryDate != null && o.status != OrderStatus.entregada)
        .map((o) => o.deliveryDate!)
        .toSet()
        .toList();
  }

  List<OrderEntity> search(String query) {
    if (query.isEmpty) return state.orders;
    final q = query.toLowerCase();
    return state.orders.where((o) {
      final matchesClient = o.clientName?.toLowerCase().contains(q) ?? false;
      final matchesPhoto = o.photos.any((p) => p.description.toLowerCase().contains(q));
      return matchesClient || matchesPhoto;
    }).toList();
  }
}

final ordersProvider = StateNotifierProvider<OrdersNotifier, OrdersState>((ref) {
  return OrdersNotifier(ref);
});
