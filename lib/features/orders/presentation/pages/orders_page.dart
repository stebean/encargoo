import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../presentation/notifiers/orders_notifier.dart';
import '../../../../shared/widgets/order_card.dart';

class OrdersPage extends ConsumerStatefulWidget {
  const OrdersPage({super.key});

  @override
  ConsumerState<OrdersPage> createState() => _OrdersPageState();
}

class _OrdersPageState extends ConsumerState<OrdersPage> {
  final _searchCtrl = TextEditingController();
  String _query = '';

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
    final results = notifier.search(_query);

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
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: TextField(
              controller: _searchCtrl,
              decoration: InputDecoration(
                hintText: 'Buscar por cliente o descripción…',
                prefixIcon: const Icon(Icons.search_rounded, size: 18),
                suffixIcon: _query.isNotEmpty
                    ? IconButton(icon: const Icon(Icons.clear_rounded, size: 18), onPressed: () { _searchCtrl.clear(); setState(() => _query = ''); })
                    : null,
              ),
              onChanged: (v) => setState(() => _query = v),
            ),
          ),
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
                            Text(_query.isEmpty ? 'No hay encargos' : 'Sin resultados para "$_query"', style: AppTextStyles.bodyMedium.copyWith(color: AppColors.inkFaint)),
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
        child: const Icon(Icons.add_rounded),
      ),
    );
  }
}
