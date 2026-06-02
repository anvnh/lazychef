import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lazychef/core/api/api_client.dart';
import 'package:lazychef/features/recipe/models/recipe_collection_item.dart';
import 'package:lazychef/features/recipe/models/suggested_recipe.dart';

final recipeRepositoryProvider = Provider<RecipeRepository>((ref) {
  return RecipeRepository(ref.watch(dioProvider));
});

class RecipeRepository {
  const RecipeRepository(this._dio);

  final Dio _dio;

  Future<SuggestedRecipesResponse> fetchSuggestedRecipes() async {
    try {
      final response = await _dio.get<dynamic>('/recipes/suggest');
      final data = response.data;

      if (data is List) {
        return SuggestedRecipesResponse(
          recipes: data
              .whereType<Map>()
              .map((recipe) => Map<String, dynamic>.from(recipe))
              .map(SuggestedRecipe.fromJson)
              .toList(),
          ingredients: const [],
          retryable: false,
        );
      }

      if (data is Map) {
        final map = Map<String, dynamic>.from(data);
        final recipes = map['recipes'];
        final ingredients = map['ingredients'];

        return SuggestedRecipesResponse(
          recipes: recipes is List
              ? recipes
                    .whereType<Map>()
                    .map((recipe) => Map<String, dynamic>.from(recipe))
                    .map(SuggestedRecipe.fromJson)
                    .toList()
              : const [],
          ingredients: ingredients is List
              ? ingredients
                    .whereType<Map>()
                    .map((ingredient) => Map<String, dynamic>.from(ingredient))
                    .map(SuggestedIngredient.fromJson)
                    .toList()
              : const [],
          retryable: map['retryable'] == true,
        );
      }

      return const SuggestedRecipesResponse(
        recipes: [],
        ingredients: [],
        retryable: false,
      );
    } on DioException catch (error) {
      throw RecipeSuggestionException(_parseDioError(error));
    } catch (_) {
      throw const RecipeSuggestionException(
        'Could not load recipe suggestions.',
      );
    }
  }

  Future<List<RecipeCollectionItem>> fetchFavoriteRecipes() async {
    try {
      final response = await _dio.get<dynamic>('/recipes/favorites');
      final data = response.data;
      final recipes = data is Map ? data['recipes'] : data;

      if (recipes is List) {
        return recipes
            .whereType<Map>()
            .map((recipe) => Map<String, dynamic>.from(recipe))
            .map(RecipeCollectionItem.fromJson)
            .toList();
      }

      return const [];
    } on DioException catch (error) {
      throw RecipeSuggestionException(_parseDioError(error));
    } catch (_) {
      throw const RecipeSuggestionException('Could not load favorite recipes.');
    }
  }

  Future<List<RecipeCollectionItem>> fetchMostViewedRecipes() async {
    try {
      final response = await _dio.get<dynamic>('/recipes/most-viewed');
      final data = response.data;
      final recipes = data is Map ? data['recipes'] : data;

      if (recipes is List) {
        return recipes
            .whereType<Map>()
            .map((recipe) => Map<String, dynamic>.from(recipe))
            .map(RecipeCollectionItem.fromJson)
            .toList();
      }

      return const [];
    } on DioException catch (error) {
      throw RecipeSuggestionException(_parseDioError(error));
    } catch (_) {
      throw const RecipeSuggestionException(
        'Could not load most viewed recipes.',
      );
    }
  }

  Future<RecipeCollectionItem?> recordRecipeView(String recipeId) async {
    if (recipeId.isEmpty) {
      return null;
    }

    try {
      final response = await _dio.post<dynamic>('/recipes/$recipeId/views');
      final data = response.data;

      if (data is Map && data['recipe'] is Map) {
        return RecipeCollectionItem.fromJson(
          Map<String, dynamic>.from(data['recipe'] as Map),
        );
      }

      return null;
    } on DioException catch (error) {
      throw RecipeSuggestionException(_parseDioError(error));
    }
  }

  Future<RecipeCollectionItem> addFavoriteRecipe(String recipeId) async {
    try {
      final response = await _dio.post<dynamic>('/recipes/favorites/$recipeId');
      final data = response.data;

      if (data is Map && data['recipe'] is Map) {
        return RecipeCollectionItem.fromJson(
          Map<String, dynamic>.from(data['recipe'] as Map),
        );
      }

      throw const RecipeSuggestionException('Could not save favorite recipe.');
    } on DioException catch (error) {
      throw RecipeSuggestionException(_parseDioError(error));
    }
  }

  Future<void> removeFavoriteRecipe(String recipeId) async {
    try {
      await _dio.delete<dynamic>('/recipes/favorites/$recipeId');
    } on DioException catch (error) {
      throw RecipeSuggestionException(_parseDioError(error));
    }
  }

  String _parseDioError(DioException error) {
    final data = error.response?.data;
    if (data is Map<String, dynamic> && data['error'] is String) {
      if (data['error'] == 'Missing bearer token' ||
          data['error'] == 'Invalid bearer token') {
        return 'Please sign in to view recipe suggestions.';
      }

      return data['error'] as String;
    }

    if (error.type == DioExceptionType.connectionError ||
        error.type == DioExceptionType.connectionTimeout) {
      return 'Could not reach the backend. Check API_URL and make sure the server is running.';
    }

    return 'Could not load recipe suggestions.';
  }
}

class RecipeSuggestionException implements Exception {
  const RecipeSuggestionException(this.message);

  final String message;

  @override
  String toString() => message;
}
