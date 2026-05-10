import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lazychef/core/router/app_router.dart';
import 'package:lazychef/core/widgets/app_bottom_bar.dart';
import 'package:lazychef/core/widgets/app_button.dart';
import 'package:lazychef/features/recipe/models/suggested_recipe.dart';
import 'package:lazychef/features/recipe/providers/recipe_provider.dart';

class RecipeScreen extends ConsumerWidget {
  const RecipeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final suggestedRecipes = ref.watch(suggestedRecipesProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      bottomNavigationBar: const AppBottomBar(currentIndex: 1),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 32),
              _buildGreeting(),
              const SizedBox(height: 24),
              _buildSearchBar(context),
              const SizedBox(height: 24),
              _buildCategories(),
              const SizedBox(height: 32),
              _buildMatchYourFridge(context, ref, suggestedRecipes),
              const SizedBox(height: 32),
              _buildTrendingRecipes(context),
              const SizedBox(height: 32),
              _buildMostViewedRecipes(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGreeting() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        const Text(
          'Make your own food,\nstay at home',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            height: 1.2,
          ),
        ),
      ],
    );
  }

  Widget _buildSearchBar(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: () {
              Navigator.pushNamed(context, AppRouter.search);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Icon(Icons.search, color: Colors.grey.shade400),
                  const SizedBox(width: 12),
                  Text(
                    'Find your today recipe',
                    style: TextStyle(color: Colors.grey.shade400),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFFFD166),
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Icon(Icons.tune),
        ),
      ],
    );
  }

  Widget _buildCategories() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _buildCategoryChip('All', Icons.all_inbox, true),
          const SizedBox(width: 16),
          _buildCategoryChip('Fast Food', Icons.fastfood, false),
          const SizedBox(width: 16),
          _buildCategoryChip('Japanese', Icons.set_meal, false),
        ],
      ),
    );
  }

  Widget _buildCategoryChip(String label, IconData icon, bool isSelected) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: isSelected ? const Color(0xFFFFD166) : const Color(0xFFFFF8E7),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            size: 20,
            color: isSelected ? Colors.black87 : Colors.orange,
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: isSelected ? Colors.black87 : Colors.black54,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMatchYourFridge(
    BuildContext context,
    WidgetRef ref,
    AsyncValue<SuggestedRecipesResponse> suggestedRecipes,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                'Match Your Latest Scan',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ),
            IconButton(
              tooltip: 'Refresh',
              onPressed: () {
                ref.invalidate(suggestedRecipesProvider);
              },
              icon: const Icon(Icons.refresh_rounded),
            ),
          ],
        ),
        const SizedBox(height: 16),
        suggestedRecipes.when(
          loading: () => const _SuggestedRecipesLoading(),
          error: (error, _) => _SuggestedRecipesError(
            error: error,
            onRetry: () {
              ref.invalidate(suggestedRecipesProvider);
            },
          ),
          data: (response) {
            if (response.recipes.isEmpty && response.retryable) {
              return _RetryableRecipeEmpty(
                onRetry: () {
                  ref.invalidate(suggestedRecipesProvider);
                },
              );
            }

            if (response.recipes.isEmpty) {
              return const _NoSuggestedRecipes();
            }

            return SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: response.recipes.asMap().entries.map((entry) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 16),
                    child: _SuggestedRecipeCard(
                      recipe: entry.value,
                      color: _suggestedRecipeColor(entry.key),
                      onTap: () => _showSuggestedRecipe(
                        context,
                        entry.value,
                        response.ingredients,
                      ),
                    ),
                  );
                }).toList(),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildTrendingRecipes(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Trending Recipes',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _buildRecipeCard(
                'Noodles with shrimp',
                '4.9',
                'https://images.unsplash.com/photo-1569718212165-3a8278d5f624?q=80&w=500&auto=format&fit=crop',
                onTap: () {
                  Navigator.pushNamed(context, AppRouter.recipeDetail);
                },
              ),
              const SizedBox(width: 16),
              _buildRecipeCard(
                'Oats with Strawberry\nand milk',
                '4.8',
                'https://images.unsplash.com/photo-1517673132405-a56a62b18caf?q=80&w=500&auto=format&fit=crop',
                onTap: () {
                  Navigator.pushNamed(context, AppRouter.recipeDetail);
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRecipeCard(
    String title,
    String rating,
    String imageUrl, {
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 220,
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 140,
              decoration: BoxDecoration(
                color: const Color(0xFFEFEFEF),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(24),
                ),
                image: DecorationImage(
                  image: NetworkImage(imageUrl),
                  fit: BoxFit.cover,
                ),
              ),
              child: Stack(
                children: [
                  Positioned(
                    top: 12,
                    right: 12,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.bookmark_border, size: 16),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const CircleAvatar(
                            radius: 10,
                            backgroundColor: Colors.grey,
                            child: Icon(Icons.person, size: 12),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Riya Ghosh',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFD166),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.star, size: 12),
                            const SizedBox(width: 4),
                            Text(
                              rating,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMostViewedRecipes() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Most Viewed Recipes',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Row(
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(16),
                  image: const DecorationImage(
                    image: NetworkImage(
                      'https://images.unsplash.com/photo-1556881286-fc6915169721?q=80&w=500&auto=format&fit=crop',
                    ),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Morning Shake with\nMango Slice and Cream',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        Icon(Icons.bookmark_border, size: 20),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const CircleAvatar(
                              radius: 10,
                              backgroundColor: Colors.grey,
                              child: Icon(Icons.person, size: 12),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Riya Ghosh',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFD166),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.star, size: 12),
                              SizedBox(width: 4),
                              Text(
                                '4.9',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SuggestedRecipeCard extends StatelessWidget {
  const _SuggestedRecipeCard({
    required this.recipe,
    required this.color,
    required this.onTap,
  });

  final SuggestedRecipe recipe;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 180,
        height: 286,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 20),
                Container(
                  width: 100,
                  height: 100,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.restaurant_menu_rounded),
                ),
                const SizedBox(height: 16),
                Text(
                  recipe.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: Colors.black87,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 10),
                // Text(
                //   recipe.description,
                //   maxLines: 2,
                //   overflow: TextOverflow.ellipsis,
                //   style: TextStyle(
                //     color: Colors.grey.shade800,
                //     fontSize: 12,
                //     height: 1.35,
                //   ),
                // ),
              ],
            ),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _RecipePill(
                  icon: Icons.schedule_rounded,
                  label: recipe.cookingTime.isEmpty
                      ? 'Timing pending'
                      : recipe.cookingTime,
                ),
                _RecipePill(
                  icon: Icons.local_fire_department_outlined,
                  label: recipe.difficultyLabel,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _RecipePill extends StatelessWidget {
  const _RecipePill({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}

class _SuggestedRecipesLoading extends StatelessWidget {
  const _SuggestedRecipesLoading();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(18),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Generating recipes from your latest scan...'),
          SizedBox(height: 14),
          LinearProgressIndicator(),
        ],
      ),
    );
  }
}

class _SuggestedRecipesError extends StatelessWidget {
  const _SuggestedRecipesError({required this.error, required this.onRetry});

  final Object error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final needsSignIn = error.toString().contains('sign in');

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Could not load suggestions',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(error.toString()),
          const SizedBox(height: 14),
          AppButton.secondary(
            label: needsSignIn ? 'Sign in' : 'Retry',
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
    );
  }
}

class _RetryableRecipeEmpty extends StatelessWidget {
  const _RetryableRecipeEmpty({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Something went wrong',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text('Recipe generation failed for your latest scan.'),
          const SizedBox(height: 14),
          AppButton.secondary(
            label: 'Retry',
            icon: Icons.refresh_rounded,
            onPressed: onRetry,
          ),
        ],
      ),
    );
  }
}

class _NoSuggestedRecipes extends StatelessWidget {
  const _NoSuggestedRecipes();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(18),
      ),
      child: const Row(
        children: [
          Icon(Icons.restaurant_menu_rounded),
          SizedBox(width: 10),
          Expanded(child: Text('Scan ingredients to get recipe suggestions.')),
        ],
      ),
    );
  }
}

