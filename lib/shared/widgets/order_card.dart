import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/utils/date_helper.dart';
import '../../features/orders/domain/entities/order_entity.dart';
import 'status_badge.dart';

class OrderCard extends StatelessWidget {
  final OrderEntity order;
  final VoidCallback? onTap;

  const OrderCard({super.key, required this.order, this.onTap});

  @override
  Widget build(BuildContext context) {
    final hasPhoto = order.photos.isNotEmpty;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.parchment,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: order.isOverdue ? AppColors.danger.withValues(alpha: 0.4) : AppColors.borderLight),
          boxShadow: const [BoxShadow(color: AppColors.shadow, blurRadius: 4, offset: Offset(0, 2))],
        ),
        child: Row(
          children: [
            // Photo thumbnail or placeholder
            if (hasPhoto)
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: CachedNetworkImage(
                  imageUrl: order.photos.first.photoUrl,
                  width: 56,
                  height: 56,
                  fit: BoxFit.cover,
                  placeholder: (_, __) => Container(width: 56, height: 56, color: AppColors.borderLight),
                  errorWidget: (_, __, ___) => _PhotoPlaceholder(count: order.photos.length),
                ),
              )
            else
              const _PhotoPlaceholder(count: 0),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          order.clientName ?? 'Sin cliente',
                          style: AppTextStyles.headlineSmall.copyWith(fontSize: 15),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      StatusBadge(status: order.status),
                    ],
                  ),
                  const SizedBox(height: 4),
                  if (order.photos.isNotEmpty && order.photos.first.description.isNotEmpty)
                    Text(
                      order.photos.first.description,
                      style: AppTextStyles.bodySmall.copyWith(fontStyle: FontStyle.italic),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.calendar_today_outlined, size: 11, color: AppColors.inkFaint),
                      const SizedBox(width: 4),
                      Text(order.deliveryDate != null ? 'Entrega: ${DateHelper.formatFull(order.deliveryDate!)}' : 'Sin fecha de entrega', style: AppTextStyles.caption),
                      const Spacer(),
                      if (order.photos.length > 1)
                        Text('+${order.photos.length} fotos', style: AppTextStyles.caption.copyWith(color: AppColors.accent)),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      const Icon(Icons.person_outline_rounded, size: 11, color: AppColors.inkFaint),
                      const SizedBox(width: 4),
                      Text(order.createdByName ?? 'Desconocido', style: AppTextStyles.caption),
                      const Spacer(),
                      Text(DateHelper.formatRelative(order.deliveryDate), style: AppTextStyles.caption.copyWith(color: order.isOverdue ? AppColors.danger : order.isUrgent ? AppColors.accent : AppColors.inkFaint, fontWeight: order.isOverdue || order.isUrgent ? FontWeight.w700 : FontWeight.w400)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 6),
            const Icon(Icons.chevron_right_rounded, color: AppColors.inkFaint, size: 18),
          ],
        ),
      ),
    );
  }
}

class _PhotoPlaceholder extends StatelessWidget {
  final int count;
  const _PhotoPlaceholder({required this.count});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(color: AppColors.borderLight, borderRadius: BorderRadius.circular(8)),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(count > 0 ? Icons.photo_library_outlined : Icons.image_outlined, color: AppColors.inkFaint, size: 20),
          if (count > 0) Text('$count', style: AppTextStyles.caption),
        ],
      ),
    );
  }
}
