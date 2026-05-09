import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lazychef/core/router/app_router.dart';
import 'package:lazychef/core/widgets/app_button.dart';
import 'package:lazychef/core/widgets/lazychef_scaffold.dart';
import 'package:lazychef/core/widgets/section_title.dart';
import 'package:lazychef/features/scan/models/scan_image_selection.dart';
import 'package:lazychef/features/scan/models/scan_upload_result.dart';
import 'package:lazychef/features/scan/providers/scan_provider.dart';
import 'package:lazychef/features/scan/ui/demo_content.dart';

class ScanResultScreen extends ConsumerWidget {
  const ScanResultScreen({super.key, this.selection});

  final ScanImageSelection? selection;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scanUpload = selection == null
        ? null
        : ref.watch(scanUploadProvider(selection!));

    return LazyChefScaffold(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 18, 24, 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                IconButton.filledTonal(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.arrow_back_rounded),
                ),
                const Spacer(),
                TextButton.icon(
                  onPressed: () {
                    Navigator.pushNamed(context, AppRouter.history);
                  },
                  icon: const Icon(Icons.history_rounded),
                  label: const Text('History'),
                ),
              ],
            ),
            const SizedBox(height: 14),
            const SectionTitle(
              eyebrow: 'Scan result',
              title: 'Your fridge looks promising',
              subtitle:
                  'Detected ingredients are ready to review before saving this scan.',
            ),
            const SizedBox(height: 18),
            if (selection != null) ...[
              _SelectedImagePreview(selection: selection!),
              const SizedBox(height: 18),
            ],
            if (scanUpload == null)
              const _DemoScanContent()
            else
              scanUpload.when(
                loading: () => const _ScanUploadLoading(),
                error: (error, _) => _ScanUploadError(
                  error: error,
                  onRetry: () {
                    ref.invalidate(scanUploadProvider(selection!));
                  },
                ),
                data: (result) => _UploadedScanContent(result: result),
              ),
            const SizedBox(height: 8),
            AppButton.primary(
              label: 'Save and open history',
              icon: Icons.bookmark_added_outlined,
              onPressed: () {
                Navigator.pushNamed(context, AppRouter.history);
              },
            ),
            const SizedBox(height: 12),
            AppButton.secondary(
              label: 'Scan another shelf',
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

class _DemoScanContent extends StatelessWidget {
  const _DemoScanContent();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _ScanSummaryCard(
          eyebrow: '5 ingredients detected',
          title: 'Two strong dinner options are ready from this shelf.',
          icon: Icons.soup_kitchen_rounded,
        ),
        const SizedBox(height: 28),
        const SectionTitle(
          eyebrow: 'Detected ingredients',
          title: 'Confidence is shown directly',
        ),
        const SizedBox(height: 14),
        ...demoIngredients.map(
          (ingredient) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _IngredientTile(ingredient: ingredient),
          ),
        ),
        const SizedBox(height: 18),
        const SectionTitle(
          eyebrow: 'Recipe suggestions',
          title: 'Use what is already there',
        ),
        const SizedBox(height: 14),
        ...demoRecipes.map(
          (recipe) => Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: _RecipeCard(recipe: recipe),
          ),
        ),
      ],
    );
  }
}

class _UploadedScanContent extends StatelessWidget {
  const _UploadedScanContent({required this.result});

  final ScanUploadResult result;

  @override
  Widget build(BuildContext context) {
    final ingredients = result.analysis.detectedIngredients;
    final ingredientCount = ingredients.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _ScanSummaryCard(
          eyebrow: ingredientCount == 1
              ? '1 ingredient detected'
              : '$ingredientCount ingredients detected',
          title: result.analysis.status == 'pending'
              ? 'Image uploaded. AI analysis placeholder is connected.'
              : 'Image uploaded and analysis completed.',
          icon: Icons.cloud_done_rounded,
        ),
        const SizedBox(height: 16),
        _UploadDetailsCard(result: result),
        const SizedBox(height: 28),
        const SectionTitle(
          eyebrow: 'Detected ingredients',
          title: 'Backend analysis response',
        ),
        const SizedBox(height: 14),
        if (ingredients.isEmpty)
          _EmptyIngredientsCard(analysis: result.analysis)
        else
          ...ingredients.map(
            (ingredient) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _DetectedIngredientTile(ingredient: ingredient),
            ),
          ),
        const SizedBox(height: 18),
        const SectionTitle(
          eyebrow: 'Recipe suggestions',
          title: 'Waiting for recipe generation',
          subtitle:
              'This will be connected after the AI ingredient response is real.',
        ),
      ],
    );
  }
}

