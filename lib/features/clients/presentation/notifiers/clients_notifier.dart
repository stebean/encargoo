import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/datasources/client_remote_datasource.dart';
import '../../domain/entities/client_entity.dart';
import '../../../auth/presentation/notifiers/auth_notifier.dart';

class ClientsState {
  final List<ClientEntity> clients;
  final bool loading;
  final String? error;

  const ClientsState({this.clients = const [], this.loading = false, this.error});

  ClientsState copyWith({List<ClientEntity>? clients, bool? loading, String? error, bool clearError = false}) {
    return ClientsState(
      clients: clients ?? this.clients,
      loading: loading ?? this.loading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class ClientsNotifier extends StateNotifier<ClientsState> {
  final Ref _ref;
  final _dataSource = ClientRemoteDataSource();

  ClientsNotifier(this._ref) : super(const ClientsState());

  String? get _workspaceId => _ref.read(authProvider).user?.workspaceId;

  Future<void> loadClients() async {
    final wid = _workspaceId;
    if (wid == null) return;
    state = state.copyWith(loading: true, clearError: true);
    try {
      final clients = await _dataSource.getClients(wid);
      state = state.copyWith(clients: clients, loading: false);
    } catch (e) {
      state = state.copyWith(loading: false, error: e.toString());
    }
  }

  Future<bool> createClient({required String name, String? phone, String? notes}) async {
    final wid = _workspaceId;
    if (wid == null) return false;
    try {
      await _dataSource.createClient({'workspace_id': wid, 'name': name, 'phone': phone, 'notes': notes});
      await loadClients();
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  Future<bool> updateClient(String id, {String? name, String? phone, String? notes}) async {
    try {
      final data = <String, dynamic>{};
      if (name != null) data['name'] = name;
      if (phone != null) data['phone'] = phone;
      if (notes != null) data['notes'] = notes;
      await _dataSource.updateClient(id, data);
      await loadClients();
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  Future<bool> deleteClient(String id) async {
    try {
      await _dataSource.deleteClient(id);
      state = state.copyWith(clients: state.clients.where((c) => c.id != id).toList());
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  List<ClientEntity> search(String query) {
    if (query.isEmpty) return state.clients;
    final q = query.toLowerCase();
    return state.clients.where((c) => c.name.toLowerCase().contains(q)).toList();
  }
}

final clientsProvider = StateNotifierProvider<ClientsNotifier, ClientsState>((ref) {
  return ClientsNotifier(ref);
});
