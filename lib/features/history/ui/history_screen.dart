import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lazychef/core/router/app_router.dart';
import 'package:lazychef/core/widgets/app_bottom_bar.dart';
import 'package:lazychef/core/widgets/app_button.dart';
import 'package:lazychef/core/widgets/lazychef_scaffold.dart';
import 'package:lazychef/core/widgets/section_title.dart';
import 'package:lazychef/features/history/models/history_scan.dart';
import 'package:lazychef/features/history/providers/history_provider.dart';

class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scanHistory = ref.watch(scanHistoryProvider);

    return LazyChefScaffold(
      bottomNavigationBar: const AppBottomBar(currentIndex: 3),
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
                  Expanded(
                    child: Text(
                      'History',
                      style: Theme.of(context).textTheme.displaySmall,
                    ),
                  ),
                  IconButton.filledTonal(
                    tooltip: 'Refresh',
                    onPressed: () {
                      ref.invalidate(scanHistoryProvider);
                    },
                    icon: const Icon(Icons.refresh_rounded),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filledTonal(
                    tooltip: 'New scan',
                    onPressed: () {
                      Navigator.pushNamedAndRemoveUntil(
                        context,
                        AppRouter.home,
                        (route) => false,
                      );
                    },
                    icon: const Icon(Icons.add_a_photo_outlined),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const SectionTitle(
                eyebrow: 'Past scans',
                title: 'Your saved fridge checks',
                subtitle:
                    'Only scans saved under the current signed-in account appear here.',
              ),
              const SizedBox(height: 20),
              scanHistory.when(
                loading: () => const _HistoryLoading(),
                error: (error, _) => _HistoryError(
                  error: error,
                  onRetry: () {
                    ref.invalidate(scanHistoryProvider);
                  },
                ),
                data: (scans) {
                  if (scans.isEmpty) {
                    return const _EmptyHistory();
                  }

                  return _HistoryEntries(scans: scans);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HistoryEntries extends StatelessWidget {
  const _HistoryEntries({required this.scans});

  final List<HistoryScan> scans;

  @override
  Widget build(BuildContext context) {
    final widgets = <Widget>[];
    String? previousDay;

    for (final scan in scans) {
      final dayLabel = _dayLabel(scan.createdDate);
      if (dayLabel != previousDay) {
        widgets.add(
          Padding(
            padding: const EdgeInsets.only(top: 10, bottom: 12),
            child: Text(
              dayLabel,
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(color: const Color(0xFFC85D3B)),
            ),
          ),
        );
        previousDay = dayLabel;
      }

      widgets.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: _HistoryScanCard(scan: scan),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: widgets,
    );
  }
}

class _HistoryScanCard extends StatelessWidget {
  const _HistoryScanCard({required this.scan});

  final HistoryScan scan;

  @override
  Widget build(BuildContext context) {
    final ingredients = scan.detectedIngredients;
    final recipes = scan.recipeSuggestions;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _ScanThumbnail(imageUrl: scan.imageUrl),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        scan.title,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _timeLabel(scan.createdDate),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: const Color(0xFF6A5D51),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            if (ingredients.isEmpty)
              Text(
                'No ingredients were detected for this scan.',
                style: Theme.of(context).textTheme.bodyMedium,
              )
            else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: ingredients
                    .take(8)
                    .map(
                      (ingredient) => Chip(
                        label: Text(
                          '${ingredient.displayName} ${_confidenceLabel(ingredient.confidence)}',
                        ),
                      ),
                    )
                    .toList(),
              ),
            const SizedBox(height: 14),
            Row(
              children: [
                const Icon(
                  Icons.inventory_2_outlined,
                  size: 18,
                  color: Color(0xFF23433C),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${ingredients.length} ingredients saved',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
                if (scan.imageUrl.isNotEmpty)
                  TextButton(
                    onPressed: () => _showScanImage(context, scan),
                    child: const Text('Preview'),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(
                  Icons.menu_book_outlined,
                  size: 18,
                  color: Color(0xFF23433C),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    recipes.isEmpty
                        ? 'Recipe generation pending'
                        : '${recipes.length} recipes generated',
                    style: Theme.of(context).textTheme.bodyMedium,
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

class _ScanThumbnail extends StatelessWidget {
  const _ScanThumbnail({required this.imageUrl});

  final String imageUrl;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: SizedBox(
        width: 72,
        height: 72,
        child: imageUrl.isEmpty
            ? const ColoredBox(
                color: Color(0xFFEDE3D7),
                child: Icon(Icons.image_not_supported_outlined),
              )
            : Image.network(
                imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) {
                  return const ColoredBox(
                    color: Color(0xFFEDE3D7),
                    child: Icon(Icons.broken_image_outlined),
                  );
                },
              ),
      ),
    );
  }
}

class _HistoryLoading extends StatelessWidget {
  const _HistoryLoading();

  @override
  Widget build(BuildContext context) {
    return const Card(
      child: Padding(
        padding: EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Loading saved scans...'),
            SizedBox(height: 14),
            LinearProgressIndicator(),
          ],
        ),
      ),
    );
  }
}

class _HistoryError extends StatelessWidget {
  const _HistoryError({required this.error, required this.onRetry});

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
                    'Could not load history',
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

class _EmptyHistory extends StatelessWidget {
  const _EmptyHistory();

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
                const Icon(
                  Icons.history_toggle_off_rounded,
                  color: Color(0xFFC85D3B),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'No saved scans yet',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              'Scan a shelf to save detected ingredients to this account.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            AppButton.primary(
              label: 'Start scanning',
              icon: Icons.add_a_photo_outlined,
              onPressed: () {
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  AppRouter.home,
                  (route) => false,
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

void _showScanImage(BuildContext context, HistoryScan scan) {
  showDialog<void>(
    context: context,
    builder: (context) {
      return Dialog(
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.network(
            scan.imageUrl,
            fit: BoxFit.contain,
            errorBuilder: (_, _, _) {
              return const Padding(
                padding: EdgeInsets.all(24),
                child: Text('Could not load scan image.'),
              );
            },
          ),
        ),
      );
    },
  );
}

String _dayLabel(DateTime? date) {
  if (date == null) {
    return 'Saved scans';
  }

  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final scanDay = DateTime(date.year, date.month, date.day);
  final difference = today.difference(scanDay).inDays;

  if (difference == 0) {
    return 'Today';
  }
  if (difference == 1) {
    return 'Yesterday';
  }

  return '${date.year}-${_twoDigits(date.month)}-${_twoDigits(date.day)}';
}

String _timeLabel(DateTime? date) {
  if (date == null) {
    return 'Saved scan';
  }

  final hour = date.hour % 12 == 0 ? 12 : date.hour % 12;
  final period = date.hour >= 12 ? 'PM' : 'AM';

  return '$hour:${_twoDigits(date.minute)} $period';
}

String _confidenceLabel(double confidence) {
  if (confidence <= 0) {
    return '';
  }

  return '${(confidence * 100).round()}%';
}

String _twoDigits(int value) => value.toString().padLeft(2, '0');