class _ScanUploadLoading extends StatelessWidget {
  const _ScanUploadLoading();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _ScanSummaryCard(
          eyebrow: 'Uploading scan',
          title: 'Uploading image...',
          icon: Icons.sync_rounded,
        ),
        SizedBox(height: 16),
        LinearProgressIndicator(),
        SizedBox(height: 28),
      ],
    );
  }
}

class _ScanUploadError extends StatelessWidget {
  const _ScanUploadError({required this.error, required this.onRetry});

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
                    'Scan upload failed',
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

class _ScanSummaryCard extends StatelessWidget {
  const _ScanSummaryCard({
    required this.eyebrow,
    required this.title,
    required this.icon,
  });

  final String eyebrow;
  final String title;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFC85D3B), Color(0xFFE2A13B)],
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  eyebrow,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  title,
                  style: Theme.of(
                    context,
                  ).textTheme.headlineMedium?.copyWith(color: Colors.white),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Container(
            width: 74,
            height: 74,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.22),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: Colors.white, size: 34),
          ),
        ],
      ),
    );
  }
}

class _UploadDetailsCard extends StatelessWidget {
  const _UploadDetailsCard({required this.result});

  final ScanUploadResult result;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Cloudinary upload',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 10),
            Text(
              result.image.secureUrl,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: const Color(0xFF6A5D51)),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _metadataPill(result.image.format.toUpperCase()),
                _metadataPill('${result.image.width} x ${result.image.height}'),
                _metadataPill('${(result.image.bytes / 1024).round()} KB'),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyIngredientsCard extends StatelessWidget {
  const _EmptyIngredientsCard({required this.analysis});

  final VisionAnalysis analysis;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${analysis.model} placeholder',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              analysis.message,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: const Color(0xFF6A5D51)),
            ),
          ],
        ),
      ),
    );
  }
}

class _SelectedImagePreview extends StatelessWidget {
  const _SelectedImagePreview({required this.selection});

  final ScanImageSelection selection;

  @override
  Widget build(BuildContext context) {
    final sourceLabel = selection.source == ImageSource.camera
        ? 'Camera photo'
        : 'Gallery photo';

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AspectRatio(
            aspectRatio: 16 / 10,
            child: FutureBuilder<Uint8List>(
              future: selection.image.readAsBytes(),
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  return Image.memory(
                    snapshot.data!,
                    fit: BoxFit.cover,
                    width: double.infinity,
                  );
                }

                if (snapshot.hasError) {
                  return const ColoredBox(
                    color: Color(0xFFEADBC9),
                    child: Center(
                      child: Icon(Icons.broken_image_outlined, size: 36),
                    ),
                  );
                }

                return const ColoredBox(
                  color: Color(0xFFEADBC9),
                  child: Center(child: CircularProgressIndicator()),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Icon(
                  Icons.image_search_rounded,
                  color: Color(0xFFC85D3B),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    '$sourceLabel selected for ingredient detection',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DetectedIngredientTile extends StatelessWidget {
  const _DetectedIngredientTile({required this.ingredient});

  final DetectedIngredient ingredient;

  @override
  Widget build(BuildContext context) {
    final percentage = (ingredient.confidence * 100).round();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            Expanded(
              child: Text(
                ingredient.name,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            Text(
              '$percentage%',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(color: const Color(0xFFC85D3B)),
            ),
          ],
        ),
      ),
    );
  }
}

class _IngredientTile extends StatelessWidget {
  const _IngredientTile({required this.ingredient});

  final IngredientInsight ingredient;

  @override
  Widget build(BuildContext context) {
    final percentage = (ingredient.confidence * 100).round();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    ingredient.name,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                Text(
                  '$percentage%',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: const Color(0xFFC85D3B),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                value: ingredient.confidence,
                minHeight: 10,
                backgroundColor: const Color(0xFFEADBC9),
                color: const Color(0xFF23433C),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RecipeCard extends StatelessWidget {
  const _RecipeCard({required this.recipe});

  final RecipePreview recipe;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _pill(recipe.duration),
                _pill(recipe.difficulty),
                ...recipe.ingredients.take(3).map(_pill),
              ],
            ),
            const SizedBox(height: 16),
            Text(recipe.title, style: textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(
              recipe.description,
              style: textTheme.bodyMedium?.copyWith(
                color: const Color(0xFF6A5D51),
              ),
            ),
            const SizedBox(height: 16),
            ...recipe.steps.asMap().entries.map(
              (entry) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: const Color(0xFF23433C),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        '${entry.key + 1}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(entry.value, style: textTheme.bodyMedium),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _pill(String label) {
    return _metadataPill(label);
  }
}

Widget _metadataPill(String label) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: const Color(0xFFCAD3CA)),
    ),
    child: Text(
      label,
      style: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        color: Color(0xFF2D241D),
      ),
    ),
  );
}
