import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lazychef/core/api/api_client.dart';
import 'package:lazychef/core/router/app_router.dart';
import 'package:lazychef/features/auth/data/auth_repository.dart';
import 'package:lazychef/features/auth/providers/auth_provider.dart';
import 'package:lazychef/features/home/ui/edit_profile.dart';
import 'package:lazychef/features/recipe/models/recipe_collection_item.dart';
import 'package:lazychef/features/recipe/providers/recipe_collection_provider.dart';

class UserProfileScreen extends ConsumerWidget {
  const UserProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final generatedRecipes = ref.watch(generatedRecipesProvider);
    final favoriteRecipes = ref.watch(favoriteRecipesProvider);
    final generatedRecipeCount = generatedRecipes.asData?.value.length ?? 0;
    final favoriteRecipeCount = favoriteRecipes.asData?.value.length ?? 0;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  _buildHeaderProfile(context, ref),
                  _buildStats(
                    generatedRecipeCount: generatedRecipeCount,
                    favoriteRecipeCount: favoriteRecipeCount,
                  ),
                  const SizedBox(height: 8),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 24),
                    child: Divider(
                      height: 32,
                      thickness: 1,
                      color: Color(0xFFF0F0F0),
                    ),
                  ),
                  // _buildMyPosts(),
                  _buildMenuItems(
                    context,
                    generatedRecipeCount: generatedRecipeCount,
                    favoriteRecipeCount: favoriteRecipeCount,
                  ),
                ],
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.only(top: 16, bottom: 40),
            color: Colors.white,
            child: _buildLogoutButton(context, ref),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderProfile(BuildContext context, WidgetRef ref) {
    final emailAsync = ref.watch(currentUserEmailProvider);
    final userName = emailAsync.when(
      data: (email) => email != null ? email.split('@')[0] : 'User',
      loading: () => 'Loading...',
      error: (error, stackTrace) => 'User',
    );

    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.topCenter,
      children: [
        Container(
          height: 200,
          decoration: const BoxDecoration(
            color: Color(0xFFFFD166),
            image: DecorationImage(
              image: NetworkImage(
                'https://images.unsplash.com/photo-1490818387583-1b5ba4597b24?q=80&w=800&auto=format&fit=crop',
              ),
              fit: BoxFit.cover,
            ),
          ),
        ),

        Positioned(
          top: MediaQuery.of(context).padding.top + 16,
          left: 16,
          child: GestureDetector(
            onTap: () {
              Navigator.pop(context);
            },
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.3),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.arrow_back_ios_new,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
        ),

        Container(
          margin: const EdgeInsets.only(top: 150),
          padding: const EdgeInsets.only(top: 60),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(width: 28),
              Text(
                userName,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),

              const SizedBox(width: 8),

              GestureDetector(
                onTap: () async {
                  final result = await showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (context) => EditProfilePopup(
                      currentName: userName,
                      currentCoverColor: const Color(0xFFFFD166),
                    ),
                  );

                  if (result != null) {
                    final newName = result['name'];
                    final newColor = result['coverColor'];
                    debugPrint('Tên mới: $newName - Màu mới: $newColor');
                  }
                },
                child: const Icon(Icons.edit, size: 20, color: Colors.grey),
              ),
            ],
          ),
        ),

        const Positioned(
          top: 100,
          child: CircleAvatar(
            radius: 50,
            backgroundColor: Colors.white,
            child: CircleAvatar(
              radius: 46,
              backgroundImage: NetworkImage(
                'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcT8I_m_kf6iq8JeoiETm7vX9yKD6DfBIdXEJA&s',
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStats({
    required int generatedRecipeCount,
    required int favoriteRecipeCount,
  }) {
    return Padding(
      padding: const EdgeInsets.only(top: 24, bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildStatItem('$generatedRecipeCount', 'RECIPES'),
          Container(
            width: 1,
            height: 24,
            color: Colors.grey.shade300,
            margin: const EdgeInsets.symmetric(horizontal: 40),
          ),
          _buildStatItem('$favoriteRecipeCount', 'SAVED'),
        ],
      ),
    );
  }

  Widget _buildStatItem(String number, String label) {
    return Row(
      children: [
        Text(
          number,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade400,
            letterSpacing: 1.2,
          ),
        ),
      ],
    );
  }

  // Widget _buildMyPosts() {
  //   return Padding(
  //     padding: const EdgeInsets.only(left: 24),
  //     child: Column(
  //       crossAxisAlignment: CrossAxisAlignment.start,
  //       children: [
  //         const Text(
  //           'My post',
  //           style: TextStyle(
  //             fontSize: 18,
  //             fontWeight: FontWeight.bold,
  //             color: Colors.black87,
  //           ),
  //         ),
  //         const SizedBox(height: 20),
  //         SizedBox(
  //           height: 140,
  //           child: ListView(
  //             scrollDirection: Axis.horizontal,
  //             children: [
  //               _buildPostItem(
  //                 'Salad',
  //                 'https://images.unsplash.com/photo-1482049016688-2d3e1b311543?q=80&w=300&auto=format&fit=crop',
  //               ),
  //               _buildPostItem(
  //                 'pizza handmade',
  //                 'https://images.unsplash.com/photo-1565299624946-b28f40a0ae38?q=80&w=300&auto=format&fit=crop',
  //               ),
  //               _buildPostItem(
  //                 'I am good',
  //                 'https://images.unsplash.com/photo-1484723091791-cdd51a0c0435?q=80&w=300&auto=format&fit=crop',
  //               ),
  //               _buildPostItem(
  //                 'vegetables meal',
  //                 'https://images.unsplash.com/photo-1546069901-ba9599a7e63c?q=80&w=300&auto=format&fit=crop',
  //               ),
  //             ],
  //           ),
  //         ),
  //       ],
  //     ),
  //   );
  // }

  // Widget _buildPostItem(String title, String imageUrl) {
  //   return Container(
  //     width: 100,
  //     margin: const EdgeInsets.only(right: 16),
  //     child: Column(
  //       crossAxisAlignment: CrossAxisAlignment.start,
  //       children: [
  //         Container(
  //           height: 100,
  //           decoration: BoxDecoration(
  //             borderRadius: BorderRadius.circular(12),
  //             image: DecorationImage(
  //               image: NetworkImage(imageUrl),
  //               fit: BoxFit.cover,
  //             ),
  //           ),
  //         ),
  //         const SizedBox(height: 8),
  //         Text(
  //           title,
  //           maxLines: 1,
  //           overflow: TextOverflow.ellipsis,
  //           style: TextStyle(
  //             fontSize: 13,
  //             fontWeight: FontWeight.w600,
  //             color: Colors.grey.shade800,
  //           ),
  //         ),
  //       ],
  //     ),
  //   );
  // }

  Widget _buildMenuItems(
    BuildContext context, {
    required int generatedRecipeCount,
    required int favoriteRecipeCount,
  }) {
    return Column(
      children: [
        _buildMenuItem(
          Icons.folder_outlined,
          'My recipes',
          subtitle: _recipeCountLabel(generatedRecipeCount, 'generated recipe'),
          onTap: () {
            _showRecipeCollectionSheet(
              context: context,
              title: 'My recipes',
              favoritesOnly: false,
            );
          },
        ),
        _buildMenuItem(Icons.history, 'Recently cooked'),
        _buildMenuItem(
          Icons.favorite_border,
          'My collection',
          subtitle: _recipeCountLabel(favoriteRecipeCount, 'saved recipe'),
          onTap: () {
            _showRecipeCollectionSheet(
              context: context,
              title: 'My collection',
              favoritesOnly: true,
            );
          },
        ),
        _buildMenuItem(Icons.shopping_bag_outlined, 'Have bought ingredients'),
      ],
    );
  }

  Widget _buildMenuItem(
    IconData icon,
    String title, {
    String? subtitle,
    VoidCallback? onTap,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
      leading: Icon(icon, color: const Color(0xFFFFB039), size: 26),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w500,
          color: Colors.grey.shade700,
        ),
      ),
      subtitle: subtitle == null
          ? null
          : Text(
              subtitle,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
            ),
      trailing: Icon(
        Icons.chevron_right,
        color: Colors.grey.shade400,
        size: 20,
      ),
      onTap: onTap,
    );
  }

  Widget _buildLogoutButton(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: SizedBox(
        width: double.infinity,
        height: 50,
        child: OutlinedButton.icon(
          onPressed: () async {
            await ref.read(authRepositoryProvider).logout();
            if (context.mounted) {
              Navigator.pushNamedAndRemoveUntil(
                context,
                AppRouter.login,
                (Route<dynamic> route) => false,
              );
            }
          },
          icon: const Icon(Icons.logout, color: Colors.redAccent),
          label: const Text(
            'Log Out',
            style: TextStyle(
              color: Colors.redAccent,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          style: OutlinedButton.styleFrom(
            side: BorderSide(color: Colors.redAccent.shade100, width: 1.5),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            foregroundColor: Colors.redAccent,
          ),
        ),
      ),
    );
  }
}

