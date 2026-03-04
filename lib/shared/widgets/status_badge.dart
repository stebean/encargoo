import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../features/orders/domain/entities/order_entity.dart';

class StatusBadge extends StatelessWidget {
  final OrderStatus status;
  const StatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    Color bg, fg;
    IconData icon;

    switch (status) {
      case OrderStatus.pendiente:
        bg = AppColors.pendienteLight; fg = AppColors.pendiente; icon = Icons.hourglass_empty_rounded;
      case OrderStatus.lista:
        bg = AppColors.listaLight; fg = AppColors.lista; icon = Icons.check_circle_outline_rounded;
      case OrderStatus.entregada:
        bg = AppColors.entregadaLight; fg = AppColors.entregada; icon = Icons.task_alt_rounded;
      case OrderStatus.atrasada:
        bg = AppColors.atrasadaLight; fg = AppColors.atrasada; icon = Icons.warning_amber_rounded;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: fg),
          const SizedBox(width: 4),
          Text(status.label, style: AppTextStyles.caption.copyWith(color: fg, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}
