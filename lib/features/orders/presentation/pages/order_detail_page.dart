import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/utils/date_helper.dart';
import '../../presentation/notifiers/orders_notifier.dart';
import '../../domain/entities/order_entity.dart';
import '../../../../shared/widgets/status_badge.dart';
import '../../../auth/presentation/notifiers/auth_notifier.dart';

class OrderDetailPage extends ConsumerWidget {
  final String id;
  const OrderDetailPage({super.key, required this.id});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(ordersProvider);
    final order = state.orders.where((o) => o.id == id).firstOrNull;
    final canDelete = ref.watch(authProvider).user?.canDelete ?? false;

    if (order == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text('Encargo no encontrado')),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        title: Text(order.clientName ?? 'Encargo', style: AppTextStyles.headlineMedium),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined, size: 20),
            onPressed: () => context.go('/encargos/$id/editar'),
          ),
          if (canDelete)
            IconButton(
              icon: const Icon(Icons.delete_outline_rounded, size: 20, color: AppColors.danger),
              onPressed: () => _confirmDelete(context, ref, order),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status row
            Row(
              children: [
                StatusBadge(status: order.status),
                const Spacer(),
                _StatusSelector(order: order),
              ],
            ),
            const SizedBox(height: 20),
            // Info card
            _InfoRow(label: 'Cliente', value: order.clientName ?? 'Sin cliente', icon: Icons.person_outline_rounded),
            _Divider(),
            _InfoRow(label: 'Tomado por', value: order.createdByName ?? '—', icon: Icons.edit_outlined),
            _Divider(),
            _InfoRow(label: 'Fecha de pedido', value: DateHelper.formatFull(order.createdAt), icon: Icons.calendar_today_outlined),
            _Divider(),
            _InfoRow(
              label: 'Entrega',
              value: order.deliveryDate != null ? DateHelper.formatFull(order.deliveryDate!) : 'Sin fecha de entrega',
              icon: Icons.local_shipping_outlined,
              valueColor: order.isOverdue ? AppColors.danger : null,
            ),
            if (order.deliveryDate != null) ...[
              _Divider(),
              _InfoRow(label: '', value: DateHelper.formatRelative(order.deliveryDate), icon: Icons.access_time_rounded, valueColor: order.isOverdue ? AppColors.danger : order.isUrgent ? AppColors.accent : null),
            ],
            if (order.notes != null && order.notes!.isNotEmpty) ...[
              _Divider(),
              _InfoRow(label: 'Notas', value: order.notes!, icon: Icons.notes_rounded),
            ],
            const SizedBox(height: 24),
            // Photos section
            if (order.photos.isNotEmpty) ...[
              Text('Fotos (${order.photos.length})', style: AppTextStyles.headlineSmall),
              const SizedBox(height: 12),
              ...order.photos.map((photo) => _PhotoItem(photo: photo)),
            ] else
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.parchment,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.borderLight),
                ),
                child: Row(children: [
                  const Icon(Icons.photo_library_outlined, color: AppColors.inkFaint),
                  const SizedBox(width: 12),
                  Text('Sin fotos adjuntas', style: AppTextStyles.bodySmall.copyWith(fontStyle: FontStyle.italic)),
                ]),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref, OrderEntity order) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: AppColors.cream,
        title: const Text('Eliminar encargo', style: AppTextStyles.headlineSmall),
        content: Text('¿Eliminar el encargo de ${order.clientName ?? 'este cliente'}?', style: AppTextStyles.bodyMedium),
        actions: [
          TextButton(onPressed: () => Navigator.of(dialogCtx).pop(false), child: const Text('Cancelar')),
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(true),
            child: Text('Eliminar', style: AppTextStyles.labelLarge.copyWith(color: AppColors.danger)),
          ),
        ],
      ),
    );
    if (ok == true && context.mounted) {
      final success = await ref.read(ordersProvider.notifier).deleteOrder(order.id);
      if (context.mounted) {
        if (success) {
          context.go('/encargos');
        } else {
          final err = ref.read(ordersProvider).error ?? 'Error desconocido';
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error al eliminar: $err'), backgroundColor: AppColors.danger),
          );
        }
      }
    }
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color? valueColor;

  const _InfoRow({required this.label, required this.value, required this.icon, this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: AppColors.accent),
          const SizedBox(width: 12),
          if (label.isNotEmpty) ...[
            SizedBox(width: 90, child: Text(label, style: AppTextStyles.labelMedium)),
          ],
          Expanded(child: Text(value, style: AppTextStyles.bodyMedium.copyWith(color: valueColor))),
        ],
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) => const Divider(height: 1, color: AppColors.borderLight);
}

