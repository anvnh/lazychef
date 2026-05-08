import 'package:flutter/material.dart';
import 'package:lazychef/core/router/app_router.dart';
import 'package:lazychef/core/widgets/app_bottom_bar.dart';
import 'package:lazychef/core/widgets/lazychef_scaffold.dart';
import 'package:lazychef/core/widgets/section_title.dart';
import 'package:lazychef/features/scan/ui/demo_content.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return LazyChefScaffold(
      bottomNavigationBar: const AppBottomBar(currentIndex: 3),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 18, 24, 110),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'History',
                    style: Theme.of(context).textTheme.displaySmall,
                  ),
                ),
                TextButton.icon(
                  onPressed: () {
                    Navigator.pushNamedAndRemoveUntil(
                      context,
                      AppRouter.home,
                      (route) => false,
                    );
                  },
                  icon: const Icon(Icons.add_a_photo_outlined),
                  label: const Text('New scan'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const SectionTitle(
              eyebrow: 'Past scans',
              title: 'A readable activity timeline',
              subtitle: 'Reopen an older scan or start a new one from here.',
            ),
            const SizedBox(height: 18),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: const [
                Chip(label: Text('All')),
                Chip(label: Text('Vegetarian')),
                Chip(label: Text('Quick meals')),
                Chip(label: Text('High confidence')),
              ],
            ),
            const SizedBox(height: 20),
            ..._buildGroupedEntries(context),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildGroupedEntries(BuildContext context) {
    final widgets = <Widget>[];
    String? previousDay;

    for (final entry in demoHistoryEntries) {
      if (entry.dayLabel != previousDay) {
        widgets.add(
          Padding(
            padding: const EdgeInsets.only(top: 10, bottom: 12),
            child: Text(
              entry.dayLabel,
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(color: const Color(0xFFC85D3B)),
            ),
          ),
        );
        previousDay = entry.dayLabel;
      }

      widgets.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          entry.mealTitle,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                      ),
                      Text(
                        entry.timeLabel,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: const Color(0xFF6A5D51),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: entry.ingredients
                        .map((ingredient) => Chip(label: Text(ingredient)))
                        .toList(),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      const Icon(
                        Icons.menu_book_outlined,
                        size: 18,
                        color: Color(0xFF23433C),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${entry.recipesFound} recipes generated',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const Spacer(),
                      TextButton(
                        onPressed: () {
                          Navigator.pushNamed(context, AppRouter.scanResult);
                        },
                        child: const Text('Open'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return widgets;
  }
}

class _HistoryBottomBar extends StatelessWidget {
  const _HistoryBottomBar();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: const Color(0xFF23433C),
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
            selectedIndex: 2,
            onDestinationSelected: (index) {
              if (index == 2) {
                return;
              }
              if (index == 0) {
                Navigator.pushReplacementNamed(context, AppRouter.home);
              } else if (index == 1) {
                Navigator.pushNamed(context, AppRouter.scanResult);
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
                icon: Icon(Icons.qr_code_scanner_outlined, color: Color(0xFFC9C9C9)),
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
