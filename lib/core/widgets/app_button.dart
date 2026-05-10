import 'package:flutter/material.dart';

class AppButton extends StatelessWidget {
  const AppButton.primary({
    required this.label,
    required this.onPressed,
    this.icon,
    this.backgroundColor,
    this.foregroundColor,
    super.key,
  }) : _variant = _AppButtonVariant.primary;

  const AppButton.secondary({
    required this.label,
    required this.onPressed,
    this.icon,
    this.backgroundColor,
    this.foregroundColor,
    super.key,
  }) : _variant = _AppButtonVariant.secondary;

  final String label;
  final VoidCallback onPressed;
  final IconData? icon;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final _AppButtonVariant _variant;

  @override
  Widget build(BuildContext context) {
    final isPrimary = _variant == _AppButtonVariant.primary;
    final colorScheme = Theme.of(context).colorScheme;

    return SizedBox(
      width: double.infinity,
      child: FilledButton(
        style: FilledButton.styleFrom(
          backgroundColor:
              backgroundColor ??
              (isPrimary
                  ? colorScheme.secondary
                  : Colors.white.withValues(alpha: 0.75)),
          foregroundColor:
              foregroundColor ??
              (isPrimary ? Colors.white : colorScheme.primary),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: isPrimary
                  ? Colors.transparent
                  : colorScheme.outline.withValues(alpha: 0.9),
            ),
          ),
        ),
        onPressed: onPressed,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 18),
              const SizedBox(width: 10),
            ],
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

enum _AppButtonVariant { primary, secondary }
