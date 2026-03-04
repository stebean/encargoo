import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../auth/presentation/notifiers/auth_notifier.dart';
import '../../../orders/presentation/notifiers/orders_notifier.dart';
import '../../../orders/domain/entities/order_entity.dart';
import '../../../../shared/widgets/order_card.dart';
import '../../../../shared/widgets/mini_calendar.dart';

enum HomeFilter { todos, urgentes, atrasados }

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  HomeFilter _filter = HomeFilter.todos;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(ordersProvider.notifier).loadOrders();
    });
  }

  @override
  Widget build(BuildContext context) {
    final ordersState = ref.watch(ordersProvider);
    final notifier = ref.read(ordersProvider.notifier);
    final user = ref.watch(authProvider).user;

    List<OrderEntity> filtered;
    switch (_filter) {
      case HomeFilter.urgentes:
        filtered = notifier.urgent;
      case HomeFilter.atrasados:
        filtered = notifier.overdue;
      case HomeFilter.todos:
        filtered = notifier.upcoming;
    }

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
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Encargoo', style: AppTextStyles.headlineLarge.copyWith(color: AppColors.accent)),
                Text('Hola ${user?.fullName.split(' ').first ?? ''}', style: AppTextStyles.caption),
              ],
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
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Próximas entregas', style: AppTextStyles.headlineSmall),
                  const SizedBox(height: 12),
                  // Filter chips
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _FilterChip(label: 'Todos', icon: Icons.list_rounded, selected: _filter == HomeFilter.todos, onTap: () => setState(() => _filter = HomeFilter.todos)),
                        const SizedBox(width: 8),
                        _FilterChip(label: 'Urgentes', icon: Icons.timer_outlined, selected: _filter == HomeFilter.urgentes, onTap: () => setState(() => _filter = HomeFilter.urgentes), color: AppColors.accent),
                        const SizedBox(width: 8),
                        _FilterChip(label: 'Atrasados', icon: Icons.warning_amber_rounded, selected: _filter == HomeFilter.atrasados, onTap: () => setState(() => _filter = HomeFilter.atrasados), color: AppColors.danger),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (ordersState.loading)
            const SliverToBoxAdapter(child: Padding(padding: EdgeInsets.all(40), child: Center(child: CircularProgressIndicator(color: AppColors.accent))))
          else if (filtered.isEmpty)
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
                    order: filtered[i],
                    onTap: () => context.go('/encargos/${filtered[i].id}'),
                  ),
                ),
                childCount: filtered.length,
              ),
            ),
          const SliverToBoxAdapter(child: SizedBox(height: 24)),
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

  const _FilterChip({required this.label, required this.icon, required this.selected, required this.onTap, this.color});

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
            Text(label, style: AppTextStyles.labelMedium.copyWith(color: selected ? AppColors.white : AppColors.inkLight)),
          ],
        ),
      ),
    );
  }
}
