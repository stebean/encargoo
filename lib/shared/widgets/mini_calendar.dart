import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/utils/date_helper.dart';

class MiniCalendar extends StatefulWidget {
  final List<DateTime> deliveryDates;

  const MiniCalendar({super.key, required this.deliveryDates});

  @override
  State<MiniCalendar> createState() => _MiniCalendarState();
}

class _MiniCalendarState extends State<MiniCalendar> {
  late DateTime _month;

  @override
  void initState() {
    super.initState();
    _month = DateTime.now();
  }

  bool _hasDelivery(DateTime day) {
    return widget.deliveryDates.any((d) => d.year == day.year && d.month == day.month && d.day == day.day);
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final firstDay = DateTime(_month.year, _month.month, 1);
    final daysInMonth = DateTime(_month.year, _month.month + 1, 0).day;
    final startWeekday = firstDay.weekday % 7; // 0=Sun

    final days = <Widget>[];
    // Day headers
    for (final d in ['D', 'L', 'M', 'Mi', 'J', 'V', 'S']) {
      days.add(Center(child: Text(d, style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.w700, color: AppColors.accent))));
    }
    // Empty cells
    for (int i = 0; i < startWeekday; i++) {
      days.add(const SizedBox());
    }
    // Day cells
    for (int i = 1; i <= daysInMonth; i++) {
      final date = DateTime(_month.year, _month.month, i);
      final isToday = date.year == now.year && date.month == now.month && date.day == now.day;
      final hasDelivery = _hasDelivery(date);

      days.add(
        Center(
          child: Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: isToday ? AppColors.accent : Colors.transparent,
              shape: BoxShape.circle,
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Text(
                  '$i',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: isToday ? AppColors.white : AppColors.ink,
                    fontWeight: isToday ? FontWeight.w700 : FontWeight.w400,
                  ),
                ),
                if (hasDelivery)
                  Positioned(
                    bottom: 2,
                    child: Container(
                      width: 4,
                      height: 4,
                      decoration: BoxDecoration(
                        color: isToday ? AppColors.white : AppColors.danger,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.parchment,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left_rounded, size: 20, color: AppColors.inkLight),
                onPressed: () => setState(() => _month = DateTime(_month.year, _month.month - 1)),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              Text(
                DateHelper.formatFull(firstDay).split(',').last.trim().replaceAll(RegExp(r'\d{4}'), DateHelper.formatFull(firstDay).split(' ').last),
                style: AppTextStyles.labelLarge.copyWith(fontFamily: 'PlayfairDisplay'),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right_rounded, size: 20, color: AppColors.inkLight),
                onPressed: () => setState(() => _month = DateTime(_month.year, _month.month + 1)),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          const SizedBox(height: 8),
          GridView.count(
            crossAxisCount: 7,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 2,
            crossAxisSpacing: 0,
            childAspectRatio: 1,
            children: days,
          ),
        ],
      ),
    );
  }
}
