import 'package:flutter/material.dart';

class SearchScreen extends StatelessWidget {
  const SearchScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Nút Back (Tùy chọn, thêm vào để UX tốt hơn)
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: const Icon(
                  Icons.arrow_back_ios_new,
                  size: 20,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 20),

              // 1. Tiêu đề Search
              const Text(
                'Search',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFFFFB039), // Màu vàng cam chủ đạo
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 20),

              // 2. Thanh tìm kiếm (Search Bar)
              _buildSearchBar(),
              const SizedBox(height: 40),

              // 3. Khu vực Recommend (Gợi ý)
              const Text(
                'Recommend',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF333333),
                ),
              ),
              const SizedBox(height: 20),
              _buildRecommendGrid(),
              const SizedBox(height: 40),

              // 4. Khu vực Search History (Lịch sử tìm kiếm)
              const Text(
                'Search History',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF333333),
                ),
              ),
              const SizedBox(height: 20),
              _buildSearchHistory(),
            ],
          ),
        ),
      ),
    );
  }

  // Widget Thanh tìm kiếm
  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.08),
            spreadRadius: 2,
            blurRadius: 15,
            offset: const Offset(0, 4), // Đổ bóng nhẹ xuống dưới
          ),
        ],
      ),
      child: TextField(
        decoration: InputDecoration(
          hintText: 'Search your recipes...',
          hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
          prefixIcon: Icon(Icons.search, color: Colors.grey.shade400, size: 22),
          suffixIcon: Icon(Icons.cancel, color: Colors.grey.shade300, size: 18),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none, // Bỏ viền mặc định
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(vertical: 16),
        ),
      ),
    );
  }

  // Widget Lưới các danh mục gợi ý
  Widget _buildRecommendGrid() {
    // Dùng GridView.builder bọc trong shrinkWrap để nó tự tính toán chiều cao
    return GridView.builder(
      shrinkWrap: true,
      physics:
          const NeverScrollableScrollPhysics(), // Tắt cuộn của lưới để dùng cuộn ngoài cùng
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2, // 2 cột
        crossAxisSpacing: 16,
        mainAxisSpacing: 20,
        childAspectRatio:
            2.5, // Tỷ lệ chiều rộng / chiều cao của thẻ (chỉnh để thẻ dẹp lại)
      ),
      itemCount: 4,
      itemBuilder: (context, index) {
        final recommends = [
          {'title': '# Healthy Diet', 'count': '120 recipes'},
          {'title': '# Fast Food', 'count': '85 recipes'},
          {'title': '# Dessert', 'count': '60 recipes'},
          {'title': '# Hot Vegan', 'count': '45 recipes'},
        ];
        return _buildRecommendItem(
          recommends[index]['title']!,
          recommends[index]['count']!,
          'https://kenh14cdn.com/k:thumb_w/600/dpA6uSv3GtBzvbRT7Y4EBtfN37yCA/Image/2014/01/h1-6ca84/nhung-hinh-anh-minh-hoa-dang-yeu-lam-ban-mim-cuoi-khi-xem.jpg', // Ảnh minh họa (Bạn có thể đổi sang ảnh khác)
        );
      },
    );
  }

  // Widget Từng item trong lưới Recommend
  Widget _buildRecommendItem(String title, String count, String imageUrl) {
    return Row(
      children: [
        // Ảnh vuông bo góc
        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            image: DecorationImage(
              image: NetworkImage(imageUrl),
              fit: BoxFit.cover,
            ),
          ),
        ),
        const SizedBox(width: 12),
        // Chữ
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF333333),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                count,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFFFFB039), // Màu vàng cho số lượng
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Widget Lịch sử tìm kiếm (Dạng Wrap các nút pill)
  Widget _buildSearchHistory() {
    final historyItems = [
      'Chicken salad',
      'Pasta',
      'Vegan breakfast',
      'Pancake',
      'Keto diet',
    ];

    return Wrap(
      spacing: 12, // Khoảng cách ngang giữa các nút
      runSpacing: 12, // Khoảng cách dọc giữa các dòng
      children: historyItems.map((item) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          decoration: BoxDecoration(
            color: const Color(
              0xFFF7F7F9,
            ), // Màu xám xanh rất nhạt giống thiết kế
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            item,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: Color(0xFF666666), // Màu chữ xám
            ),
          ),
        );
      }).toList(),
    );
  }
}