class _RecipeCollectionSheet extends ConsumerWidget {
  const _RecipeCollectionSheet({
    required this.title,
    required this.favoritesOnly,
  });

  final String title;
  final bool favoritesOnly;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recipesAsync = favoritesOnly
        ? ref
              .watch(favoriteRecipesProvider)
              .whenData((favorites) => favorites.values.toList())
        : ref.watch(generatedRecipesProvider);
    final favoriteRecipes = ref.watch(favoriteRecipesProvider).asData?.value;

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.72,
      minChildSize: 0.35,
      maxChildSize: 0.92,
      builder: (context, scrollController) {
        return SafeArea(
          top: false,
          child: ListView(
            controller: scrollController,
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 28),
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Close',
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              recipesAsync.when(
                loading: () => const _RecipeCollectionLoading(),
                error: (error, _) => _RecipeCollectionError(error: error),
                data: (recipes) {
                  if (recipes.isEmpty) {
                    return _EmptyRecipeCollection(
                      message: favoritesOnly
                          ? 'Favorite a generated recipe to save it here.'
                          : 'Generated recipes from your scans will appear here.',
                    );
                  }

                  return Column(
                    children: recipes.map((recipe) {
                      final isFavorite =
                          favoriteRecipes?.containsKey(recipe.id) ?? false;

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _ProfileRecipeTile(
                          recipe: recipe,
                          isFavorite: isFavorite,
                          onFavoritePressed: () {
                            ref
                                .read(favoriteRecipesProvider.notifier)
                                .toggleFavorite(recipe);
                          },
                          onTap: () {
                            _showRecipeDetails(
                              context,
                              ref,
                              recipe,
                              isFavorite,
                            );
                          },
                        ),
                      );
                    }).toList(),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ProfileRecipeTile extends StatelessWidget {
  const _ProfileRecipeTile({
    required this.recipe,
    required this.isFavorite,
    required this.onFavoritePressed,
    this.onTap,
  });

  final RecipeCollectionItem recipe;
  final bool isFavorite;
  final VoidCallback onFavoritePressed;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFFFFBF2),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFF1E7D2)),
        ),
        child: Row(
          children: [
            _RecipeCollectionImage(imageUrl: recipe.imageUrl),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    recipe.title.isEmpty ? 'Generated recipe' : recipe.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _recipeMetaLabel(recipe),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
            IconButton(
              tooltip: isFavorite ? 'Remove from collection' : 'Save',
              onPressed: onFavoritePressed,
              icon: Icon(
                isFavorite ? Icons.favorite : Icons.favorite_border,
                color: isFavorite
                    ? const Color(0xFFE85D3F)
                    : Colors.grey.shade500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RecipeCollectionImage extends StatelessWidget {
  const _RecipeCollectionImage({required this.imageUrl, this.size = 72});

  final String? imageUrl;
  final double size;

  @override
  Widget build(BuildContext context) {
    final url = imageUrl?.trim() ?? '';
    final resolvedUrl = _resolveRecipeImageUrl(url);

    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: SizedBox(
        width: size,
        height: size,
        child: resolvedUrl.isEmpty
            ? const ColoredBox(
                color: Color(0xFFF1E7D2),
                child: Icon(Icons.restaurant_menu_rounded),
              )
            : Image.network(
                resolvedUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) {
                  return const ColoredBox(
                    color: Color(0xFFF1E7D2),
                    child: Icon(Icons.restaurant_menu_rounded),
                  );
                },
              ),
      ),
    );
  }
}

class _RecipeCollectionLoading extends StatelessWidget {
  const _RecipeCollectionLoading();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 24),
      child: Center(child: CircularProgressIndicator()),
    );
  }
}

class _RecipeCollectionError extends StatelessWidget {
  const _RecipeCollectionError({required this.error});

