import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';

class AppShell extends StatelessWidget {
  final Widget child;
  final String location;

  const AppShell({super.key, required this.child, required this.location});

  int get _index {
    if (location.startsWith('/encargos')) return 1;
    if (location.startsWith('/clientes')) return 2;
    if (location.startsWith('/ajustes')) return 3;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: child,
      bottomNavigationBar: _AppBottomNav(currentIndex: _index),
    );
  }
}

class _AppBottomNav extends StatelessWidget {
  final int currentIndex;
  const _AppBottomNav({required this.currentIndex});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.parchment,
        border: Border(top: BorderSide(color: AppColors.borderLight, width: 1)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 62,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _NavItem(icon: Icons.home_outlined, activeIcon: Icons.home_rounded, label: 'Inicio', index: 0, currentIndex: currentIndex, path: '/inicio'),
              _NavItem(icon: Icons.receipt_long_outlined, activeIcon: Icons.receipt_long_rounded, label: 'Encargos', index: 1, currentIndex: currentIndex, path: '/encargos'),
              _NavItem(icon: Icons.people_outline_rounded, activeIcon: Icons.people_rounded, label: 'Clientes', index: 2, currentIndex: currentIndex, path: '/clientes'),
              _NavItem(icon: Icons.settings_outlined, activeIcon: Icons.settings_rounded, label: 'Ajustes', index: 3, currentIndex: currentIndex, path: '/ajustes'),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final int index;
  final int currentIndex;
  final String path;

  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.index,
    required this.currentIndex,
    required this.path,
  });

  @override
  Widget build(BuildContext context) {
    final isActive = index == currentIndex;
    return Expanded(
      child: GestureDetector(
        onTap: () => context.go(path),
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: Icon(
                isActive ? activeIcon : icon,
                key: ValueKey(isActive),
                color: isActive ? AppColors.accent : AppColors.inkFaint,
                size: 22,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: AppTextStyles.caption.copyWith(
                color: isActive ? AppColors.accent : AppColors.inkFaint,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w400,
              ),
            ),
            const SizedBox(height: 2),
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOut,
              height: 2,
              width: isActive ? 20 : 0,
              decoration: BoxDecoration(
                color: AppColors.accent,
                borderRadius: BorderRadius.circular(1),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
