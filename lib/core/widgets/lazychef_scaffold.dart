import 'package:flutter/material.dart';

class LazyChefScaffold extends StatelessWidget {
  const LazyChefScaffold({
    required this.child,
    this.bottomNavigationBar,
    super.key,
  });

  final Widget child;
  final Widget? bottomNavigationBar;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      backgroundColor: Colors.transparent,
      bottomNavigationBar: bottomNavigationBar,
      body: Stack(
        children: [
          const _Backdrop(),
          SafeArea(
            child: Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 560),
                child: child,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Backdrop extends StatelessWidget {
  const _Backdrop();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Theme.of(context).scaffoldBackgroundColor,
            const Color(0xFFFFFFFF),
            const Color(0xFFEAF0EA),
          ],
        ),
      ),
      child: const SizedBox.expand(),
    );
  }
}
