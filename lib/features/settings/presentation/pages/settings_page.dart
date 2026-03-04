import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../auth/presentation/notifiers/auth_notifier.dart';
import '../../../workspace/presentation/notifiers/workspace_provider.dart';
import '../notifiers/message_template_provider.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final user = authState.user;
    final workspace = ref.watch(workspaceProvider);
    final members = ref.watch(workspaceMembersProvider);
    final isOwner = user?.isOwner ?? false;

    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(title: const Text('Ajustes', style: AppTextStyles.headlineMedium)),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // ── Mi cuenta ──────────────────────────────────────────────────────
          const _SectionLabel('MI CUENTA'),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.parchment,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.borderLight),
            ),
            child: Row(
              children: [
                Container(
                  width: 48, height: 48,
                  decoration: const BoxDecoration(color: AppColors.borderLight, shape: BoxShape.circle),
                  child: Center(child: Text(
                    (user?.fullName ?? '?')[0].toUpperCase(),
                    style: AppTextStyles.headlineLarge.copyWith(color: AppColors.accent),
                  )),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(user?.fullName ?? '—', style: AppTextStyles.headlineSmall),
                      Text(user?.email ?? '—', style: AppTextStyles.bodySmall),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: isOwner ? AppColors.accentDeep : AppColors.borderLight,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    isOwner ? 'Dueño' : 'Miembro',
                    style: AppTextStyles.caption.copyWith(
                      color: isOwner ? AppColors.white : AppColors.inkFaint,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // ── Espacio de trabajo ─────────────────────────────────────────────
          const _SectionLabel('ESPACIO DE TRABAJO'),
          workspace.when(
            data: (ws) => ws == null
                ? _buildNoWorkspace(context, ref)
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Workspace info card
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.parchment,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppColors.borderLight),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(children: [
                              const Icon(Icons.workspaces_outlined, size: 16, color: AppColors.accent),
                              const SizedBox(width: 8),
                              Expanded(child: Text(ws.name, style: AppTextStyles.headlineSmall.copyWith(fontSize: 16))),
                            ]),
                            const SizedBox(height: 14),
                            const Text('Código de acceso', style: AppTextStyles.labelMedium),
                            const SizedBox(height: 6),
                            GestureDetector(
                              onTap: () {
                                Clipboard.setData(ClipboardData(text: ws.accessCode));
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: const Text('Código copiado'),
                                    duration: const Duration(seconds: 2),
                                    behavior: SnackBarBehavior.floating,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  ),
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
                                    Text(
                                      ws.accessCode,
                                      style: AppTextStyles.displayMedium.copyWith(
                                        color: AppColors.white, letterSpacing: 6, fontSize: 22,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    const Icon(Icons.copy_rounded, color: AppColors.white, size: 18),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Comparte este código para que otros se unan.',
                              style: AppTextStyles.caption.copyWith(fontStyle: FontStyle.italic),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Workspace actions
                      // Create new workspace (always available)
                      _ActionTile(
                        icon: Icons.add_circle_outline_rounded,
                        label: 'Crear nuevo espacio de trabajo',
                        onTap: () => _showCreateNewWorkspace(context, ref),
                      ),
                      const SizedBox(height: 8),
                      // Leave workspace
                      _ActionTile(
                        icon: Icons.exit_to_app_rounded,
                        label: isOwner
                            ? 'Salir del espacio de trabajo'
                            : 'Salir del espacio de trabajo',
                        color: AppColors.danger,
                        onTap: () => _confirmLeave(context, ref, isOwner),
                      ),
                    ],
                  ),
            loading: () => const Center(child: CircularProgressIndicator(color: AppColors.accent)),
            error: (_, __) => const SizedBox(),
          ),
          const SizedBox(height: 24),

          // ── Miembros ───────────────────────────────────────────────────────
          const _SectionLabel('MIEMBROS'),
          members.when(
            data: (list) => Column(
              children: list.map((m) {
                final isMe = m['id'] == user?.id;
                final memberRole = m['role'] as String? ?? 'member';
                final isOwnerMember = memberRole == 'owner';
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: AppColors.parchment,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.borderLight),
                  ),
                  child: Row(children: [
                    Container(
                      width: 32, height: 32,
                      decoration: const BoxDecoration(color: AppColors.borderLight, shape: BoxShape.circle),
                      child: Center(child: Text(
                        (m['full_name'] as String? ?? '?')[0].toUpperCase(),
                        style: AppTextStyles.labelLarge.copyWith(color: AppColors.accent),
                      )),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(m['full_name'] as String? ?? 'Usuario', style: AppTextStyles.bodyMedium),
                    ),
                    if (isOwnerMember)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.accentDeep.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text('Dueño', style: AppTextStyles.caption.copyWith(color: AppColors.accent, fontWeight: FontWeight.w700)),
                      )
                    else if (isMe)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(color: AppColors.pendienteLight, borderRadius: BorderRadius.circular(10)),
                        child: Text('Tú', style: AppTextStyles.caption.copyWith(color: AppColors.accent, fontWeight: FontWeight.w700)),
                      ),
                  ]),
                );
              }).toList(),
            ),
            loading: () => const SizedBox(),
            error: (_, __) => const SizedBox(),
          ),

          // ── Mensaje de WhatsApp ──────────────────────────────────────────
          const SizedBox(height: 24),
          const _SectionLabel('MENSAJE DE WHATSAPP'),
          _MessageTemplateEditor(),
          const SizedBox(height: 32),
          // ── Cerrar sesión ─────────────────────────────────────────────────
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

  Widget _buildNoWorkspace(BuildContext context, WidgetRef ref) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.parchment,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.borderLight),
          ),
          child: Text('Sin espacio de trabajo', style: AppTextStyles.bodySmall.copyWith(fontStyle: FontStyle.italic)),
        ),
        const SizedBox(height: 12),
        _ActionTile(
          icon: Icons.add_circle_outline_rounded,
          label: 'Crear espacio de trabajo',
          onTap: () => _showWorkspaceSetup(context),
        ),
      ],
    );
  }

  void _showWorkspaceSetup(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.cream,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => const _WorkspaceSetupSheet(),
    );
  }

  void _showCreateNewWorkspace(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.cream,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => const _WorkspaceSetupSheet(),
    );
  }

  Future<void> _confirmLeave(BuildContext context, WidgetRef ref, bool isOwner) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.cream,
        title: const Text('Salir del espacio de trabajo', style: AppTextStyles.headlineSmall),
        content: Text(
          isOwner
              ? 'Eres el dueño. ¿Seguro que quieres salir? Otros miembros seguirán teniendo acceso al workspace.\n\nPuedes volver a unirte con el código de acceso.'
              : '¿Seguro que quieres salir de este espacio de trabajo? Podrás unirte de nuevo con el código de acceso.',
          style: AppTextStyles.bodyMedium,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Salir', style: AppTextStyles.labelLarge.copyWith(color: AppColors.danger)),
          ),
        ],
      ),
    );
    if (ok == true && context.mounted) {
      await ref.read(authProvider.notifier).leaveWorkspace();
    }
  }
}

