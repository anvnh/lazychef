import 'package:flutter/material.dart';

class EditProfilePopup extends StatefulWidget {
  // Nhận tên và màu hiện tại từ màn hình Profile truyền qua
  final String currentName;
  final Color currentCoverColor;

  const EditProfilePopup({
    super.key,
    required this.currentName,
    required this.currentCoverColor,
  });

  @override
  State<EditProfilePopup> createState() => _EditProfilePopupState();
}

class _EditProfilePopupState extends State<EditProfilePopup> {
  late TextEditingController _nameController;
  late Color _selectedCoverColor;

  // Danh sách các màu bìa để chọn
  final List<Color> coverColors = [
    const Color(0xFFFFD166), // Vàng cam
    const Color(0xFFF4A261), // Cam đậm
    const Color(0xFF2A9D8F), // Xanh cổ vịt
    const Color(0xFFE76F51), // Đỏ gạch
    const Color(0xFF264653), // Xanh đen
  ];

  @override
  void initState() {
    super.initState();
    // Khởi tạo dữ liệu từ widget cha truyền vào
    _nameController = TextEditingController(text: widget.currentName);
    _selectedCoverColor = widget.currentCoverColor;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      // Padding đẩy bottom sheet lên khi bàn phím xuất hiện
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min, // Tự co lại bằng nội dung bên trong
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- HEADER ---
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Edit Profile',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // --- ĐỔI ẢNH ĐẠI DIỆN ---
            Center(
              child: Stack(
                children: [
                  const CircleAvatar(
                    radius: 40,
                    backgroundImage: NetworkImage(
                      'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcT8I_m_kf6iq8JeoiETm7vX9yKD6DfBIdXEJA&s',
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: GestureDetector(
                      onTap: () {
                        // TODO: Logic mở thư viện ảnh
                      },
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFB039),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: const Icon(Icons.camera_alt, size: 16, color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // --- ĐỔI TÊN ---
            const Text('Display Name', style: TextStyle(fontWeight: FontWeight.w600, color: Colors.black54)),
            const SizedBox(height: 8),
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.grey.shade100,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 24),

            // --- ĐỔI MÀU BÌA (COVER COLOR) ---
            const Text('Cover Color', style: TextStyle(fontWeight: FontWeight.w600, color: Colors.black54)),
            const SizedBox(height: 12),
            Wrap(
              spacing: 16,
              children: coverColors.map((color) {
                final isSelected = _selectedCoverColor == color;
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedCoverColor = color;
                    });
                  },
                  child: CircleAvatar(
                    radius: 20,
                    backgroundColor: color,
                    child: isSelected ? const Icon(Icons.check, color: Colors.white, size: 20) : null,
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 32),

            // --- NÚT LƯU ---
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () {
                  // Đóng popup và trả về cục data Map chứa Tên và Màu mới
                  Navigator.pop(context, {
                    'name': _nameController.text,
                    'coverColor': _selectedCoverColor,
                  });
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFFB039),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Text('Save Changes', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}