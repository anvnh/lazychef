import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lazychef/features/history/providers/history_provider.dart';
import 'package:lazychef/features/recipe/data/recipe_repository.dart';
import 'package:lazychef/features/recipe/models/recipe_collection_item.dart';

final generatedRecipesProvider =
    FutureProvider.autoDispose<List<RecipeCollectionItem>>((ref) async {
      final scans = await ref.watch(scanHistoryProvider.future);
      final recipesById = <String, RecipeCollectionItem>{};

      for (final scan in scans) {
        for (final recipe in scan.recipeSuggestions) {
          final item = RecipeCollectionItem.fromHistory(
            recipe: recipe,
            scan: scan,
          );
          if (item.id.isNotEmpty) {
            recipesById[item.id] = item;
          }
        }
      }

      return recipesById.values.toList();
    }, retry: (_, _) => null);

final mostViewedRecipesProvider =
    FutureProvider.autoDispose<List<RecipeCollectionItem>>((ref) async {
      final repository = ref.watch(recipeRepositoryProvider);
      return repository.fetchMostViewedRecipes();
    }, retry: (_, _) => null);

final favoriteRecipesProvider =
    AsyncNotifierProvider<
      FavoriteRecipesController,
      Map<String, RecipeCollectionItem>
    >(FavoriteRecipesController.new);

class FavoriteRecipesController
    extends AsyncNotifier<Map<String, RecipeCollectionItem>> {
  @override
  FutureOr<Map<String, RecipeCollectionItem>> build() async {
    final repository = ref.watch(recipeRepositoryProvider);
    final recipes = await repository.fetchFavoriteRecipes();
    final favorites = <String, RecipeCollectionItem>{};

    for (final item in recipes) {
      if (item.id.isNotEmpty) {
        favorites[item.id] = item;
      }
    }

    return favorites;
  }

  Future<void> toggleFavorite(RecipeCollectionItem recipe) async {
    if (recipe.id.isEmpty) {
      return;
    }

    final currentFavorites = Map<String, RecipeCollectionItem>.from(
      state.asData?.value ?? const {},
    );

    if (currentFavorites.containsKey(recipe.id)) {
      currentFavorites.remove(recipe.id);
      state = AsyncData(Map.unmodifiable(currentFavorites));
      await ref.read(recipeRepositoryProvider).removeFavoriteRecipe(recipe.id);
    } else {
      final savedRecipe = await ref
          .read(recipeRepositoryProvider)
          .addFavoriteRecipe(recipe.id);
      currentFavorites[recipe.id] = savedRecipe;
      state = AsyncData(Map.unmodifiable(currentFavorites));
    }
  }
}
