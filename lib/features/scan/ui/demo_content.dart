class IngredientInsight {
  const IngredientInsight({required this.name, required this.confidence});

  final String name;
  final double confidence;
}

class RecipePreview {
  const RecipePreview({
    required this.title,
    required this.description,
    required this.duration,
    required this.difficulty,
    required this.ingredients,
    required this.steps,
  });

  final String title;
  final String description;
  final String duration;
  final String difficulty;
  final List<String> ingredients;
  final List<String> steps;
}

class HistoryEntry {
  const HistoryEntry({
    required this.dayLabel,
    required this.mealTitle,
    required this.timeLabel,
    required this.ingredients,
    required this.recipesFound,
  });

  final String dayLabel;
  final String mealTitle;
  final String timeLabel;
  final List<String> ingredients;
  final int recipesFound;
}

const demoIngredients = [
  IngredientInsight(name: 'Tomatoes', confidence: 0.94),
  IngredientInsight(name: 'Spinach', confidence: 0.88),
  IngredientInsight(name: 'Eggs', confidence: 0.92),
  IngredientInsight(name: 'Parmesan', confidence: 0.81),
  IngredientInsight(name: 'Mushrooms', confidence: 0.79),
];

const demoRecipes = [
  RecipePreview(
    title: 'Skillet Garden Frittata',
    description:
        'A soft egg skillet with quick-sauteed vegetables and parmesan folded in at the end.',
    duration: '18 min',
    difficulty: 'Easy',
    ingredients: ['Eggs', 'Spinach', 'Tomatoes', 'Mushrooms', 'Parmesan'],
    steps: [
      'Saute mushrooms and tomatoes until the edges soften.',
      'Add spinach and cook just until wilted.',
      'Pour beaten eggs over the pan and finish with parmesan.',
    ],
  ),
  RecipePreview(
    title: 'Warm Tomato Mushroom Toast',
    description:
        'Pan-roasted vegetables layered over crisp bread with parmesan and a jammy egg.',
    duration: '14 min',
    difficulty: 'Fast',
    ingredients: ['Tomatoes', 'Mushrooms', 'Eggs', 'Parmesan'],
    steps: [
      'Roast mushrooms and tomatoes with olive oil in a hot pan.',
      'Toast bread until deeply golden while the vegetables cook.',
      'Top with the vegetables, shave parmesan, and add a soft egg.',
    ],
  ),
];

const demoHistoryEntries = [
  HistoryEntry(
    dayLabel: 'Today',
    mealTitle: 'Skillet Garden Frittata',
    timeLabel: '7:45 PM',
    ingredients: ['Spinach', 'Eggs', 'Tomatoes'],
    recipesFound: 4,
  ),
  HistoryEntry(
    dayLabel: 'Today',
    mealTitle: 'Creamy Pepper Pasta',
    timeLabel: '12:10 PM',
    ingredients: ['Peppers', 'Cream', 'Garlic'],
    recipesFound: 3,
  ),
  HistoryEntry(
    dayLabel: 'Yesterday',
    mealTitle: 'Leftover Rice Bowl',
    timeLabel: '8:25 PM',
    ingredients: ['Rice', 'Cucumber', 'Eggs'],
    recipesFound: 2,
  ),
  HistoryEntry(
    dayLabel: 'Sunday',
    mealTitle: 'Fridge-Cleanout Soup',
    timeLabel: '6:30 PM',
    ingredients: ['Carrot', 'Celery', 'Tomatoes', 'Beans'],
    recipesFound: 5,
  ),
];
