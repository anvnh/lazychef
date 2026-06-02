class HistoryScan {
  const HistoryScan({
    required this.id,
    required this.imageUrl,
    required this.createdAt,
    required this.detectedIngredients,
    required this.recipeSuggestions,
  });

  factory HistoryScan.fromJson(Map<String, dynamic> json) {
    return HistoryScan(
      id: json['id'] as String? ?? '',
      imageUrl: (json['imageUrl'] ?? json['image_url']) as String? ?? '',
      createdAt: json['createdAt'] as String? ?? '',
      detectedIngredients: _jsonList(
        json['detectedIngredients'],
      ).map(HistoryIngredient.fromJson).toList(),
      recipeSuggestions: _jsonList(
        json['recipeSuggestions'],
      ).map(HistoryRecipeSuggestion.fromJson).toList(),
    );
  }

  final String id;
  final String imageUrl;
  final String createdAt;
  final List<HistoryIngredient> detectedIngredients;
  final List<HistoryRecipeSuggestion> recipeSuggestions;

  DateTime? get createdDate {
    if (createdAt.isEmpty) {
      return null;
    }

    return DateTime.tryParse(createdAt.replaceFirst(' ', 'T'));
  }

  String get title {
    if (detectedIngredients.isEmpty) {
      return 'Saved fridge scan';
    }

    final primaryIngredients = detectedIngredients
        .take(2)
        .map((ingredient) => ingredient.displayName)
        .join(', ');

    return '$primaryIngredients scan';
  }
}

class HistoryIngredient {
  const HistoryIngredient({required this.name, required this.confidence});

  factory HistoryIngredient.fromJson(Map<String, dynamic> json) {
    return HistoryIngredient(
      name: json['name'] as String? ?? '',
      confidence: (json['confidence'] as num?)?.toDouble(),
    );
  }

  final String name;
  final double? confidence;

  String get confidenceLabel {
    if (confidence == null) {
      return 'Man.';
    }

    if (confidence! <= 0) {
      return '';
    }

    return '${(confidence! * 100).round()}%';
  }

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
}

class HistoryRecipeSuggestion {
  const HistoryRecipeSuggestion({
    required this.id,
    required this.title,
    required this.description,
    required this.instructions,
    required this.cookingTime,
    required this.difficulty,
    required this.missingIngredients,
    required this.imageUrl,
    required this.viewCount,
  });

  factory HistoryRecipeSuggestion.fromJson(Map<String, dynamic> json) {
    return HistoryRecipeSuggestion(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      instructions: json['instructions'] as String? ?? '',
      cookingTime: json['cookingTime'] as String? ?? '',
      difficulty: json['difficulty'] as String? ?? 'easy',
      missingIngredients: _stringList(json['missingIngredients']),
      imageUrl: (json['imageUrl'] ?? json['image_url']) as String?,
      viewCount: _intValue(json['viewCount'] ?? json['view_count']),
    );
  }

  final String id;
  final String title;
  final String description;
  final String instructions;
  final String cookingTime;
  final String difficulty;
  final List<String> missingIngredients;
  final String? imageUrl;
  final int viewCount;
}

List<Map<String, dynamic>> _jsonList(Object? value) {
  if (value is List) {
    return value
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }

  return const [];
}

List<String> _stringList(Object? value) {
  if (value is List) {
    return value.whereType<String>().toList();
  }

  return const [];
}

int _intValue(Object? value) {
  if (value is num) {
    return value.toInt();
  }

  return 0;
}