Widget _buildIngredientItem(
  String name,
  String amount,
  Color color,
  IconData icon,
) {
  return Container(
    width: 100,
    margin: const EdgeInsets.only(bottom: 8),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 80, // Tăng chiều rộng ô vuông (cũ là 60)
          height: 80, // Tăng chiều cao ô vuông (cũ là 60)
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(
              20,
            ), // Bo góc to hơn chút cho cân đối
          ),
          child: Icon(
            icon,
            color: Colors.black54,
            size: 36,
          ), // Tăng size icon (cũ là 28)
        ),
        const SizedBox(height: 10),
        Text(
          name,
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ), // Tăng size chữ
        ),
        const SizedBox(height: 4),
        Text(
          amount,
          style: TextStyle(
            color: Colors.grey.shade600,
            fontSize: 13,
          ), // Tăng size chữ
        ),
      ],
    ),
  );
}

void _showSuggestedRecipe(
  BuildContext context,
  SuggestedRecipe recipe,
  List<SuggestedIngredient> allIngredients,
) {
  showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    backgroundColor: const Color(0xFFF7F8FA),
    builder: (context) {
      var showAllIngredients = false;

      return StatefulBuilder(
        builder: (BuildContext context, StateSetter setState) {
          return DraggableScrollableSheet(
            expand: false,
            initialChildSize: 0.72,
            minChildSize: 0.45,
            maxChildSize: 0.92,
            builder: (context, scrollController) {
              return ListView(
                controller: scrollController,
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 28),
                children: [
                  // Hình ảnh recipe
                  Center(
                    child: Container(
                      width: 180,
                      height: 180,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 24,
                            offset: const Offset(0, 12),
                          ),
                        ],
                        image: const DecorationImage(
                          image: NetworkImage(
                            'https://images.unsplash.com/photo-1569718212165-3a8278d5f624?q=80&w=500&auto=format&fit=crop',
                          ),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Tiêu đề
                  Center(
                    child: Text(
                      recipe.title,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w600,
                        height: 1.3,
                        color: Color(0xFF2C3236),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Stats (Thời gian và độ khó)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.access_time_rounded,
                            color: Colors.grey,
                            size: 25,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            recipe.cookingTime,
                            style: const TextStyle(
                              color: Colors.grey,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 48),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.speed_rounded,
                            color: Colors.grey,
                            size: 25,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            recipe.difficultyLabel,
                            style: const TextStyle(
                              color: Colors.grey,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 24),
                    child: Divider(
                      height: 32,
                      thickness: 1,
                      color: Color.fromARGB(255, 226, 226, 226),
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Mô tả
                  Text(
                    'Description:',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(recipe.description, textAlign: TextAlign.center),
                  const SizedBox(height: 24),

                  // Danh sách nguyên liệu
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'All ingredients',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF2C3236),
                        ),
                      ),
                      if (allIngredients.isNotEmpty)
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              showAllIngredients = !showAllIngredients;
                            });
                          },
                          child: Text(
                            showAllIngredients ? 'Show less' : 'See all',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFFFF7E5F),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  if (allIngredients.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: const Text(
                        'No detected ingredients were saved for this scan.',
                        textAlign: TextAlign.center,
                      ),
                    )
                  else if (showAllIngredients)
                    Wrap(
                      spacing: 16,
                      runSpacing: 24,
                      children: allIngredients.asMap().entries.map((entry) {
                        final ingredient = entry.value;

                        return _buildIngredientItem(
                          ingredient.displayName,
                          ingredient.confidenceLabel,
                          _ingredientColor(entry.key),
                          _ingredientIcon(entry.key),
                        );
                      }).toList(),
                    )
                  else
                    SizedBox(
                      height: 160,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        clipBehavior: Clip.none,
                        itemCount: allIngredients.length,
                        itemBuilder: (context, index) {
                          final ingredient = allIngredients[index];

                          return Padding(
                            padding: const EdgeInsets.only(right: 16.0),
                            child: _buildIngredientItem(
                              ingredient.displayName,
                              ingredient.confidenceLabel,
                              _ingredientColor(index),
                              _ingredientIcon(index),
                            ),
                          );
                        },
                      ),
                    ),
                  const SizedBox(height: 30),

                  // Nguyên liệu bị thiếu
                  if (recipe.missingIngredients.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    Center(
                      child: Text(
                        'Missing ingredients',
                        style: Theme.of(context).textTheme.titleMedium,
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 16,
                      runSpacing: 24,
                      children: recipe.missingIngredients.asMap().entries.map((
                        entry,
                      ) {
                        final ingredient = entry.value;

                        return _buildIngredientItem(
                          _formatIngredientName(ingredient),
                          'Needed',
                          _ingredientColor(entry.key + allIngredients.length),
                          _ingredientIcon(entry.key + allIngredients.length),
                        );
                      }).toList(),
                    ),
                  ],
                  const SizedBox(height: 20),

                  Center(
                    child: Text(
                      'Instructions',
                      style: Theme.of(context).textTheme.titleMedium,
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: _InstructionText(recipe.instructions),
                  ),
                ],
              );
            },
          );
        },
      );
    },
  );
}

