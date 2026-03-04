import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../auth/presentation/notifiers/auth_notifier.dart';
import '../../../workspace/presentation/notifiers/workspace_provider.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).user;
    final workspace = ref.watch(workspaceProvider);
    final members = ref.watch(workspaceMembersProvider);

    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(title: const Text('Ajustes', style: AppTextStyles.headlineMedium)),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // User info
          const _SectionLabel('Mi cuenta'),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: AppColors.parchment, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.borderLight)),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: const BoxDecoration(color: AppColors.borderLight, shape: BoxShape.circle),
                  child: Center(child: Text((user?.fullName ?? '?')[0].toUpperCase(), style: AppTextStyles.headlineLarge.copyWith(color: AppColors.accent))),
                ),
                const SizedBox(width: 14),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(user?.fullName ?? '—', style: AppTextStyles.headlineSmall),
                    Text(user?.email ?? '—', style: AppTextStyles.bodySmall),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          // Workspace section
          const _SectionLabel('Espacio de trabajo'),
          workspace.when(
            data: (ws) => ws == null
                ? Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: AppColors.parchment, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.borderLight)),
                    child: Text('Sin workspace', style: AppTextStyles.bodySmall.copyWith(fontStyle: FontStyle.italic)),
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(color: AppColors.parchment, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.borderLight)),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(children: [
                              const Icon(Icons.workspaces_outlined, size: 16, color: AppColors.accent),
                              const SizedBox(width: 8),
                              Text(ws.name, style: AppTextStyles.headlineSmall.copyWith(fontSize: 16)),
                            ]),
                            const SizedBox(height: 14),
                            const Text('Código de acceso', style: AppTextStyles.labelMedium),
                            const SizedBox(height: 6),
                            GestureDetector(
                              onTap: () {
                                Clipboard.setData(ClipboardData(text: ws.accessCode));
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: const Text('Código copiado'), duration: const Duration(seconds: 2), behavior: SnackBarBehavior.floating, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                                );
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                                decoration: BoxDecoration(
                                  color: AppColors.accentDeep,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(ws.accessCode, style: AppTextStyles.displayMedium.copyWith(color: AppColors.white, letterSpacing: 6, fontSize: 22)),
                                    const SizedBox(width: 12),
                                    const Icon(Icons.copy_rounded, color: AppColors.white, size: 18),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text('Comparte este código para que otros se unan.', style: AppTextStyles.caption.copyWith(fontStyle: FontStyle.italic)),
                          ],
                        ),
                      ),
                    ],
                  ),
            loading: () => const Center(child: CircularProgressIndicator(color: AppColors.accent)),
            error: (_, __) => const SizedBox(),
          ),
          const SizedBox(height: 24),
          // Members
          const _SectionLabel('Miembros'),
          members.when(
            data: (list) => Column(
              children: list.map((m) => Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(color: AppColors.parchment, borderRadius: BorderRadius.circular(10), border: Border.all(color: AppColors.borderLight)),
                child: Row(children: [
                  Container(
                    width: 32, height: 32,
                    decoration: const BoxDecoration(color: AppColors.borderLight, shape: BoxShape.circle),
                    child: Center(child: Text((m['full_name'] as String? ?? '?')[0].toUpperCase(), style: AppTextStyles.labelLarge.copyWith(color: AppColors.accent))),
                  ),
                  const SizedBox(width: 12),
                  Text(m['full_name'] as String? ?? 'Usuario', style: AppTextStyles.bodyMedium),
                  if (m['id'] == ref.read(authProvider).user?.id) ...[
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(color: AppColors.pendienteLight, borderRadius: BorderRadius.circular(10)),
                      child: Text('Tú', style: AppTextStyles.caption.copyWith(color: AppColors.accent, fontWeight: FontWeight.w700)),
                    ),
                  ],
                ]),
              )).toList(),
            ),
            loading: () => const SizedBox(),
            error: (_, __) => const SizedBox(),
          ),
          const SizedBox(height: 32),
          // Sign out
          OutlinedButton.icon(
            onPressed: () => ref.read(authProvider.notifier).signOut(),
            icon: const Icon(Icons.logout_rounded, size: 18, color: AppColors.danger),
            label: const Text('Cerrar sesión'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.danger,
              side: const BorderSide(color: AppColors.danger),
            ),
          ),
          const SizedBox(height: 24),
          Center(child: Text('Encargoo v1.0.0', style: AppTextStyles.caption.copyWith(fontStyle: FontStyle.italic))),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel(this.label);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(label, style: AppTextStyles.labelMedium.copyWith(letterSpacing: 1, fontSize: 11)),
    );
  }
}
