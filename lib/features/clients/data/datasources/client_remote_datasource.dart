import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/constants/supabase_config.dart';
import '../../../../core/errors/app_exception.dart';
import '../models/client_model.dart';

class ClientRemoteDataSource {
  final SupabaseClient _client = SupabaseConfig.client;

  Future<List<ClientModel>> getClients(String workspaceId) async {
    try {
      final response = await _client
          .from('clients')
          .select()
          .eq('workspace_id', workspaceId)
          .order('name');
      return (response as List).map((e) => ClientModel.fromJson(e)).toList();
    } catch (e) {
      throw DatabaseException('Error al obtener clientes: $e');
    }
  }

  Future<ClientModel> createClient(Map<String, dynamic> data) async {
    try {
      final response = await _client.from('clients').insert(data).select().single();
      return ClientModel.fromJson(response);
    } catch (e) {
      throw DatabaseException('Error al crear cliente: $e');
    }
  }

  Future<ClientModel> updateClient(String id, Map<String, dynamic> data) async {
    try {
      final response = await _client.from('clients').update(data).eq('id', id).select().single();
      return ClientModel.fromJson(response);
    } catch (e) {
      throw DatabaseException('Error al actualizar cliente: $e');
    }
  }

  Future<void> deleteClient(String id) async {
    try {
      await _client.from('clients').delete().eq('id', id);
    } catch (e) {
      throw DatabaseException('Error al eliminar cliente: $e');
    }
  }
}
