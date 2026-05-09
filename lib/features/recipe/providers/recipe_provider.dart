import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lazychef/features/recipe/data/recipe_repository.dart';
import 'package:lazychef/features/recipe/models/suggested_recipe.dart';

final suggestedRecipesProvider =
    FutureProvider.autoDispose<SuggestedRecipesResponse>((ref) async {
      final repository = ref.watch(recipeRepositoryProvider);
      return repository.fetchSuggestedRecipes();
    }, retry: (_, _) => null);
