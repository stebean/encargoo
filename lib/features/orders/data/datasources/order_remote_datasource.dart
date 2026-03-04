import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/constants/supabase_config.dart';
import '../../../../core/errors/app_exception.dart' as app_ex;
import '../models/order_model.dart';

class OrderRemoteDataSource {
  final SupabaseClient _client = SupabaseConfig.client;

  Future<List<OrderModel>> getOrders(String workspaceId) async {
    try {
      final response = await _client
          .from('orders')
          .select('*, clients(name), profiles(full_name), order_photos(*)')
          .eq('workspace_id', workspaceId)
          .order('created_at', ascending: false);
      
      if ((response as List).isNotEmpty) {
        print('DEBUG RESPONSE: ${response.first['profiles']}');
      }
      
      return response.map((e) => OrderModel.fromJson(e)).toList();
    } catch (e) {
      throw app_ex.DatabaseException('Error al obtener los encargos: $e');
    }
  }

  Future<OrderModel> getOrderById(String id) async {
    try {
      final response = await _client
          .from('orders')
          .select('*, clients(name), profiles(full_name), order_photos(*)')
          .eq('id', id)
          .single();
      return OrderModel.fromJson(response);
    } catch (e) {
      throw app_ex.DatabaseException('Error al obtener el encargo: $e');
    }
  }

  Future<OrderModel> createOrder(Map<String, dynamic> data) async {
    try {
      final response = await _client
          .from('orders')
          .insert(data)
          .select('*, clients(name), profiles(full_name), order_photos(*)')
          .single();
      return OrderModel.fromJson(response);
    } catch (e) {
      throw app_ex.DatabaseException('Error al crear el encargo: $e');
    }
  }

  Future<OrderModel> updateOrder(String id, Map<String, dynamic> data) async {
    try {
      final response = await _client
          .from('orders')
          .update(data)
          .eq('id', id)
          .select('*, clients(name), profiles(full_name), order_photos(*)')
          .single();
      return OrderModel.fromJson(response);
    } catch (e) {
      throw app_ex.DatabaseException('Error al actualizar el encargo: $e');
    }
  }

  Future<void> deleteOrder(String id, List<String> photoUrls) async {
    try {
      // 1. Get all photos for this order to delete them from storage first
      for (final url in photoUrls) {
        // Attempt to delete photo from storage (we ignore errors here to allow the order to still be deleted)
        try {
          final uri = Uri.parse(url);
          final fileName = uri.pathSegments.last;
          await _client.storage.from('order-photos').remove([fileName]);
        } catch (_) {}
      }

      // 2. Delete the order (cascade will delete the database row corresponding to order_photos)
      final response = await _client.from('orders').delete().eq('id', id).select();
      if ((response as List).isEmpty) {
        throw app_ex.DatabaseException('No se pudo eliminar el encargo (RLS o no encontrado).');
      }
    } catch (e) {
      throw app_ex.DatabaseException('Error al eliminar el encargo: $e');
    }
  }

  Future<String> uploadPhoto(File file, String orderId) async {
    try {
      final fileName = '${orderId}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      await _client.storage.from('order-photos').upload(fileName, file);
      return _client.storage.from('order-photos').getPublicUrl(fileName);
    } catch (e) {
      throw app_ex.StorageException('Error al subir la foto: $e');
    }
  }

  Future<void> addPhoto(Map<String, dynamic> data) async {
    try {
      await _client.from('order_photos').insert(data);
    } catch (e) {
      throw app_ex.DatabaseException('Error al guardar la foto: $e');
    }
  }

  Future<void> deletePhoto(String photoId, String photoUrl) async {
    try {
      final uri = Uri.parse(photoUrl);
      final fileName = uri.pathSegments.last;
      await _client.storage.from('order-photos').remove([fileName]);
      await _client.from('order_photos').delete().eq('id', photoId);
    } catch (e) {
      throw app_ex.DatabaseException('Error al eliminar la foto: $e');
    }
  }
}
