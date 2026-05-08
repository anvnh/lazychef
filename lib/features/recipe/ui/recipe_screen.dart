import 'package:flutter/material.dart';
import 'package:lazychef/core/router/app_router.dart';
import 'package:lazychef/core/widgets/app_bottom_bar.dart';

class RecipeScreen extends StatelessWidget {
  const RecipeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      bottomNavigationBar: const AppBottomBar(currentIndex: 1),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(context),
              const SizedBox(height: 32),
              _buildGreeting(),
              const SizedBox(height: 24),
              _buildSearchBar(),
              const SizedBox(height: 24),
              _buildCategories(),
              const SizedBox(height: 32),
              _buildPopularRecipes(context),
              const SizedBox(height: 32),
              _buildMostViewedRecipes(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(12),
          ),
          child: IconButton(
                    onPressed: () {
                      Navigator.pushNamed(context, AppRouter.home);
                    },
          icon: const Icon(Icons.sort),
        ),),
        const CircleAvatar(
          radius: 24,
          backgroundColor: Color(0xFFF7E1D7),
          child: Icon(Icons.person, color: Colors.brown),
        ),
      ],
    );
  }

  Widget _buildGreeting() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Hi Rubina!',
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey.shade600,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Make your own food,\nstay at home',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            height: 1.2,
          ),
        ),
      ],
    );
  }

  Widget _buildSearchBar() {
    return Row(
      children: [
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Icon(Icons.search, color: Colors.grey.shade400),
                const SizedBox(width: 12),
                Text(
                  'Find your today recipe',
                  style: TextStyle(color: Colors.grey.shade400),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFFFD166),
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Icon(Icons.tune),
        ),
      ],
    );
  }

  Widget _buildCategories() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _buildCategoryChip('Breakfast', Icons.breakfast_dining, true),
          const SizedBox(width: 16),
          _buildCategoryChip('Fast Food', Icons.fastfood, false),
          const SizedBox(width: 16),
          _buildCategoryChip('Japanese', Icons.set_meal, false),
        ],
      ),
    );
  }

  Widget _buildCategoryChip(String label, IconData icon, bool isSelected) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: isSelected ? const Color(0xFFFFD166) : const Color(0xFFFFF8E7),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            size: 20,
            color: isSelected ? Colors.black87 : Colors.orange,
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: isSelected ? Colors.black87 : Colors.black54,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPopularRecipes(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Popular Recipes',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _buildRecipeCard(
                'Noodles with shrimp',
                '4.9',
                'https://images.unsplash.com/photo-1569718212165-3a8278d5f624?q=80&w=500&auto=format&fit=crop',
                onTap: () {
                  Navigator.pushNamed(context, AppRouter.recipeDetail);
                },
              ),
              const SizedBox(width: 16),
              _buildRecipeCard(
                'Oats with Strawberry\nand milk',
                '4.8',
                'https://images.unsplash.com/photo-1517673132405-a56a62b18caf?q=80&w=500&auto=format&fit=crop',
                onTap: () {
                  Navigator.pushNamed(context, AppRouter.recipeDetail);
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRecipeCard(String title, String rating, String imageUrl, {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 220,
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 140,
              decoration: BoxDecoration(
                color: const Color(0xFFEFEFEF),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                image: DecorationImage(
                  image: NetworkImage(imageUrl),
                  fit: BoxFit.cover,
                ),
              ),
              child: Stack(
                children: [
                  Positioned(
                    top: 12,
                    right: 12,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.bookmark_border, size: 16),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const CircleAvatar(
                            radius: 10,
                            backgroundColor: Colors.grey,
                            child: Icon(Icons.person, size: 12),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Riya Ghosh',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFD166),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.star, size: 12),
                            const SizedBox(width: 4),
                            Text(
                              rating,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMostViewedRecipes() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Most Viewed Recipes',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Row(
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(16),
                  image: const DecorationImage(
                    image: NetworkImage('https://images.unsplash.com/photo-1556881286-fc6915169721?q=80&w=500&auto=format&fit=crop'),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Morning Shake with\nMango Slice and Cream',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        const Icon(Icons.bookmark_border, size: 20),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const CircleAvatar(
                              radius: 10,
                              backgroundColor: Colors.grey,
                              child: Icon(Icons.person, size: 12),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Riya Ghosh',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFD166),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.star, size: 12),
                              SizedBox(width: 4),
                              Text(
                                '4.9',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// class _RecipeBottomBar extends StatelessWidget {
//   const _RecipeBottomBar();

//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       decoration: BoxDecoration(
//         color: Theme.of(context).colorScheme.primary,
//         borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
//       ),
//       child: SafeArea(
//         top: false,
//         child: Padding(
//           padding: const EdgeInsets.symmetric(vertical: 12),
//           child: Row(
//             mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//             children: [
//               _buildNavItem(Icons.explore_outlined, 'Discover', true),
//               _buildNavItem(Icons.shopping_cart_outlined, 'Ingredients', false),
//               _buildNavItem(Icons.person_outline, 'Profile', false),
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _buildNavItem(IconData icon, String label, bool isSelected) {
//     final color = isSelected ? Colors.white : Colors.white60;
//     return Column(
//       mainAxisSize: MainAxisSize.min,
//       children: [
//         Icon(icon, color: color, size: 26),
//         const SizedBox(height: 4),
//         Text(
//           label,
//           style: TextStyle(
//             color: color,
//             fontSize: 12,
//             fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
//           ),
//         ),
//       ],
//     );
//   }
// }
