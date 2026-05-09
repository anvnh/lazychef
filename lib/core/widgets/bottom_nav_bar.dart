import 'package:flutter/material.dart';
import 'package:lazychef/core/router/app_router.dart';
import 'package:lazychef/features/scan/utils/scan_image_picker.dart';

class BottomNavBar extends StatelessWidget {
  const BottomNavBar({super.key, required this.currentIndex});

  final int currentIndex;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primary,
          borderRadius: BorderRadius.circular(12),
        ),
        child: NavigationBarTheme(
          data: NavigationBarThemeData(
            labelTextStyle: WidgetStateProperty.resolveWith((states) {
              final isSelected = states.contains(WidgetState.selected);

              return TextStyle(
                color: isSelected
                    ? const Color(0xFFFFFFFF)
                    : const Color(0xFFC9C9C9),
                fontSize: 12,
                fontWeight: FontWeight.w700,
              );
            }),
          ),
          child: NavigationBar(
            selectedIndex: currentIndex,
            onDestinationSelected: (index) {
              if (index == currentIndex) {
                return;
              }
              if (index == 0) {
                Navigator.pushReplacementNamed(context, AppRouter.home);
              } else if (index == 1) {
                showScanImagePickerOptions(context);
              } else if (index == 2) {
                Navigator.pushReplacementNamed(context, AppRouter.history);
              }
            },
            backgroundColor: Colors.transparent,
            indicatorColor: const Color(0xFFE4A55A),
            labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.home_outlined, color: Color(0xFFC9C9C9)),
                selectedIcon: Icon(
                  Icons.home_rounded,
                  color: Color(0xFFFFFFFF),
                ),
                label: 'Home',
              ),
              NavigationDestination(
                icon: Icon(
                  Icons.qr_code_scanner_outlined,
                  color: Color(0xFFC9C9C9),
                ),
                selectedIcon: Icon(
                  Icons.qr_code_scanner_rounded,
                  color: Color(0xFFFFFFFF),
                ),
                label: 'Scan',
              ),
              NavigationDestination(
                icon: Icon(Icons.history_outlined, color: Color(0xFFC9C9C9)),
                selectedIcon: Icon(
                  Icons.history_rounded,
                  color: Color(0xFFFFFFFF),
                ),
                label: 'History',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
