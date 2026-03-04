import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:encargoo/features/auth/presentation/notifiers/auth_notifier.dart';
import 'package:encargoo/features/auth/presentation/pages/login_page.dart';
import 'package:encargoo/features/auth/presentation/pages/register_page.dart';
import 'package:encargoo/features/workspace/presentation/pages/workspace_setup_page.dart';
import 'package:encargoo/features/home/presentation/pages/home_page.dart';
import 'package:encargoo/features/orders/presentation/pages/orders_page.dart';
import 'package:encargoo/features/orders/presentation/pages/order_form_page.dart';
import 'package:encargoo/features/orders/presentation/pages/order_detail_page.dart';
import 'package:encargoo/features/clients/presentation/pages/clients_page.dart';
import 'package:encargoo/features/clients/presentation/pages/client_form_page.dart';
import 'package:encargoo/features/settings/presentation/pages/settings_page.dart';
import 'package:encargoo/shared/widgets/app_shell.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final auth = ref.watch(authProvider);

  return GoRouter(
    initialLocation: '/inicio',
    redirect: (context, state) {
      final isLoggedIn = auth.user != null;
      final hasWorkspace = auth.user?.workspaceId != null;
      final path = state.matchedLocation;

      if (!isLoggedIn) {
        final authPaths = ['/login', '/register'];
        if (!authPaths.any((p) => path.startsWith(p))) return '/login';
      } else if (!hasWorkspace) {
        if (path != '/workspace-setup') return '/workspace-setup';
      } else {
        if (path == '/login' || path == '/register' || path == '/workspace-setup') {
          return '/inicio';
        }
      }
      return null;
    },
    routes: [
      GoRoute(path: '/login', builder: (_, __) => const LoginPage()),
      GoRoute(path: '/register', builder: (_, __) => const RegisterPage()),
      GoRoute(path: '/workspace-setup', builder: (_, __) => const WorkspaceSetupPage()),
      ShellRoute(
        builder: (context, state, child) => AppShell(child: child, location: state.matchedLocation),
        routes: [
          GoRoute(path: '/inicio', builder: (_, __) => const HomePage()),
          GoRoute(
            path: '/encargos',
            builder: (_, __) => const OrdersPage(),
            routes: [
              GoRoute(path: 'nuevo', builder: (_, __) => const OrderFormPage()),
              GoRoute(
                path: ':id',
                builder: (_, s) => OrderDetailPage(id: s.pathParameters['id']!),
                routes: [
                  GoRoute(
                    path: 'editar',
                    builder: (_, s) => OrderFormPage(orderId: s.pathParameters['id']),
                  ),
                ],
              ),
            ],
          ),
          GoRoute(
            path: '/clientes',
            builder: (_, __) => const ClientsPage(),
            routes: [
              GoRoute(path: 'nuevo', builder: (_, __) => const ClientFormPage()),
              GoRoute(
                path: ':id/editar',
                builder: (_, s) => ClientFormPage(clientId: s.pathParameters['id']),
              ),
            ],
          ),
          GoRoute(path: '/ajustes', builder: (_, __) => const SettingsPage()),
        ],
      ),
    ],
  );
});