// ── Action tile ──────────────────────────────────────────────────────────────
class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;

  const _ActionTile({required this.icon, required this.label, required this.onTap, this.color});

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppColors.ink;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.parchment,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color != null ? color!.withValues(alpha: 0.3) : AppColors.borderLight),
        ),
        child: Row(children: [
          Icon(icon, size: 18, color: c),
          const SizedBox(width: 12),
          Text(label, style: AppTextStyles.bodyMedium.copyWith(color: c)),
          const Spacer(),
          Icon(Icons.chevron_right_rounded, size: 18, color: c.withValues(alpha: 0.5)),
        ]),
      ),
    );
  }
}

// ── Section label ────────────────────────────────────────────────────────────
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

// ── Workspace setup bottom sheet ─────────────────────────────────────────────
class _WorkspaceSetupSheet extends ConsumerStatefulWidget {
  const _WorkspaceSetupSheet();

  @override
  ConsumerState<_WorkspaceSetupSheet> createState() => _WorkspaceSetupSheetState();
}

class _WorkspaceSetupSheetState extends ConsumerState<_WorkspaceSetupSheet> {
  final _nameCtrl = TextEditingController();
  final _codeCtrl = TextEditingController();
  bool _isCreating = true;
  final _form = GlobalKey<FormState>();

