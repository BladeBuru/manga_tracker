import 'package:flutter/material.dart';

class SquareTile extends StatelessWidget {
  final String imagePath;
  final VoidCallback? onTap;
  final bool isRounded; // si true = rond, sinon carré
  final double size;

  const SquareTile({
    super.key,
    required this.imagePath,
    this.onTap,
    this.isRounded = false,
    this.size = 60,
  });

  @override
  Widget build(BuildContext context) {
    final borderRadius = BorderRadius.circular(isRounded ? size : 16);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: borderRadius,
        child: Ink(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.white),
            borderRadius: borderRadius,
            color: Colors.grey[100],
          ),
          child: Image.asset(
            imagePath,
            height: size,
            width: size,
          ),
        ),
      ),
    );
  }
}
