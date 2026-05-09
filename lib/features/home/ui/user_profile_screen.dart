import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lazychef/core/router/app_router.dart';
import 'package:lazychef/features/auth/data/auth_repository.dart';
import 'package:lazychef/features/auth/providers/auth_provider.dart';
import 'package:lazychef/features/home/ui/edit_profile.dart';

class UserProfileScreen extends ConsumerWidget {
  const UserProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  _buildHeaderProfile(context, ref),
                  _buildStats(),
                  const SizedBox(height: 8),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 24),
                    child: Divider(
                      height: 32,
                      thickness: 1,
                      color: Color(0xFFF0F0F0),
                    ),
                  ),
                  // _buildMyPosts(),
                  _buildMenuItems(),
                ],
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.only(top: 16, bottom: 40),
            color: Colors.white,
            child: _buildLogoutButton(context, ref),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderProfile(BuildContext context, WidgetRef ref) {
    final emailAsync = ref.watch(currentUserEmailProvider);
    final userName = emailAsync.when(
      data: (email) => email != null ? email.split('@')[0] : 'User',
      loading: () => 'Loading...',
      error: (_, __) => 'User',
    );

    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.topCenter,
      children: [
        // 1. Ảnh bìa (Cover Image)
        Container(
          height: 200,
          decoration: const BoxDecoration(
            color: Color(0xFFFFD166),
            image: DecorationImage(
              image: NetworkImage(
                'https://images.unsplash.com/photo-1490818387583-1b5ba4597b24?q=80&w=800&auto=format&fit=crop',
              ),
              fit: BoxFit.cover,
            ),
          ),
        ),

        // 2. Nút Back (Quay về Home) đặt nổi lên trên ảnh bìa
        Positioned(
          top:
              MediaQuery.of(context).padding.top +
              16, // Đẩy xuống khỏi thanh trạng thái (tai thỏ/pin)
          left: 16,
          child: GestureDetector(
            onTap: () {
              Navigator.pop(context);
            },
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.3),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.arrow_back_ios_new,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
        ),

        Container(
          margin: const EdgeInsets.only(top: 150),
          padding: const EdgeInsets.only(top: 60),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(width: 28),
              Text(
                userName,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),

              const SizedBox(width: 8),

              GestureDetector(
                onTap: () async {
                  final result = await showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (context) => EditProfilePopup(
                      currentName: userName, // Chuyền data tĩnh tạm thời
                      currentCoverColor: const Color(0xFFFFD166),
                    ),
                  );

                  if (result != null) {
                    final newName = result['name'];
                    final newColor = result['coverColor'];
                    print('Tên mới: $newName - Màu mới: $newColor');
                  }
                },
                child: const Icon(Icons.edit, size: 20, color: Colors.grey),
              ),
            ],
          ),
        ),

        const Positioned(
          top: 100,
          child: CircleAvatar(
            radius: 50,
            backgroundColor: Colors.white,
            child: CircleAvatar(
              radius: 46,
              backgroundImage: NetworkImage(
                'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcT8I_m_kf6iq8JeoiETm7vX9yKD6DfBIdXEJA&s',
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStats() {
    return Padding(
      padding: const EdgeInsets.only(top: 24, bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildStatItem('153', 'FOLLOW'),
          Container(
            width: 1,
            height: 24,
            color: Colors.grey.shade300,
            margin: const EdgeInsets.symmetric(horizontal: 40),
          ),
          _buildStatItem('244', 'LIKE'),
        ],
      ),
    );
  }

  Widget _buildStatItem(String number, String label) {
    return Row(
      children: [
        Text(
          number,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade400,
            letterSpacing: 1.2,
          ),
        ),
      ],
    );
  }

  // Widget _buildMyPosts() {
  //   return Padding(
  //     padding: const EdgeInsets.only(left: 24),
  //     child: Column(
  //       crossAxisAlignment: CrossAxisAlignment.start,
  //       children: [
  //         const Text(
  //           'My post',
  //           style: TextStyle(
  //             fontSize: 18,
  //             fontWeight: FontWeight.bold,
  //             color: Colors.black87,
  //           ),
  //         ),
  //         const SizedBox(height: 20),
  //         SizedBox(
  //           height: 140,
  //           child: ListView(
  //             scrollDirection: Axis.horizontal,
  //             children: [
  //               _buildPostItem(
  //                 'Salad',
  //                 'https://images.unsplash.com/photo-1482049016688-2d3e1b311543?q=80&w=300&auto=format&fit=crop',
  //               ),
  //               _buildPostItem(
  //                 'pizza handmade',
  //                 'https://images.unsplash.com/photo-1565299624946-b28f40a0ae38?q=80&w=300&auto=format&fit=crop',
  //               ),
  //               _buildPostItem(
  //                 'I am good',
  //                 'https://images.unsplash.com/photo-1484723091791-cdd51a0c0435?q=80&w=300&auto=format&fit=crop',
  //               ),
  //               _buildPostItem(
  //                 'vegetables meal',
  //                 'https://images.unsplash.com/photo-1546069901-ba9599a7e63c?q=80&w=300&auto=format&fit=crop',
  //               ),
  //             ],
  //           ),
  //         ),
  //       ],
  //     ),
  //   );
  // }

  // Widget _buildPostItem(String title, String imageUrl) {
  //   return Container(
  //     width: 100,
  //     margin: const EdgeInsets.only(right: 16),
  //     child: Column(
  //       crossAxisAlignment: CrossAxisAlignment.start,
  //       children: [
  //         Container(
  //           height: 100,
  //           decoration: BoxDecoration(
  //             borderRadius: BorderRadius.circular(12),
  //             image: DecorationImage(
  //               image: NetworkImage(imageUrl),
  //               fit: BoxFit.cover,
  //             ),
  //           ),
  //         ),
  //         const SizedBox(height: 8),
  //         Text(
  //           title,
  //           maxLines: 1,
  //           overflow: TextOverflow.ellipsis,
  //           style: TextStyle(
  //             fontSize: 13,
  //             fontWeight: FontWeight.w600,
  //             color: Colors.grey.shade800,
  //           ),
  //         ),
  //       ],
  //     ),
  //   );
  // }

  Widget _buildMenuItems() {
    return Column(
      children: [
        _buildMenuItem(Icons.folder_outlined, 'My recipes'),
        _buildMenuItem(Icons.history, 'Recently cooked'),
        _buildMenuItem(Icons.favorite_border, 'My collection'),
        _buildMenuItem(Icons.shopping_bag_outlined, 'Have bought ingredients'),
      ],
    );
  }

  Widget _buildMenuItem(IconData icon, String title) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
      leading: Icon(icon, color: const Color(0xFFFFB039), size: 26),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w500,
          color: Colors.grey.shade700,
        ),
      ),
      trailing: Icon(
        Icons.chevron_right,
        color: Colors.grey.shade400,
        size: 20,
      ),
      onTap: () {
        // TODO: Chuyển trang khi bấm vào mục menu
      },
    );
  }

  Widget _buildLogoutButton(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: SizedBox(
        width: double.infinity,
        height: 50,
        child: OutlinedButton.icon(
          onPressed: () async {
            await ref.read(authRepositoryProvider).logout();
            if (context.mounted) {
              Navigator.pushNamedAndRemoveUntil(
                context,
                AppRouter.login,
                (Route<dynamic> route) => false,
              );
            }
          },
          icon: const Icon(Icons.logout, color: Colors.redAccent),
          label: const Text(
            'Log Out',
            style: TextStyle(
              color: Colors.redAccent,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          style: OutlinedButton.styleFrom(
            side: BorderSide(color: Colors.redAccent.shade100, width: 1.5),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            foregroundColor: Colors.redAccent,
          ),
        ),
      ),
    );
  }
}
