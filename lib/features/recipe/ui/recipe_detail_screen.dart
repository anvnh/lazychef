import 'package:flutter/material.dart';

class RecipeDetailScreen extends StatefulWidget {
  const RecipeDetailScreen({super.key});

  @override
  State<RecipeDetailScreen> createState() => _RecipeDetailScreenState();
}

class _RecipeDetailScreenState extends State<RecipeDetailScreen> {
  bool _showAllIngredients = false;

  final List<Map<String, dynamic>> _ingredients = [
    {
      'name': 'Noodles',
      'amount': '450 g',
      'color': const Color(0xFFFDE8C4),
      'icon': Icons.ramen_dining,
    },
    {
      'name': 'Butter',
      'amount': '200 g',
      'color': const Color(0xFFF3E5D8),
      'icon': Icons.breakfast_dining,
    },
    {
      'name': 'Lemon',
      'amount': '10 g',
      'color': const Color(0xFFE5F3D8),
      'icon': Icons.egg_alt,
    },
    {
      'name': 'Chicken',
      'amount': '100 g',
      'color': const Color(0xFFEFE6E0),
      'icon': Icons.set_meal,
    },
    {
      'name': 'Soy Sauce',
      'amount': '30 ml',
      'color': const Color(0xFFEFE6E0),
      'icon': Icons.water_drop,
    },
    {
      'name': 'Garlic',
      'amount': '5 g',
      'color': const Color(0xFFFDE8C4),
      'icon': Icons.grass,
    },
  ];

  final List<Map<String, dynamic>> _missingIngredients = [
    {
      'name': 'Chili',
      'amount': '2 pcs',
      'color': const Color(0xFFFFD4D4),
      'icon': Icons.local_fire_department,
    },
    {
      'name': 'Oil',
      'amount': '15 ml',
      'color': const Color(0xFFF3E5D8),
      'icon': Icons.water_drop,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      body: SingleChildScrollView(
        child: Column(
          children: [_buildTopSection(context), _buildBottomSection(context)],
        ),
      ),
    );
  }

  Widget _buildTopSection(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(40),
          bottomRight: Radius.circular(40),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Icon(Icons.arrow_back_ios_new, size: 20),
                  ),
                  const Icon(Icons.favorite_border, color: Color(0xFF2C3236)),
                ],
              ),
              const SizedBox(height: 32),

              // Dish Image
              Container(
                width: 220,
                height: 220,
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
              const SizedBox(height: 48),
              const Text(
                'Noodles with chicken',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                  height: 1.3,
                  color: Color(0xFF2C3236),
                ),
              ),
              const SizedBox(height: 48),
              // Stats Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildStatItem(Icons.access_time, '45 min'),
                  _buildStatItem(
                    Icons.star_border,
                    '8.5 rate',
                    iconColor: const Color(0xFFF2BC3D),
                  ),
                  _buildStatItem(
                    Icons.local_fire_department_outlined,
                    '215 kcal',
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem(IconData icon, String text, {Color? iconColor}) {
    return Column(
      children: [
        Icon(icon, color: iconColor ?? const Color(0xFF9E9E9E), size: 28),
        const SizedBox(height: 8),
        Text(
          text,
          style: const TextStyle(
            color: Color(0xFF9E9E9E),
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildBottomSection(BuildContext context) {
    final allIngredients = [..._ingredients, ..._missingIngredients];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
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
              GestureDetector(
                onTap: () {
                  setState(() {
                    _showAllIngredients = !_showAllIngredients;
                  });
                },
                child: Text(
                  _showAllIngredients ? 'Show less' : 'See all',
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

          // Ingredients List/Grid
          _showAllIngredients
              ? Wrap(
                  spacing: 16,
                  runSpacing: 24,
                  children: allIngredients.map((ing) {
                    return _buildIngredientItem(
                      ing['name'] as String,
                      ing['amount'] as String,
                      ing['color'] as Color,
                      ing['icon'] as IconData,
                    );
                  }).toList(),
                )
              : SizedBox(
                  height:
                      164, // Đặt chiều cao cố định để ListView có thể cuộn ngang
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    clipBehavior: Clip.none,
                    itemCount: allIngredients.length,
                    itemBuilder: (context, index) {
                      final ing = allIngredients[index];
                      return Padding(
                        padding: const EdgeInsets.only(right: 16.0),
                        child: _buildIngredientItem(
                          ing['name'] as String,
                          ing['amount'] as String,
                          ing['color'] as Color,
                          ing['icon'] as IconData,
                        ),
                      );
                    },
                  ),
                ),

          const SizedBox(height: 40),

          // Missing Ingredients Section
          const Text(
            'Keep in mind, you are missing:',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Color(0xFF2C3236),
            ),
          ),
          const SizedBox(height: 24),
          Wrap(
            spacing: 16,
            runSpacing: 24,
            children: _missingIngredients.map((ing) {
              return _buildIngredientItem(
                ing['name'] as String,
                ing['amount'] as String,
                ing['color'] as Color,
                ing['icon'] as IconData,
              );
            }).toList(),
          ),

          const SizedBox(height: 40),
          const Text(
            'Instructions',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w600,
              color: Color(0xFF2C3236),
              height: 1.3,
            ),
          ),
          const SizedBox(height: 24),
          _buildInstructionStep(
            '1',
            'Boil the noodles',
            'Boil water in a pot. Cook the noodles for 5 minutes, then drain and set aside.',
          ),
          _buildInstructionStep(
            '2',
            'Cook the chicken',
            'Cut the chicken breast into pieces. Stir-fry in a pan until golden brown.',
          ),
          _buildInstructionStep(
            '3',
            'Mix together',
            'Add the vegetables and soy sauce to the pan. Toss with noodles and serve hot.',
          ),
        ],
      ),
    );
  }

  Widget _buildInstructionStep(String step, String title, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: const BoxDecoration(
              color: Color(0xFFFF7E5F),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              step,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF4A4E54),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF9E9E9E),
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIngredientItem(
    String name,
    String amount,
    Color bgColor,
    IconData placeholderIcon,
  ) {
    return SizedBox(
      width: 104,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Ingredient Image (Rounded Square)
          Container(
            width: 104,
            height: 104,
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(placeholderIcon, color: Colors.black26, size: 48),
          ),
          const SizedBox(height: 12),

          // Ingredient Info
          Text(
            name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Color(0xFF4A4E54),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            amount,
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFF9E9E9E),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