  @override
  void dispose() {
    _nameCtrl.dispose();
    _codeCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_form.currentState?.validate() ?? false)) return;
    final notifier = ref.read(authProvider.notifier);
    bool ok;
    if (_isCreating) {
      ok = await notifier.createWorkspace(_nameCtrl.text.trim());
    } else {
      ok = await notifier.joinWorkspace(_codeCtrl.text.trim());
    }
    if (ok && mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);
    final bottom = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(24, 24, 24, bottom + 24),
      child: Form(
        key: _form,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.borderLight, borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 20),
            const Text('Espacio de trabajo', style: AppTextStyles.headlineSmall),
            const SizedBox(height: 16),
            // Toggle
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: AppColors.borderLight.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  _SheetTab(label: 'Crear nuevo', selected: _isCreating, onTap: () => setState(() => _isCreating = true)),
                  _SheetTab(label: 'Unirse con código', selected: !_isCreating, onTap: () => setState(() => _isCreating = false)),
                ],
              ),
            ),
            const SizedBox(height: 20),
            if (_isCreating)
              TextFormField(
                controller: _nameCtrl,
                decoration: const InputDecoration(
                  labelText: 'Nombre del espacio de trabajo',
                  hintText: 'Ej. Taller de Costura',
                  prefixIcon: Icon(Icons.workspaces_outlined, size: 18),
                ),
                validator: (v) => (v?.isEmpty ?? true) ? 'Escribe un nombre' : null,
              )
            else
              TextFormField(
                controller: _codeCtrl,
                textCapitalization: TextCapitalization.characters,
                maxLength: 6,
                decoration: const InputDecoration(
                  labelText: 'Código de acceso',
                  hintText: 'A1B2C3',
                  prefixIcon: Icon(Icons.vpn_key_outlined, size: 18),
                  counterText: '',
                ),
                style: const TextStyle(letterSpacing: 4, fontWeight: FontWeight.w700, fontSize: 18),
                validator: (v) => ((v?.length ?? 0) < 6) ? 'Código de 6 caracteres' : null,
              ),
            if (auth.error != null) ...[ 
              const SizedBox(height: 10),
              Text(auth.error!, style: AppTextStyles.bodySmall.copyWith(color: AppColors.danger)),
            ],
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: auth.loading ? null : _submit,
                child: auth.loading
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.white))
                    : Text(_isCreating ? 'Crear espacio de trabajo' : 'Unirme'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SheetTab extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _SheetTab({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: selected ? AppColors.accent : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: AppTextStyles.labelMedium.copyWith(color: selected ? AppColors.white : AppColors.inkFaint, fontSize: 12),
          ),
        ),
      ),
    );
  }
}

// ── WhatsApp message template editor ─────────────────────────────────────────
class _MessageTemplateEditor extends ConsumerStatefulWidget {
  const _MessageTemplateEditor();

  @override
  ConsumerState<_MessageTemplateEditor> createState() => _MessageTemplateEditorState();
}

class _MessageTemplateEditorState extends ConsumerState<_MessageTemplateEditor> {
  late TextEditingController _ctrl;
  bool _dirty = false;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController();
    // Load initial value from provider
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final template = ref.read(messageTemplateProvider).value ?? defaultMessageTemplate;
      _ctrl.text = template;
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Watch to initialize when ready
    ref.watch(messageTemplateProvider);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.parchment,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Plantilla del mensaje de encargo listo',
            style: AppTextStyles.labelMedium,
          ),
          const SizedBox(height: 4),
          Text(
            'Usa {nombre} para el nombre del cliente y \${total} para el precio total.',
            style: AppTextStyles.caption.copyWith(fontStyle: FontStyle.italic, color: AppColors.inkFaint),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _ctrl,
            maxLines: 5,
            onChanged: (_) => setState(() => _dirty = true),
            decoration: InputDecoration(
              hintText: defaultMessageTemplate,
              filled: true,
              fillColor: AppColors.cream,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: AppColors.borderLight)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: AppColors.borderLight)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.accent)),
              contentPadding: const EdgeInsets.all(12),
            ),
            style: AppTextStyles.bodySmall,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () async {
                    await ref.read(messageTemplateProvider.notifier).reset();
                    _ctrl.text = defaultMessageTemplate;
                    setState(() => _dirty = false);
                  },
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.borderLight),
                    foregroundColor: AppColors.inkFaint,
                  ),
                  child: const Text('Restablecer'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton(
                  onPressed: _dirty
                      ? () async {
                          await ref.read(messageTemplateProvider.notifier).save(_ctrl.text);
                          setState(() => _dirty = false);
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: const Text('Mensaje guardado'),
                                duration: const Duration(seconds: 2),
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                            );
                          }
                        }
                      : null,
                  child: const Text('Guardar'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
