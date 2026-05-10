class SuggestedRecipe {
  const SuggestedRecipe({
    required this.id,
    required this.scanId,
    required this.title,
    required this.description,
    required this.instructions,
    required this.cookingTime,
    required this.difficulty,
    required this.missingIngredients,
    required this.imageUrl,
  });

  factory SuggestedRecipe.fromJson(Map<String, dynamic> json) {
    return SuggestedRecipe(
      id: json['id'] as String? ?? '',
      scanId: json['scanId'] as String? ?? '',
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      instructions: json['instructions'] as String? ?? '',
      cookingTime: json['cookingTime'] as String? ?? '',
      difficulty: json['difficulty'] as String? ?? 'easy',
      missingIngredients: _stringList(json['missingIngredients']),
      imageUrl: json['imageUrl'] as String?,
    );
  }

  final String id;
  final String scanId;
  final String title;
  final String description;
  final String instructions;
  final String cookingTime;
  final String difficulty;
  final List<String> missingIngredients;
  final String? imageUrl;

  String get difficultyLabel {
    if (difficulty.isEmpty) {
      return 'Easy';
    }

    return '${difficulty[0].toUpperCase()}${difficulty.substring(1)}';
  }
}

class SuggestedRecipesResponse {
  const SuggestedRecipesResponse({
    required this.recipes,
    required this.ingredients,
    required this.retryable,
  });

  final List<SuggestedRecipe> recipes;
  final List<SuggestedIngredient> ingredients;
  final bool retryable;
}

class SuggestedIngredient {
  const SuggestedIngredient({required this.name, required this.confidence});

  factory SuggestedIngredient.fromJson(Map<String, dynamic> json) {
    return SuggestedIngredient(
      name: json['name'] as String? ?? '',
      confidence: (json['confidence'] as num?)?.toDouble() ?? 0,
    );
  }

  final String name;
  final double confidence;

  String get displayName {
    if (name.isEmpty) {
      return 'Ingredient';
    }

    return name
        .split(' ')
        .where((part) => part.isNotEmpty)
        .map((part) => '${part[0].toUpperCase()}${part.substring(1)}')
        .join(' ');
  }

  String get confidenceLabel {
    if (confidence <= 0) {
      return 'Detected';
    }

    return '${(confidence * 100).round()}% match';
  }
}

List<String> _stringList(Object? value) {
  if (value is List) {
    return value.whereType<String>().toList();
  }

  return const [];
}
