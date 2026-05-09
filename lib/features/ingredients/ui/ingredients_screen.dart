import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lazychef/core/router/app_router.dart';
import 'package:lazychef/core/widgets/app_bottom_bar.dart';
import 'package:lazychef/core/widgets/app_button.dart';
import 'package:lazychef/core/widgets/lazychef_scaffold.dart';
import 'package:lazychef/core/widgets/section_title.dart';
import 'package:lazychef/features/history/models/history_scan.dart';
import 'package:lazychef/features/history/providers/history_provider.dart';
import 'package:lazychef/features/scan/utils/scan_image_picker.dart';

enum _IngredientFilter {
  all('All'),
  latest('Latest scan'),
  highConfidence('High confidence');

  const _IngredientFilter(this.label);

  final String label;
}

class IngredientsScreen extends ConsumerStatefulWidget {
  const IngredientsScreen({super.key});

  @override
  ConsumerState<IngredientsScreen> createState() => _IngredientsScreenState();
}

class _IngredientsScreenState extends ConsumerState<IngredientsScreen> {
  final _searchController = TextEditingController();
  _IngredientFilter _selectedFilter = _IngredientFilter.latest;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController
      ..removeListener(_onSearchChanged)
      ..dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final scanHistory = ref.watch(scanHistoryProvider);

    return LazyChefScaffold(
      bottomNavigationBar: const AppBottomBar(currentIndex: 2),
      child: RefreshIndicator(
        onRefresh: () => ref.refresh(scanHistoryProvider.future),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(24, 18, 24, 110),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  IconButton.filledTonal(
                    tooltip: 'Back',
                    onPressed: () {
                      Navigator.pushReplacementNamed(context, AppRouter.home);
                    },
                    icon: const Icon(Icons.arrow_back_rounded),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Ingredients',
                      style: Theme.of(context).textTheme.displaySmall,
                    ),
                  ),
                  IconButton.filledTonal(
                    tooltip: 'Scan shelf',
                    onPressed: () => showScanImagePickerOptions(context),
                    icon: const Icon(Icons.qr_code_scanner_rounded),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filledTonal(
                    tooltip: 'Refresh',
                    onPressed: () {
                      ref.invalidate(scanHistoryProvider);
                    },
                    icon: const Icon(Icons.refresh_rounded),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const SectionTitle(
                eyebrow: 'My fridge',
                title: 'Ingredients from saved scans',
                subtitle:
                    'This inventory is built from scans saved under the current account.',
              ),
              const SizedBox(height: 18),
              _SearchField(controller: _searchController),
              const SizedBox(height: 16),
              _FilterChips(
                selectedFilter: _selectedFilter,
                onSelected: (filter) {
                  setState(() {
                    _selectedFilter = filter;
                  });
                },
              ),
              const SizedBox(height: 20),
              scanHistory.when(
                loading: () => const _IngredientsLoading(),
                error: (error, _) => _IngredientsError(
                  error: error,
                  onRetry: () {
                    ref.invalidate(scanHistoryProvider);
                  },
                ),
                data: (scans) {
                  final ingredients = _filterIngredients(
                    scans: scans,
                    query: _searchController.text,
                    filter: _selectedFilter,
                  );

                  if (scans.isEmpty) {
                    return const _EmptyIngredients();
                  }
                  if (ingredients.isEmpty) {
                    return const _NoMatchingIngredients();
                  }

                  return _IngredientsGrid(ingredients: ingredients);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SearchField extends StatelessWidget {
  const _SearchField({required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      textInputAction: TextInputAction.search,
      decoration: InputDecoration(
        hintText: 'Search saved ingredients',
        prefixIcon: const Icon(Icons.search_rounded),
        suffixIcon: controller.text.isEmpty
            ? null
            : IconButton(
                tooltip: 'Clear',
                onPressed: controller.clear,
                icon: const Icon(Icons.close_rounded),
              ),
      ),
    );
  }
}

class _FilterChips extends StatelessWidget {
  const _FilterChips({required this.selectedFilter, required this.onSelected});

  final _IngredientFilter selectedFilter;
  final ValueChanged<_IngredientFilter> onSelected;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: _IngredientFilter.values.map((filter) {
        return ChoiceChip(
          label: Text(filter.label),
          selected: selectedFilter == filter,
          onSelected: (_) => onSelected(filter),
        );
      }).toList(),
    );
  }
}

class _IngredientsGrid extends StatelessWidget {
  const _IngredientsGrid({required this.ingredients});

  final List<_IngredientInventoryItem> ingredients;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth >= 720 ? 3 : 2;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${ingredients.length} saved ingredients',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(color: const Color(0xFF6A5D51)),
            ),
            const SizedBox(height: 12),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                childAspectRatio: 0.86,
                crossAxisSpacing: 14,
                mainAxisSpacing: 14,
              ),
              itemCount: ingredients.length,
              itemBuilder: (context, index) {
                return _IngredientCard(ingredient: ingredients[index]);
              },
            ),
          ],
        );
      },
    );
  }
}

