import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../auth/presentation/notifiers/auth_notifier.dart';

class WorkspaceSetupPage extends ConsumerStatefulWidget {
  const WorkspaceSetupPage({super.key});

  @override
  ConsumerState<WorkspaceSetupPage> createState() => _WorkspaceSetupPageState();
}

class _WorkspaceSetupPageState extends ConsumerState<WorkspaceSetupPage> {
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
    if (_isCreating) {
      await notifier.createWorkspace(_nameCtrl.text.trim());
    } else {
      await notifier.joinWorkspace(_codeCtrl.text.trim());
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);

    return Scaffold(
      backgroundColor: AppColors.cream,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 40),
          child: Form(
            key: _form,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),
                Text('Bienvenido\n${auth.user?.fullName ?? ''}', style: AppTextStyles.displayMedium),
                const SizedBox(height: 8),
                Text('Primero, configura tu espacio de trabajo', style: AppTextStyles.bodySmall.copyWith(fontStyle: FontStyle.italic)),
                const SizedBox(height: 32),
                // Toggle
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(color: AppColors.parchment, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.borderLight)),
                  child: Row(
                    children: [
                      _Tab(label: 'Crear nuevo', selected: _isCreating, onTap: () => setState(() => _isCreating = true)),
                      _Tab(label: 'Unirse con código', selected: !_isCreating, onTap: () => setState(() => _isCreating = false)),
                    ],
                  ),
                ),
                const SizedBox(height: 28),
                if (_isCreating) ...[
                  const Text('Nombre del espacio de trabajo', style: AppTextStyles.labelLarge),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _nameCtrl,
                    decoration: const InputDecoration(
                      hintText: 'Ej. Taller de Costura, Encargos Rosa…',
                      prefixIcon: Icon(Icons.workspaces_outlined, size: 18),
                    ),
                    validator: (v) => (v?.isEmpty ?? true) ? 'Escribe un nombre' : null,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Se generará un código automático para que otros puedan unirse.',
                    style: AppTextStyles.caption.copyWith(fontStyle: FontStyle.italic),
                  ),
                ] else ...[
                  const Text('Código de acceso', style: AppTextStyles.labelLarge),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _codeCtrl,
                    textCapitalization: TextCapitalization.characters,
                    maxLength: 6,
                    decoration: const InputDecoration(
                      hintText: 'A1B2C3',
                      prefixIcon: Icon(Icons.vpn_key_outlined, size: 18),
                      counterText: '',
                    ),
                    style: const TextStyle(letterSpacing: 4, fontWeight: FontWeight.w700, fontSize: 18),
                    validator: (v) => ((v?.length ?? 0) < 6) ? 'Código de 6 caracteres' : null,
                  ),
                ],
                if (auth.error != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: AppColors.dangerLight, borderRadius: BorderRadius.circular(8), border: Border.all(color: AppColors.danger.withValues(alpha: 0.3))),
                    child: Text(auth.error!, style: AppTextStyles.bodySmall.copyWith(color: AppColors.danger)),
                  ),
                ],
                const SizedBox(height: 28),
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
        ),
      ),
    );
  }
}

class _Tab extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _Tab({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected ? AppColors.accent : Colors.transparent,
            borderRadius: BorderRadius.circular(9),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: AppTextStyles.labelMedium.copyWith(color: selected ? AppColors.white : AppColors.inkFaint),
          ),
        ),
      ),
    );
  }
}
