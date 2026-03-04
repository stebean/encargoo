import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/datasources/workspace_remote_datasource.dart';
import '../../domain/entities/workspace_entity.dart';
import '../../../auth/presentation/notifiers/auth_notifier.dart';

final workspaceProvider = FutureProvider<WorkspaceEntity?>((ref) async {
  final user = ref.watch(authProvider).user;
  if (user?.workspaceId == null) return null;
  final ds = WorkspaceRemoteDataSource();
  return ds.getWorkspace(user!.workspaceId!);
});

final workspaceMembersProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final user = ref.watch(authProvider).user;
  if (user?.workspaceId == null) return [];
  final ds = WorkspaceRemoteDataSource();
  return ds.getMembers(user!.workspaceId!);
});
