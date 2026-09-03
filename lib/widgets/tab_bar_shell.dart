import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class TabBarShell extends StatelessWidget {
  const TabBarShell({
    super.key,
    required this.body,
    required this.currentIndex,
    required this.onTabSelected,
    required this.onFabTap,
  });

  final Widget body;
  final int currentIndex; // 0 Início, 1 Avisos, 3 Calendário, 4 Perfil (2 é o FAB)
  final ValueChanged<int> onTabSelected;
  final VoidCallback onFabTap;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(child: body),
          Positioned(
            left: 14,
            right: 14,
            bottom: 14,
            child: _TabBar(
              currentIndex: currentIndex,
              onTabSelected: onTabSelected,
              onFabTap: onFabTap,
            ),
          ),
        ],
      ),
    );
  }
}

class _TabBar extends StatelessWidget {
  const _TabBar({required this.currentIndex, required this.onTabSelected, required this.onFabTap});

  final int currentIndex;
  final ValueChanged<int> onTabSelected;
  final VoidCallback onFabTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 66,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.16), blurRadius: 30, offset: const Offset(0, 10)),
        ],
      ),
      child: Row(
        children: [
          _TabItem(icon: '🏠', label: 'Início', active: currentIndex == 0, onTap: () => onTabSelected(0)),
          _TabItem(icon: '📰', label: 'Notícias', active: currentIndex == 1, onTap: () => onTabSelected(1)),
          _Fab(onTap: onFabTap),
          _TabItem(icon: '📅', label: 'Calendário', active: currentIndex == 3, onTap: () => onTabSelected(3)),
          _TabItem(icon: '👤', label: 'Perfil', active: currentIndex == 4, onTap: () => onTabSelected(4)),
        ],
      ),
    );
  }
}

class _TabItem extends StatelessWidget {
  const _TabItem({required this.icon, required this.label, required this.active, required this.onTap});

  final String icon;
  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = active ? AppColors.blueDark : AppColors.ink2;
    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.pill),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(icon, style: TextStyle(fontSize: 19, color: color)),
              const SizedBox(height: 2),
              Text(label, style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: color)),
            ],
          ),
        ),
      ),
    );
  }
}

class _Fab extends StatelessWidget {
  const _Fab({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Material(
        color: Colors.transparent,
        shape: const CircleBorder(),
        child: InkWell(
          onTap: onTap,
          customBorder: const CircleBorder(),
          child: Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              gradient: AppColors.gradient,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(color: AppColors.blue.withValues(alpha: 0.45), blurRadius: 18, offset: const Offset(0, 8)),
              ],
            ),
            alignment: Alignment.center,
            child: const Text('🎓', style: TextStyle(fontSize: 22)),
          ),
        ),
      ),
    );
  }
}
