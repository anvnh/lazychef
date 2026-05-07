import 'package:flutter/material.dart';
import 'package:lazychef/core/router/app_router.dart';
import 'package:lazychef/core/widgets/app_button.dart';
import 'package:lazychef/core/widgets/lazychef_scaffold.dart';
import 'package:lazychef/core/widgets/section_title.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return LazyChefScaffold(
      bottomNavigationBar: const _BottomBar(currentIndex: 0),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 18, 24, 110),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'LazyChef',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: Theme.of(context).colorScheme.secondary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Tonight looks easy.',
                        style: Theme.of(context).textTheme.displaySmall,
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: const Color(0xFF23433C),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.ramen_dining_rounded,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 22),
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF23433C), Color(0xFF41635B)],
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'FRIDGE SCAN',
                    style: TextStyle(
                      color: Color(0xFFF7D9B5),
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Point the camera at the shelf and let the app do the ingredient sorting.',
                    style: Theme.of(
                      context,
                    ).textTheme.headlineMedium?.copyWith(color: Colors.white),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'You can also upload a saved photo and preview how the results screen will look.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: const Color(0xFFE5ECE9),
                    ),
                  ),
                  const SizedBox(height: 22),
                  AppButton.primary(
                    label: 'Scan with camera',
                    icon: Icons.photo_camera_outlined,
                    onPressed: () {
                      Navigator.pushNamed(context, AppRouter.scanResult);
                    },
                  ),
                  const SizedBox(height: 12),
                  AppButton.secondary(
                    label: 'Choose photo',
                    icon: Icons.collections_outlined,
                    onPressed: () {
                      Navigator.pushNamed(context, AppRouter.scanResult);
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),
            SectionTitle(
              eyebrow: 'Quick access',
              title: 'Start from what you have',
              subtitle:
                  'Recent staples and shortcuts stay close to the scanner.',
              action: TextButton(
                onPressed: () {
                  Navigator.pushNamed(context, AppRouter.history);
                },
                child: const Text('History'),
              ),
            ),
            const SizedBox(height: 16),
            const _ActionGrid(),
            const SizedBox(height: 28),
            const SectionTitle(
              eyebrow: 'Kitchen rhythm',
              title: 'Ready ingredients',
              subtitle: 'Items most likely to shape tonight\'s suggestions.',
            ),
            const SizedBox(height: 16),
            const _KitchenNotes(),
          ],
        ),
      ),
    );
  }
}

class _ActionGrid extends StatelessWidget {
  const _ActionGrid();

  @override
  Widget build(BuildContext context) {
    final items = [
      (
        'Fast scan',
        'Camera-first entry point for the main workflow.',
        Icons.bolt_rounded,
      ),
      (
        'Recipe preview',
        'Shows ingredients and dishes in the same pass.',
        Icons.menu_book_outlined,
      ),
      (
        'Scan history',
        'Keeps past fridge states readable at a glance.',
        Icons.history_rounded,
      ),
      (
        'Ingredient cues',
        'Confidence styling keeps detection results understandable.',
        Icons.eco_outlined,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 340;

        return GridView.builder(
          itemCount: items.length,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: isCompact ? 1 : 2,
            mainAxisExtent: isCompact ? 128 : 180,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          itemBuilder: (context, index) {
            final item = items[index];

            return Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: const Color(0xFFC85D3B).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(item.$3, color: const Color(0xFFC85D3B)),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      item.$1,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 6),
                    Expanded(
                      child: Text(
                        item.$2,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: const Color(0xFF6A5D51),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _KitchenNotes extends StatelessWidget {
  const _KitchenNotes();

  @override
  Widget build(BuildContext context) {
    final notes = const [
      ('1', 'Eggs', 'Reliable protein for fast skillet meals and rice bowls.'),
      (
        '2',
        'Spinach',
        'Best used soon; pairs well with eggs, pasta, and soup.',
      ),
      ('3', 'Tomatoes', 'Good base for warm toast, sauces, and quick salads.'),
    ];

    return Column(
      children: notes
          .map(
            (note) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: Colors.white,
                  border: Border.all(color: const Color(0xFFCAD3CA)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: const Color(0xFF23433C),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        note.$1,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            note.$2,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            note.$3,
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(color: const Color(0xFF6A5D51)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          )
          .toList(),
    );
  }
}

class _BottomBar extends StatelessWidget {
  const _BottomBar({required this.currentIndex});

  final int currentIndex;

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
            selectedIndex: currentIndex,
            onDestinationSelected: (index) {
              if (index == 0) {
                return;
              }

              Navigator.pushNamed(context, AppRouter.history);
            },
            backgroundColor: Colors.transparent,
            indicatorColor: const Color(0xFFE4A55A),
            labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.home_outlined, color: Color(0xFF999797)),
                selectedIcon: Icon(
                  Icons.home_rounded,
                  color: Color(0xFFFFFFFF),
                ),
                label: 'Home',
              ),
              NavigationDestination(
                icon: Icon(Icons.history_rounded, color: Color(0xFF999797)),
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
