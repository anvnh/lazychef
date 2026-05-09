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
    required this.retryable,
  });

  final List<SuggestedRecipe> recipes;
  final bool retryable;
}

List<String> _stringList(Object? value) {
  if (value is List) {
    return value.whereType<String>().toList();
  }

  return const [];
}
