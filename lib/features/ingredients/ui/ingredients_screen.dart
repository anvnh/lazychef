import 'package:flutter/material.dart';
import 'package:lazychef/core/router/app_router.dart';

class IngredientsScreen extends StatefulWidget {
  const IngredientsScreen({Key? key}) : super(key: key);

  @override
  State<IngredientsScreen> createState() => _IngredientsScreenState();
}

class _IngredientsScreenState extends State<IngredientsScreen> {
  // Dữ liệu giả lập
  final List<String> categories = ['All', 'Vegetables', 'Meat', 'Dairy', 'Fruits'];
  int selectedCategoryIndex = 0;

  final List<Map<String, dynamic>> ingredients = [
    {'name': 'Tomato', 'qty': '3 pcs', 'icon': '🍅', 'cat': 'Vegetables'},
    {'name': 'Chicken Breast', 'qty': '500g', 'icon': '🍗', 'cat': 'Meat'},
    {'name': 'Broccoli', 'qty': '1 head', 'icon': '🥦', 'cat': 'Vegetables'},
    {'name': 'Milk', 'qty': '1 L', 'icon': '🥛', 'cat': 'Dairy'},
    {'name': 'Eggs', 'qty': '10 pcs', 'icon': '🥚', 'cat': 'Dairy'},
    {'name': 'Carrot', 'qty': '4 pcs', 'icon': '🥕', 'cat': 'Vegetables'},
  ];

  @override
  Widget build(BuildContext context) {
    // Kế thừa màu từ Theme bạn đã setup
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, color: colorScheme.onSurface, size: 20),
          onPressed: () {
            Navigator.pushReplacementNamed(context, AppRouter.home);
          },
        ),
        title: Text(
          'My Fridge',
          style: theme.textTheme.headlineMedium,
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.more_vert, color: colorScheme.onSurface),
            onPressed: () {},
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Thanh tìm kiếm
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Search ingredients...',
                  hintStyle: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey),
                  prefixIcon: const Icon(Icons.search, color: Colors.grey),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 14),
                  // Bỏ viền mặc định của TextField để dùng viền Container
                  enabledBorder: InputBorder.none, 
                  focusedBorder: InputBorder.none,
                ),
              ),
            ),
            const SizedBox(height: 20),

            // 2. Danh mục (Categories)
            SizedBox(
              height: 40,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: categories.length,
                itemBuilder: (context, index) {
                  final isSelected = selectedCategoryIndex == index;
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        selectedCategoryIndex = index;
                      });
                    },
                    child: Container(
                      margin: const EdgeInsets.only(right: 12),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected ? colorScheme.primary : Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isSelected ? colorScheme.primary : Colors.grey.shade300,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          categories[index],
                          style: TextStyle(
                            color: isSelected ? Colors.white : colorScheme.onSurface,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 20),

            Text(
              '${ingredients.length} items from last scan',
              style: theme.textTheme.titleMedium?.copyWith(color: Colors.grey.shade600),
            ),
            const SizedBox(height: 12),

            // 3. Danh sách nguyên liệu dạng lưới
            Expanded(
              // Bắt buộc dùng Expanded để tránh lỗi RenderBox hasSize như bạn vừa gặp
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2, // 2 cột
                  childAspectRatio: 0.85, // Tỷ lệ chiều cao/rộng của thẻ
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                ),
                itemCount: ingredients.length,
                itemBuilder: (context, index) {
                  final item = ingredients[index];
                  return _buildIngredientCard(
                    context, 
                    item['name'], 
                    item['qty'], 
                    item['icon']
                  );
                },
              ),
            ),
          ],
        ),
      ),
      
      // 4. Nút Add thủ công (Floating Action Button)
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          // TODO: Hiện Popup hoặc chuyển trang Add Manual
          _showAddManualBottomSheet(context);
        },
        backgroundColor: colorScheme.secondary, // Màu cam đất (Accent color)
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text(
          'Add Item', 
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)
        ),
      ),
    );
  }

  // Widget riêng lẻ cho từng Thẻ Nguyên liệu
  Widget _buildIngredientCard(BuildContext context, String name, String qty, String emojiIcon) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Thay bằng Image.network hoặc Image.asset nếu dùng hình thật
          Text(emojiIcon, style: const TextStyle(fontSize: 40)), 
          const SizedBox(height: 12),
          Text(
            name,
            style: Theme.of(context).textTheme.titleMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            qty,
            style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
          ),
        ],
      ),
    );
  }

  // Popup đơn giản khi bấm nút Add
  void _showAddManualBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24),
          height: 250,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Add Ingredient Manually', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 16),
              const TextField(
                decoration: InputDecoration(
                  hintText: 'e.g., Apple, Beef...',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                  ),
                  child: const Text('Add to Fridge', style: TextStyle(color: Colors.white)),
                ),
              )
            ],
          ),
        );
      },
    );
  }
}