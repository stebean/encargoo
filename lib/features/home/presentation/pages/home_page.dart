import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../auth/presentation/notifiers/auth_notifier.dart';
import '../../../orders/presentation/notifiers/orders_notifier.dart';
import '../../../workspace/presentation/notifiers/workspace_provider.dart';
import '../../../../shared/widgets/order_card.dart';
import '../../../../shared/widgets/mini_calendar.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(ordersProvider.notifier).loadOrders();
    });
  }

  void _showWorkspaceMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.cream,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _WorkspaceSwitcherSheet(
        onCreateNew: () {
          Navigator.pop(context);
          _showWorkspaceSetup(context, startCreating: true);
        },
        onJoinWithCode: () {
          Navigator.pop(context);
          _showWorkspaceSetup(context, startCreating: false);
        },
      ),
    );
  }

  void _showWorkspaceSetup(BuildContext context, {bool startCreating = true}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.cream,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => _WorkspaceFormSheet(startCreating: startCreating),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ordersState = ref.watch(ordersProvider);
    final notifier = ref.read(ordersProvider.notifier);
    final user = ref.watch(authProvider).user;
    final workspace = ref.watch(workspaceProvider);
    final upcoming = notifier.upcoming;

    final workspaceName = workspace.when(
      data: (ws) => ws?.name ?? 'Encargoo',
      loading: () => 'Encargoo',
      error: (_, __) => 'Encargoo',
    );

    return Scaffold(
      backgroundColor: AppColors.cream,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            backgroundColor: AppColors.cream,
            floating: true,
            pinned: false,
            expandedHeight: 0,
            flexibleSpace: null,
            title: GestureDetector(
              onTap: () => _showWorkspaceMenu(context),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    child: Text(
                      workspaceName,
                      style: AppTextStyles.headlineLarge.copyWith(color: AppColors.accent),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.accent, size: 22),
                ],
              ),
            ),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(16),
              child: Padding(
                padding: const EdgeInsets.only(left: 16, bottom: 4),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Hola ${user?.fullName.split(' ').first ?? ''}',
                    style: AppTextStyles.caption,
                  ),
                ),
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.search_rounded, color: AppColors.inkLight),
                onPressed: () => context.go('/encargos'),
              ),
            ],
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: MiniCalendar(deliveryDates: notifier.deliveryDates),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: const Text('Próximas entregas', style: AppTextStyles.headlineSmall),
            ),
          ),
          if (ordersState.loading)
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.all(40),
                child: Center(child: CircularProgressIndicator(color: AppColors.accent)),
              ),
            )
          else if (upcoming.isEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(40),
                child: Center(
                  child: Column(children: [
                    const Icon(Icons.inbox_rounded, size: 48, color: AppColors.borderLight),
                    const SizedBox(height: 12),
                    Text('Sin encargos pendientes', style: AppTextStyles.bodyMedium.copyWith(color: AppColors.inkFaint)),
                  ]),
                ),
              ),
            )
          else
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (ctx, i) => Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  child: OrderCard(
                    order: upcoming[i],
                    onTap: () => context.go('/encargos/${upcoming[i].id}'),
                  ),
                ),
                childCount: upcoming.length,
              ),
            ),
          const SliverToBoxAdapter(child: SizedBox(height: 24)),
        ],
      ),
    );
  }
}

// ── Workspace switcher bottom sheet ──────────────────────────────────────────
class _WorkspaceSwitcherSheet extends StatelessWidget {
  final VoidCallback onCreateNew;
  final VoidCallback onJoinWithCode;
  const _WorkspaceSwitcherSheet({required this.onCreateNew, required this.onJoinWithCode});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.borderLight, borderRadius: BorderRadius.circular(2)))),
          const SizedBox(height: 20),
          const Align(
            alignment: Alignment.centerLeft,
            child: Text('Cambiar espacio de trabajo', style: AppTextStyles.headlineSmall),
          ),
          const SizedBox(height: 20),
          _SheetOption(
            icon: Icons.add_circle_outline_rounded,
            label: 'Crear nuevo espacio de trabajo',
            onTap: onCreateNew,
          ),
          const SizedBox(height: 10),
          _SheetOption(
            icon: Icons.vpn_key_outlined,
            label: 'Unirse con código',
            onTap: onJoinWithCode,
          ),
        ],
      ),
    );
  }
}

class _SheetOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _SheetOption({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.parchment,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.borderLight),
        ),
        child: Row(children: [
          Icon(icon, size: 20, color: AppColors.accent),
          const SizedBox(width: 14),
          Text(label, style: AppTextStyles.bodyMedium),
          const Spacer(),
          const Icon(Icons.chevron_right_rounded, size: 18, color: AppColors.inkFaint),
        ]),
      ),
    );
  }
}

// ── Workspace form bottom sheet ───────────────────────────────────────────────
class _WorkspaceFormSheet extends ConsumerStatefulWidget {
  final bool startCreating;
  const _WorkspaceFormSheet({required this.startCreating});

  @override
  ConsumerState<_WorkspaceFormSheet> createState() => _WorkspaceFormSheetState();
}

class _WorkspaceFormSheetState extends ConsumerState<_WorkspaceFormSheet> {
  late bool _isCreating;
  final _nameCtrl = TextEditingController();
  final _codeCtrl = TextEditingController();
  final _form = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _isCreating = widget.startCreating;
  }

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
            Row(children: [
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(color: AppColors.borderLight.withValues(alpha: 0.5), borderRadius: BorderRadius.circular(10)),
                child: Row(children: [
                  _Tab(label: 'Crear', selected: _isCreating, onTap: () => setState(() => _isCreating = true)),
                  _Tab(label: 'Unirse', selected: !_isCreating, onTap: () => setState(() => _isCreating = false)),
                ]),
              ),
            ]),
            const SizedBox(height: 20),
            if (_isCreating)
              TextFormField(
                controller: _nameCtrl,
                autofocus: true,
                decoration: const InputDecoration(labelText: 'Nombre del espacio de trabajo', hintText: 'Ej. Taller de Costura', prefixIcon: Icon(Icons.workspaces_outlined, size: 18)),
                validator: (v) => (v?.isEmpty ?? true) ? 'Escribe un nombre' : null,
              )
            else
              TextFormField(
                controller: _codeCtrl,
                autofocus: true,
                textCapitalization: TextCapitalization.characters,
                maxLength: 6,
                decoration: const InputDecoration(labelText: 'Código de acceso', hintText: 'A1B2C3', prefixIcon: Icon(Icons.vpn_key_outlined, size: 18), counterText: ''),
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

class _Tab extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _Tab({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? AppColors.accent : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(label, style: AppTextStyles.labelMedium.copyWith(color: selected ? AppColors.white : AppColors.inkFaint)),
      ),
    );
  }
}