class _IngredientCard extends StatelessWidget {
  const _IngredientCard({required this.ingredient});

  final _IngredientInventoryItem ingredient;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEDE3D7),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.eco_rounded,
                    color: Color(0xFF23433C),
                  ),
                ),
                const Spacer(),
                Text(
                  '${ingredient.confidencePercent}%',
                  style: textTheme.labelLarge?.copyWith(
                    color: const Color(0xFFC85D3B),
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
            const Spacer(),
            Text(
              ingredient.displayName,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Seen in ${ingredient.scanCount} ${ingredient.scanCount == 1 ? 'scan' : 'scans'}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: textTheme.bodySmall?.copyWith(
                color: const Color(0xFF6A5D51),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(
                  Icons.history_rounded,
                  size: 16,
                  color: Color(0xFF6A5D51),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    _lastSeenLabel(ingredient.lastSeen),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.bodySmall?.copyWith(
                      color: const Color(0xFF6A5D51),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _IngredientsLoading extends StatelessWidget {
  const _IngredientsLoading();

  @override
  Widget build(BuildContext context) {
    return const Card(
      child: Padding(
        padding: EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Loading saved ingredients...'),
            SizedBox(height: 14),
            LinearProgressIndicator(),
          ],
        ),
      ),
    );
  }
}

class _IngredientsError extends StatelessWidget {
  const _IngredientsError({required this.error, required this.onRetry});

  final Object error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final needsSignIn = error.toString().contains('sign in');

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.error_outline_rounded,
                  color: Color(0xFFC85D3B),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Could not load ingredients',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              error.toString(),
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            AppButton.secondary(
              label: needsSignIn ? 'Sign in' : 'Try again',
              icon: needsSignIn ? Icons.login_rounded : Icons.refresh_rounded,
              onPressed: needsSignIn
                  ? () {
                      Navigator.pushNamedAndRemoveUntil(
                        context,
                        AppRouter.login,
                        (route) => false,
                      );
                    }
                  : onRetry,
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyIngredients extends StatelessWidget {
  const _EmptyIngredients();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.kitchen_outlined, color: Color(0xFFC85D3B)),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'No ingredients saved yet',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              'Scan a shelf to build your account inventory.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            AppButton.primary(
              label: 'Start scanning',
              icon: Icons.qr_code_scanner_rounded,
              onPressed: () => showScanImagePickerOptions(context),
            ),
          ],
        ),
      ),
    );
  }
}

