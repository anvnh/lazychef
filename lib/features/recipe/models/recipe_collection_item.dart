import 'package:lazychef/features/history/models/history_scan.dart';
import 'package:lazychef/features/recipe/models/suggested_recipe.dart';

class RecipeCollectionItem {
  const RecipeCollectionItem({
    required this.id,
    required this.scanId,
    required this.title,
    required this.description,
    required this.instructions,
    required this.cookingTime,
    required this.difficulty,
    required List<HistoryIngredient> availableIngredients,
    required this.missingIngredients,
    required this.imageUrl,
    required this.generatedAt,
    required this.viewCount,
  }) : _availableIngredients = availableIngredients;

  factory RecipeCollectionItem.fromSuggested(SuggestedRecipe recipe) {
    final scanId = recipe.scanId.trim();
    final id = _recipeId(
      recipeId: recipe.id,
      scanId: scanId,
      title: recipe.title,
    );

    return RecipeCollectionItem(
      id: id,
      scanId: scanId,
      title: recipe.title,
      description: recipe.description,
      instructions: recipe.instructions,
      cookingTime: recipe.cookingTime,
      difficulty: recipe.difficulty,
      availableIngredients: const [],
      missingIngredients: recipe.missingIngredients,
      imageUrl: recipe.imageUrl,
      generatedAt: null,
      viewCount: recipe.viewCount,
    );
  }

  factory RecipeCollectionItem.fromHistory({
    required HistoryRecipeSuggestion recipe,
    required HistoryScan scan,
  }) {
    final id = _recipeId(
      recipeId: recipe.id,
      scanId: scan.id,
      title: recipe.title,
    );

    return RecipeCollectionItem(
      id: id,
      scanId: scan.id,
      title: recipe.title,
      description: recipe.description,
      instructions: recipe.instructions,
      cookingTime: recipe.cookingTime,
      difficulty: recipe.difficulty,
      availableIngredients: scan.detectedIngredients,
      missingIngredients: recipe.missingIngredients,
      imageUrl: recipe.imageUrl,
      generatedAt: scan.createdDate,
      viewCount: recipe.viewCount,
    );
  }

  factory RecipeCollectionItem.fromJson(Map<String, dynamic> json) {
    return RecipeCollectionItem(
      id: json['id'] as String? ?? '',
      scanId: json['scanId'] as String? ?? '',
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      instructions: json['instructions'] as String? ?? '',
      cookingTime: json['cookingTime'] as String? ?? '',
      difficulty: json['difficulty'] as String? ?? 'easy',
      availableIngredients: _ingredientList(json['availableIngredients']),
      missingIngredients: _stringList(json['missingIngredients']),
      imageUrl: (json['imageUrl'] ?? json['image_url']) as String?,
      generatedAt: DateTime.tryParse(json['generatedAt'] as String? ?? ''),
      viewCount: _intValue(json['viewCount'] ?? json['view_count']),
    );
  }

  final String id;
  final String scanId;
  final String title;
  final String description;
  final String instructions;
  final String cookingTime;
  final String difficulty;
  final List<HistoryIngredient>? _availableIngredients;
  final List<String> missingIngredients;
  final String? imageUrl;
  final DateTime? generatedAt;
  final int viewCount;

  List<HistoryIngredient> get availableIngredients {
    return _availableIngredients ?? const [];
  }

  String get difficultyLabel {
    if (difficulty.isEmpty) {
      return 'Easy';
    }

    return '${difficulty[0].toUpperCase()}${difficulty.substring(1)}';
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'scanId': scanId,
      'title': title,
      'description': description,
      'instructions': instructions,
      'cookingTime': cookingTime,
      'difficulty': difficulty,
      'availableIngredients': availableIngredients
          .map(
            (ingredient) => {
              'name': ingredient.name,
              'confidence': ingredient.confidence,
              'quantity': ingredient.quantity,
              'expiryDate': ingredient.expiryDate,
            },
          )
          .toList(),
      'missingIngredients': missingIngredients,
      'imageUrl': imageUrl,
      'generatedAt': generatedAt?.toIso8601String(),
      'viewCount': viewCount,
    };
  }
}

String _recipeId({
  required String recipeId,
  required String scanId,
  required String title,
}) {
  final normalizedRecipeId = recipeId.trim();
  if (normalizedRecipeId.isNotEmpty) {
    return normalizedRecipeId;
  }

  final normalizedScanId = scanId.trim();
  final normalizedTitle = title.trim().toLowerCase().replaceAll(
    RegExp(r'\s+'),
    '-',
  );

  if (normalizedScanId.isEmpty) {
    return normalizedTitle;
  }

  return '$normalizedScanId:$normalizedTitle';
}

List<String> _stringList(Object? value) {
  if (value is List) {
    return value.whereType<String>().toList();
  }

  return const [];
}

List<HistoryIngredient> _ingredientList(Object? value) {
  if (value is List) {
    return value
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .map(HistoryIngredient.fromJson)
        .toList();
  }

  return const [];
}

int _intValue(Object? value) {
  if (value is num) {
    return value.toInt();
  }

  return 0;
}
