import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supa;
import '../../../../core/constants/supabase_config.dart';
import '../../../../core/errors/app_exception.dart' as app_ex;
import '../../../workspace/data/datasources/workspace_remote_datasource.dart';
import '../../domain/entities/user_entity.dart';

// Auth State
class AuthState {
  final UserEntity? user;
  final bool loading;
  final String? error;

  const AuthState({this.user, this.loading = false, this.error});

  AuthState copyWith({UserEntity? user, bool? loading, String? error, bool clearError = false, bool clearUser = false}) {
    return AuthState(
      user: clearUser ? null : (user ?? this.user),
      loading: loading ?? this.loading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier() : super(const AuthState()) {
    _init();
  }

  final _client = SupabaseConfig.client;
  final _workspaceDataSource = WorkspaceRemoteDataSource();

  void _init() {
    final session = _client.auth.currentSession;
    if (session != null) {
      _loadProfile(session.user.id);
    }
    _client.auth.onAuthStateChange.listen((data) {
      if (data.session != null) {
        _loadProfile(data.session!.user.id);
      } else {
        state = const AuthState();
      }
    });
  }

  Future<void> _loadProfile(String userId) async {
    try {
      final profile = await _client.from('profiles').select().eq('id', userId).maybeSingle();
      if (profile != null) {
        state = state.copyWith(
          user: UserEntity(
            id: userId,
            email: _client.auth.currentUser?.email ?? '',
            fullName: profile['full_name'] as String? ?? '',
            workspaceId: profile['workspace_id'] as String?,
          ),
          loading: false,
        );
      } else {
        print('Profile not found for $userId');
        state = state.copyWith(loading: false, error: 'Perfil no configurado.');
      }
    } catch (e, st) {
      print('Load profile error: $e\n$st');
      state = state.copyWith(loading: false, error: 'Error al cargar perfil.');
    }
  }

  Future<void> login(String email, String password) async {
    state = state.copyWith(loading: true, clearError: true);
    try {
      await _client.auth.signInWithPassword(email: email, password: password);
    } on supa.AuthException catch (e) {
      print('AuthException login: $e');
      state = state.copyWith(loading: false, error: e.message);
    } catch (e, st) {
      print('Login error: $e\n$st');
      state = state.copyWith(loading: false, error: 'Error al iniciar sesión');
    }
  }

  Future<void> register(String email, String password, String fullName) async {
    state = state.copyWith(loading: true, clearError: true);
    try {
      final res = await _client.auth.signUp(
        email: email, 
        password: password,
        data: {'full_name': fullName, 'name': fullName},
      );
      if (res.user != null) {
        await _loadProfile(res.user!.id);
      }
    } on supa.AuthException catch (e) {
      print('AuthException register: $e');
      state = state.copyWith(loading: false, error: e.message);
    } catch (e, st) {
      print('Register error: $e\n$st');
      state = state.copyWith(loading: false, error: 'Error al registrarse');
    }
  }

  Future<bool> createWorkspace(String name) async {
    if (state.user == null) return false;
    try {
      final ws = await _workspaceDataSource.createWorkspace(state.user!.id, name);
      state = state.copyWith(user: UserEntity(
        id: state.user!.id,
        email: state.user!.email,
        fullName: state.user!.fullName,
        workspaceId: ws.id,
      ));
      return true;
    } on app_ex.WorkspaceException catch (e) {
      state = state.copyWith(error: e.message);
      return false;
    }
  }

  Future<bool> joinWorkspace(String code) async {
    if (state.user == null) return false;
    try {
      final ws = await _workspaceDataSource.joinWorkspace(state.user!.id, code);
      state = state.copyWith(user: UserEntity(
        id: state.user!.id,
        email: state.user!.email,
        fullName: state.user!.fullName,
        workspaceId: ws.id,
      ));
      return true;
    } on app_ex.WorkspaceException catch (e) {
      state = state.copyWith(error: e.message);
      return false;
    }
  }

  Future<void> signOut() async {
    await _client.auth.signOut();
    state = const AuthState();
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier();
});
