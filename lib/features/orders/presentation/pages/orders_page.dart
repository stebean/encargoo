import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../presentation/notifiers/orders_notifier.dart';
import '../../domain/entities/order_entity.dart';
import '../../../../shared/widgets/order_card.dart';

enum OrderFilter { todos, urgentes, atrasados }

class OrdersPage extends ConsumerStatefulWidget {
  const OrdersPage({super.key});

  @override
  ConsumerState<OrdersPage> createState() => _OrdersPageState();
}

class _OrdersPageState extends ConsumerState<OrdersPage> {
  final _searchCtrl = TextEditingController();
  String _query = '';
  OrderFilter _filter = OrderFilter.todos;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(ordersProvider.notifier).loadOrders();
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(ordersProvider);
    final notifier = ref.read(ordersProvider.notifier);

    // Apply filter first, then search
    List<OrderEntity> base;
    switch (_filter) {
      case OrderFilter.urgentes:
        base = notifier.urgent;
      case OrderFilter.atrasados:
        base = notifier.overdue;
      case OrderFilter.todos:
        base = state.orders;
    }
    final results = _query.isEmpty
        ? base
        : notifier.search(_query).where((o) => base.any((b) => b.id == o.id)).toList();

    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        title: const Text('Encargos', style: AppTextStyles.headlineMedium),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Text('${state.orders.length} total', style: AppTextStyles.caption),
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter chips
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _FilterChip(
                    label: 'Todos',
                    icon: Icons.list_rounded,
                    selected: _filter == OrderFilter.todos,
                    onTap: () => setState(() => _filter = OrderFilter.todos),
                  ),
                  const SizedBox(width: 8),
                  _FilterChip(
                    label: 'Urgentes',
                    icon: Icons.timer_outlined,
                    selected: _filter == OrderFilter.urgentes,
                    onTap: () => setState(() => _filter = OrderFilter.urgentes),
                    color: AppColors.accent,
                  ),
                  const SizedBox(width: 8),
                  _FilterChip(
                    label: 'Atrasados',
                    icon: Icons.warning_amber_rounded,
                    selected: _filter == OrderFilter.atrasados,
                    onTap: () => setState(() => _filter = OrderFilter.atrasados),
                    color: AppColors.danger,
                  ),
                ],
              ),
            ),
          ),
          // Search bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: TextField(
              controller: _searchCtrl,
              decoration: InputDecoration(
                hintText: 'Buscar por cliente o descripción…',
                prefixIcon: const Icon(Icons.search_rounded, size: 18),
                suffixIcon: _query.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded, size: 18),
                        onPressed: () {
                          _searchCtrl.clear();
                          setState(() => _query = '');
                        },
                      )
                    : null,
              ),
              onChanged: (v) => setState(() => _query = v),
            ),
          ),
          // Results
          Expanded(
            child: state.loading
                ? const Center(child: CircularProgressIndicator(color: AppColors.accent))
                : results.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.receipt_long_outlined, size: 54, color: AppColors.borderLight),
                            const SizedBox(height: 14),
                            Text(
                              _query.isEmpty ? 'No hay encargos' : 'Sin resultados para "$_query"',
                              style: AppTextStyles.bodyMedium.copyWith(color: AppColors.inkFaint),
                            ),
                          ],
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: results.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (_, i) => OrderCard(
                          order: results[i],
                          onTap: () => context.go('/encargos/${results[i].id}'),
                        ),
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.go('/encargos/nuevo'),
        tooltip: 'Nuevo encargo',
        child: const Icon(Icons.add_rounded),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;
  final Color? color;

  const _FilterChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppColors.accent;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? c : AppColors.parchment,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: selected ? c : AppColors.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: selected ? AppColors.white : c),
            const SizedBox(width: 6),
            Text(
              label,
              style: AppTextStyles.labelMedium.copyWith(
                color: selected ? AppColors.white : AppColors.inkLight,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