class _InstructionText extends StatelessWidget {
  const _InstructionText(this.instructions);

  final String instructions;

  @override
  Widget build(BuildContext context) {
    final baseStyle = Theme.of(
      context,
    ).textTheme.bodyMedium?.copyWith(height: 1.45);
    final numberStyle = baseStyle?.copyWith(
      color: const Color(0xFFE85D3F),
      fontWeight: FontWeight.w800,
    );

    return RichText(
      textAlign: TextAlign.left,
      text: TextSpan(
        style: baseStyle,
        children: _instructionSpans(instructions, numberStyle),
      ),
    );
  }
}

List<InlineSpan> _instructionSpans(
  String instructions,
  TextStyle? numberStyle,
) {
  final normalized = instructions.trim().replaceAllMapped(
    RegExp(r'\s+(\d+\.\s+)'),
    (match) => '\n${match.group(1)}',
  );
  final spans = <InlineSpan>[];
  final numberPattern = RegExp(r'(^|\n)(\d+\.)\s*');
  var cursor = 0;

  for (final match in numberPattern.allMatches(normalized)) {
    if (match.start > cursor) {
      spans.add(TextSpan(text: normalized.substring(cursor, match.start)));
    }

    spans.add(TextSpan(text: match.group(1)));
    spans.add(TextSpan(text: '${match.group(2)} ', style: numberStyle));
    cursor = match.end;
  }

  if (cursor < normalized.length) {
    spans.add(TextSpan(text: normalized.substring(cursor)));
  }

  return spans;
}

String _formatIngredientName(String name) {
  if (name.isEmpty) {
    return 'Ingredient';
  }

  return name
      .split(' ')
      .where((part) => part.isNotEmpty)
      .map((part) => '${part[0].toUpperCase()}${part.substring(1)}')
      .join(' ');
}

Color _suggestedRecipeColor(int index) {
  const colors = [
    Color(0xFFFFDF9E),
    Color(0xFFDCEAD8),
    Color(0xFFF4D6C8),
    Color(0xFFE7E1D4),
    Color(0xFFD7E6EB),
  ];

  return colors[index % colors.length];
}

Color _ingredientColor(int index) {
  const colors = [
    Color(0xFFFFCDD2),
    Color(0xFFD7CCC8),
    Color(0xFFFFF9C4),
    Color(0xFFC8E6C9),
    Color(0xFFBBDEFB),
    Color(0xFFFFE0B2),
  ];

  return colors[index % colors.length];
}

IconData _ingredientIcon(int index) {
  const icons = [
    Icons.restaurant_menu_rounded,
    Icons.set_meal,
    Icons.eco,
    Icons.egg_alt_outlined,
    Icons.local_pizza,
    Icons.rice_bowl_outlined,
  ];

  return icons[index % icons.length];
}