class _StatusSelector extends ConsumerWidget {
  final OrderEntity order;
  const _StatusSelector({required this.order});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return PopupMenuButton<OrderStatus>(
      color: AppColors.parchment,
      icon: const Icon(Icons.swap_horiz_rounded, color: AppColors.accent, size: 20),
      tooltip: 'Cambiar estado',
      onSelected: (s) => ref.read(ordersProvider.notifier).updateOrder(order.id, status: s),
      itemBuilder: (_) => OrderStatus.values.map((s) => PopupMenuItem(
        value: s,
        child: Text(s.label, style: AppTextStyles.bodyMedium),
      )).toList(),
    );
  }
}

class _PhotoItem extends StatelessWidget {
  final OrderPhotoEntity photo;
  const _PhotoItem({required this.photo});

  void _openFullscreen(BuildContext context) {
    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        barrierColor: Colors.black87,
        pageBuilder: (_, __, ___) => _PhotoReadOnlyViewer(photo: photo),
        transitionsBuilder: (_, anim, __, child) =>
            FadeTransition(opacity: anim, child: child),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _openFullscreen(context),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: AppColors.parchment,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.borderLight),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                  child: CachedNetworkImage(
                    imageUrl: photo.photoUrl,
                    width: double.infinity,
                    height: 200,
                    fit: BoxFit.cover,
                  ),
                ),
                Positioned(
                  bottom: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Icon(Icons.fullscreen_rounded, size: 16, color: Colors.white),
                  ),
                ),
              ],
            ),
            if (photo.description.isNotEmpty)
              Padding(
                padding: const EdgeInsets.all(12),
                child: Text(
                  photo.description,
                  style: AppTextStyles.bodyMedium.copyWith(fontStyle: FontStyle.italic),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ── Read-only fullscreen photo viewer ─────────────────────────────────────────
class _PhotoReadOnlyViewer extends StatefulWidget {
  final OrderPhotoEntity photo;
  const _PhotoReadOnlyViewer({required this.photo});

  @override
  State<_PhotoReadOnlyViewer> createState() => _PhotoReadOnlyViewerState();
}

class _PhotoReadOnlyViewerState extends State<_PhotoReadOnlyViewer> {
  bool _showOverlay = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: GestureDetector(
        onTap: () => setState(() => _showOverlay = !_showOverlay),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Full image with zoom
            InteractiveViewer(
              minScale: 0.8,
              maxScale: 4.0,
              child: CachedNetworkImage(
                imageUrl: widget.photo.photoUrl,
                fit: BoxFit.contain,
                placeholder: (_, __) => const Center(child: CircularProgressIndicator(color: Colors.white54)),
                errorWidget: (_, __, ___) => const Center(child: Icon(Icons.broken_image_outlined, color: Colors.white54, size: 48)),
              ),
            ),
            // Close button
            AnimatedOpacity(
              opacity: _showOverlay ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 200),
              child: SafeArea(
                child: Align(
                  alignment: Alignment.topLeft,
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: CircleAvatar(
                      backgroundColor: Colors.black54,
                      child: IconButton(
                        icon: const Icon(Icons.close_rounded, color: Colors.white, size: 20),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            // Bottom: description overlay (read-only)
            if (widget.photo.description.isNotEmpty)
              AnimatedPositioned(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeInOut,
                bottom: _showOverlay ? 0 : -200,
                left: 0,
                right: 0,
                child: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [Color(0xDD000000), Color(0x88000000), Colors.transparent],
                    ),
                  ),
                  padding: EdgeInsets.only(
                    left: 20,
                    right: 20,
                    top: 32,
                    bottom: MediaQuery.of(context).padding.bottom + 20,
                  ),
                  child: Text(
                    widget.photo.description,
                    style: const TextStyle(color: Colors.white, fontSize: 15, height: 1.5),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
