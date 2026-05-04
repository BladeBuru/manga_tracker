import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:mangatracker/core/theme/app_radius.dart';

class FilterButton extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onPressed;

  const FilterButton({
    super.key,
    required this.label,
    required this.selected,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: selected 
            ? theme.colorScheme.primary 
            : theme.colorScheme.surface,
        foregroundColor: selected 
            ? theme.colorScheme.onPrimary 
            : theme.colorScheme.onSurface.withValues(alpha: 0.7),
        elevation: selected ? 2 : 0,
        shadowColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.huge)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: selected 
              ? theme.colorScheme.onPrimary 
              : theme.colorScheme.onSurface.withValues(alpha: 0.7),
        ),
      ),
    );
  }
}
