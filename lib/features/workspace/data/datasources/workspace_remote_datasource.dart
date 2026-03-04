import 'dart:math';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/constants/supabase_config.dart';
import '../../../../core/errors/app_exception.dart';
import '../models/workspace_model.dart';

class WorkspaceRemoteDataSource {
  final SupabaseClient _client = SupabaseConfig.client;

  String _generateCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final rand = Random.secure();
    return List.generate(6, (_) => chars[rand.nextInt(chars.length)]).join();
  }

  Future<WorkspaceModel> createWorkspace(String userId, String name) async {
    try {
      final code = _generateCode();
      final workspace = await _client
          .from('workspaces')
          .insert({'name': name, 'access_code': code})
          .select()
          .single();
      return WorkspaceModel.fromJson(workspace);
    } catch (e) {
      throw WorkspaceException('Error al crear el workspace: $e');
    }
  }

  Future<WorkspaceModel> joinWorkspace(String userId, String code) async {
    try {
      final response = await _client
          .from('workspaces')
          .select()
          .eq('access_code', code.toUpperCase())
          .maybeSingle();
      if (response == null) {
        throw const WorkspaceException('Código de acceso no encontrado. Verifica que sea correcto.');
      }
      final ws = WorkspaceModel.fromJson(response);
      // Update workspace_id only (role column requires SQL migration)
      await _client
          .from('profiles')
          .update({'workspace_id': ws.id})
          .eq('id', userId);
      return ws;
    } catch (e) {
      if (e is WorkspaceException) rethrow;
      throw WorkspaceException('Error al unirse al workspace: $e');
    }
  }

  Future<void> leaveWorkspace(String userId) async {
    try {
      await _client
          .from('profiles')
          .update({'workspace_id': null})
          .eq('id', userId);
    } catch (e) {
      throw WorkspaceException('Error al salir del workspace: $e');
    }
  }

  Future<WorkspaceModel?> getWorkspace(String workspaceId) async {
    try {
      final response = await _client
          .from('workspaces')
          .select()
          .eq('id', workspaceId)
          .maybeSingle();
      return response != null ? WorkspaceModel.fromJson(response) : null;
    } catch (e) {
      throw WorkspaceException('Error al obtener workspace: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getMembers(String workspaceId) async {
    try {
      final response = await _client
          .from('profiles')
          .select('id, full_name, role')
          .eq('workspace_id', workspaceId);
      return List<Map<String, dynamic>>.from(response as List);
    } catch (e) {
      // Fallback without role if column not yet migrated
      try {
        final response = await _client
            .from('profiles')
            .select('id, full_name')
            .eq('workspace_id', workspaceId);
        return List<Map<String, dynamic>>.from(response as List);
      } catch (_) {
        throw WorkspaceException('Error al obtener miembros: $e');
      }
    }
  }
}

