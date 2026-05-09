import 'package:flutter/material.dart';
import 'package:lazychef/core/router/app_router.dart';

class AppBottomBar extends StatelessWidget {
  const AppBottomBar({super.key, required this.currentIndex});

  final int currentIndex;

  @override
  Widget build(BuildContext context) {
    final activeColor = Theme.of(context).colorScheme.primary;
    const inactiveColor = Color(0xFFC8CCCD);
    final bottomPadding = MediaQuery.paddingOf(context).bottom;

    return SizedBox(
      height: 70 + bottomPadding + 20,
      child: Stack(
        alignment: Alignment.bottomCenter,
        clipBehavior: Clip.none,
        children: [
          Container(
            height: 70 + bottomPadding,
            padding: EdgeInsets.only(bottom: bottomPadding),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(
                  context: context,
                  icon: Icons.pie_chart_outline_rounded,
                  activeIcon: Icons.pie_chart_rounded,
                  label: 'Home',
                  index: 0,
                  isActive: currentIndex == 0,
                  activeColor: activeColor,
                  inactiveColor: inactiveColor,
                ),
                _buildNavItem(
                  context: context,
                  icon: Icons.ramen_dining_outlined,
                  activeIcon: Icons.ramen_dining_rounded,
                  label: 'Recipes',
                  index: 1,
                  isActive: currentIndex == 1,
                  activeColor: activeColor,
                  inactiveColor: inactiveColor,
                ),
                const SizedBox(width: 110), // Space for center button
                _buildNavItem(
                  context: context,
                  icon: Icons.kitchen_outlined,
                  activeIcon: Icons.kitchen_rounded,
                  label: 'Ingred.',
                  index: 2,
                  isActive: currentIndex == 2,
                  activeColor: activeColor,
                  inactiveColor: inactiveColor,
                ),
                _buildNavItem(
                  context: context,
                  icon: Icons.history_outlined,
                  activeIcon: Icons.history_rounded,
                  label: 'History',
                  index: 3,
                  isActive: currentIndex == 3,
                  activeColor: activeColor,
                  inactiveColor: inactiveColor,
                ),
              ],
            ),
          ),
          Positioned(
            top: 0,
            child: GestureDetector(
              onTap: () {
                if (currentIndex != 1) {
                  Navigator.pushNamed(context, AppRouter.scanResult);
                }
              },
              child: Container(
                width: 68,
                height: 68,
                decoration: BoxDecoration(
                  color: activeColor,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.qr_code_scanner_rounded,
                  color: Colors.white,
                  size: 32,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem({
    required BuildContext context,
    required IconData icon,
    required IconData activeIcon,
    required String label,
    required int index,
    required bool isActive,
    required Color activeColor,
    required Color inactiveColor,
  }) {
    final color = isActive ? activeColor : inactiveColor;
    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          if (index == currentIndex) return;
          if (index == 0) {
            Navigator.pushReplacementNamed(context, AppRouter.home);
          } else if (index == 1) {
            Navigator.pushReplacementNamed(context, AppRouter.recipe);
          } else if (index == 2) {
            Navigator.pushReplacementNamed(context, AppRouter.ingredients);
          } else if (index == 3) {
            Navigator.pushReplacementNamed(context, AppRouter.history);
          }
        },
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(isActive ? activeIcon : icon, color: color, size: 28),
            const SizedBox(height: 2),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                label,
                maxLines: 1,
                style: TextStyle(
                  color: color,
                  fontSize: 12,
                  fontWeight: isActive ? FontWeight.w700 : FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