  final Object error;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.redAccent.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        error.toString(),
        style: const TextStyle(color: Colors.redAccent),
      ),
    );
  }
}

class _EmptyRecipeCollection extends StatelessWidget {
  const _EmptyRecipeCollection({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBF2),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFF1E7D2)),
      ),
      child: Row(
        children: [
          const Icon(Icons.restaurant_menu_rounded, color: Color(0xFFFFB039)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(message, style: TextStyle(color: Colors.grey.shade700)),
          ),
        ],
      ),
    );
  }
}

void _showRecipeCollectionSheet({
  required BuildContext context,
  required String title,
  required bool favoritesOnly,
}) {
  showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    builder: (context) {
      return _RecipeCollectionSheet(title: title, favoritesOnly: favoritesOnly);
    },
  );
}

void _showRecipeDetails(
  BuildContext context,
  WidgetRef ref,
  RecipeCollectionItem recipe,
  bool initialIsFavorite,
) {
  showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    backgroundColor: const Color(0xFFF7F8FA),
    builder: (context) {
      return Consumer(
        builder: (context, ref, _) {
          final isFavorite =
              ref
                  .watch(favoriteRecipesProvider)
                  .asData
                  ?.value
                  .containsKey(recipe.id) ??
              initialIsFavorite;

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
                  Center(
                    child: _RecipeCollectionImage(
                      imageUrl: recipe.imageUrl,
                      size: 180,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Center(
                    child: Text(
                      recipe.title.isEmpty ? 'Generated recipe' : recipe.title,
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
                  Center(
                    child: TextButton.icon(
                      onPressed: () {
                        ref
                            .read(favoriteRecipesProvider.notifier)
                            .toggleFavorite(recipe);
                      },
                      icon: Icon(
                        isFavorite ? Icons.favorite : Icons.favorite_border,
                        color: const Color(0xFFE85D3F),
                      ),
                      label: Text(isFavorite ? 'Saved' : 'Save recipe'),
                    ),
                  ),
                  const SizedBox(height: 8),
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
                            recipe.cookingTime.isEmpty
                                ? 'Timing pending'
                                : recipe.cookingTime,
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
                  Text(
                    'Description:',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(recipe.description, textAlign: TextAlign.center),
                  const SizedBox(height: 24),
                  if (recipe.missingIngredients.isNotEmpty) ...[
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
                      children: recipe.missingIngredients.map((ingredient) {
                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: Text(
                            ingredient,
                            style: const TextStyle(fontWeight: FontWeight.w500),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 20),
                  ],
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
                    child: Text(
                      recipe.instructions,
                      style: Theme.of(
                        context,
                      ).textTheme.bodyMedium?.copyWith(height: 1.45),
                    ),
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

String _recipeCountLabel(int count, String singularLabel) {
  if (count == 1) {
    return '1 $singularLabel';
  }

  return '$count ${singularLabel}s';
}

String _resolveRecipeImageUrl(String url) {
  if (url.isEmpty) {
    return '';
  }

  final lowerUrl = url.toLowerCase();
  if (lowerUrl.startsWith('http://') ||
      lowerUrl.startsWith('https://') ||
      lowerUrl.startsWith('data:')) {
    return url;
  }

  return Uri.parse(apiBaseUrl).resolve(url).toString();
}

String _recipeMetaLabel(RecipeCollectionItem recipe) {
  final parts = <String>[
    recipe.cookingTime.isEmpty ? 'Timing pending' : recipe.cookingTime,
    recipe.difficultyLabel,
  ];

  if (recipe.missingIngredients.isNotEmpty) {
    parts.add('${recipe.missingIngredients.length} missing');
  }

  return parts.join(' | ');
}