class _NoMatchingIngredients extends StatelessWidget {
  const _NoMatchingIngredients();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            const Icon(Icons.search_off_rounded, color: Color(0xFFC85D3B)),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'No saved ingredients match this filter.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

List<_IngredientInventoryItem> _filterIngredients({
  required List<HistoryScan> scans,
  required String query,
  required _IngredientFilter filter,
}) {
  final normalizedQuery = query.trim().toLowerCase();
  final sourceScans = switch (filter) {
    _IngredientFilter.latest => scans.isEmpty ? <HistoryScan>[] : [scans.first],
    _IngredientFilter.all || _IngredientFilter.highConfidence => scans,
  };
  final ingredients = _buildInventory(sourceScans).where((ingredient) {
    final matchesQuery =
        normalizedQuery.isEmpty || ingredient.name.contains(normalizedQuery);
    final matchesFilter = switch (filter) {
      _IngredientFilter.all => true,
      _IngredientFilter.latest => true,
      _IngredientFilter.highConfidence => ingredient.bestConfidence >= 0.75,
    };

    return matchesQuery && matchesFilter;
  }).toList();

  ingredients.sort((a, b) {
    final confidenceCompare = b.bestConfidence.compareTo(a.bestConfidence);
    if (confidenceCompare != 0) {
      return confidenceCompare;
    }

    return a.displayName.compareTo(b.displayName);
  });

  return ingredients;
}

List<_IngredientInventoryItem> _buildInventory(List<HistoryScan> scans) {
  final byName = <String, _MutableIngredientInventoryItem>{};

  for (final scan in scans) {
    for (final ingredient in scan.detectedIngredients) {
      final name = ingredient.name.trim().toLowerCase();
      if (name.isEmpty) {
        continue;
      }

      final item = byName.putIfAbsent(
        name,
        () => _MutableIngredientInventoryItem(name: name),
      );
      item.scanIds.add(scan.id);
      item.bestConfidence = item.bestConfidence > ingredient.confidence
          ? item.bestConfidence
          : ingredient.confidence;

      final createdDate = scan.createdDate;
      if (createdDate != null &&
          (item.lastSeen == null || createdDate.isAfter(item.lastSeen!))) {
        item.lastSeen = createdDate;
      }
    }
  }

  return byName.values.map(_IngredientInventoryItem.fromMutable).toList();
}

String _lastSeenLabel(DateTime? date) {
  if (date == null) {
    return 'Saved scan';
  }

  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final scanDay = DateTime(date.year, date.month, date.day);
  final difference = today.difference(scanDay).inDays;

  if (difference == 0) {
    return 'Seen today';
  }
  if (difference == 1) {
    return 'Seen yesterday';
  }

  return 'Seen ${date.year}-${_twoDigits(date.month)}-${_twoDigits(date.day)}';
}

String _displayName(String name) {
  return name
      .split(' ')
      .where((part) => part.isNotEmpty)
      .map((part) => '${part[0].toUpperCase()}${part.substring(1)}')
      .join(' ');
}

String _twoDigits(int value) => value.toString().padLeft(2, '0');

class _MutableIngredientInventoryItem {
  _MutableIngredientInventoryItem({required this.name});

  final String name;
  final Set<String> scanIds = {};
  double bestConfidence = 0;
  DateTime? lastSeen;
}

class _IngredientInventoryItem {
  const _IngredientInventoryItem({
    required this.name,
    required this.displayName,
    required this.scanIds,
    required this.bestConfidence,
    required this.lastSeen,
  });

  factory _IngredientInventoryItem.fromMutable(
    _MutableIngredientInventoryItem item,
  ) {
    return _IngredientInventoryItem(
      name: item.name,
      displayName: _displayName(item.name),
      scanIds: Set.unmodifiable(item.scanIds),
      bestConfidence: item.bestConfidence.clamp(0, 1),
      lastSeen: item.lastSeen,
    );
  }

  final String name;
  final String displayName;
  final Set<String> scanIds;
  final double bestConfidence;
  final DateTime? lastSeen;

  int get scanCount => scanIds.length;
  int get confidencePercent => (bestConfidence * 100).round();
}
