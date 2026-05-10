import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lazychef/core/router/app_router.dart';
import 'package:lazychef/core/widgets/app_button.dart';
import 'package:lazychef/core/widgets/lazychef_scaffold.dart';
import 'package:lazychef/features/auth/providers/auth_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailController = TextEditingController(text: 'admin@gmail.com');
  final _passwordController = TextEditingController(text: '12345678');

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _onLoginPressed() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all fields')),
      );
      return;
    }

    await ref.read(authControllerProvider.notifier).login(email, password);

    if (mounted) {
      final authState = ref.read(authControllerProvider);
      if (authState.hasError) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(authState.error.toString())));
      } else {
        Navigator.pushReplacementNamed(context, AppRouter.home);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final authState = ref.watch(authControllerProvider);
    final isLoading = authState.isLoading;

    return LazyChefScaffold(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFCAD3CA)),
              ),
              child: const Text(
                'LAZYCHEF',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0,
                  color: Color(0xFFC85D3B),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Text(
              'Your fridge, organized for dinner.',
              style: textTheme.displayLarge,
            ),
            const SizedBox(height: 14),
            Text(
              'Sign in to scan ingredients, review recipes, and keep previous fridge checks close at hand.',
              style: textTheme.bodyLarge?.copyWith(
                color: const Color(0xFF53615A),
              ),
            ),
            const SizedBox(height: 28),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(22),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Welcome back', style: textTheme.titleLarge),
                    const SizedBox(height: 8),
                    Text(
                      'Sign in to keep your pantry history and recipe suggestions in sync.',
                      style: textTheme.bodyMedium?.copyWith(
                        color: const Color(0xFF53615A),
                      ),
                    ),
                    const SizedBox(height: 20),
                    TextField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      enabled: !isLoading,
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        hintText: 'chef@lazykitchen.app',
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: _passwordController,
                      obscureText: true,
                      enabled: !isLoading,
                      decoration: const InputDecoration(
                        labelText: 'Password',
                        hintText: 'Enter your password',
                      ),
                    ),
                    const SizedBox(height: 22),
                    isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : AppButton.primary(
                            label: 'Sign in',
                            icon: Icons.arrow_forward_rounded,
                            backgroundColor: const Color(0xFFFFD166),
                            foregroundColor: const Color(0xFF2C3236),
                            onPressed: _onLoginPressed,
                          ),
                    const SizedBox(height: 12),
                    AppButton.secondary(
                      label: 'Create an account',
                      onPressed: isLoading
                          ? () {} // Do nothing when loading
                          : () {
                              Navigator.pushNamed(context, AppRouter.register);
                            },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 18),
            const _PreviewStrip(),
          ],
        ),
      ),
    );
  }
}

class _PreviewStrip extends StatelessWidget {
  const _PreviewStrip();

  @override
  Widget build(BuildContext context) {
    final items = const [
      ('Scan', Icons.photo_camera_outlined, 'Capture the shelf in seconds'),
      ('Detect', Icons.eco_outlined, 'Highlight likely ingredients'),
      (
        'Cook',
        Icons.soup_kitchen_outlined,
        'Get recipes that fit what you have',
      ),
    ];

    return Column(
      children: items
          .map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFCAD3CA)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: const Color(0xFF23433C).withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(item.$2, color: const Color(0xFF23433C)),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.$1,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            item.$3,
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(color: const Color(0xFF53615A)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          )
          .toList(),
    );
  }
}
