import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lazychef/core/router/app_router.dart';
import 'package:lazychef/core/widgets/app_button.dart';
import 'package:lazychef/core/widgets/lazychef_scaffold.dart';
import 'package:lazychef/core/widgets/section_title.dart';
import 'package:lazychef/features/scan/models/scan_image_selection.dart';
import 'package:lazychef/features/scan/ui/demo_content.dart';

class ScanResultScreen extends StatelessWidget {
  const ScanResultScreen({super.key, this.selection});

  final ScanImageSelection? selection;

  @override
  Widget build(BuildContext context) {
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
            Container(
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
                        const Text(
                          '5 ingredients detected',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Two strong dinner options are ready from this shelf.',
                          style: Theme.of(context).textTheme.headlineMedium
                              ?.copyWith(color: Colors.white),
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
                    child: const Icon(
                      Icons.soup_kitchen_rounded,
                      color: Colors.white,
                      size: 34,
                    ),
                  ),
                ],
              ),
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
}
