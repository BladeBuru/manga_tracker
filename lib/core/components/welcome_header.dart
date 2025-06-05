import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class WelcomeHeader extends StatelessWidget {
  final String? username;

  const WelcomeHeader({super.key, this.username});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const CircleAvatar(
          radius: 20,
          backgroundColor: Colors.transparent,
          child: ClipOval(child: Image(image: AssetImage('assets/images/mask_logo.png'))),
        ),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Bonjour,', style: Theme.of(context).textTheme.bodySmall),
            AnimatedOpacity(
              duration: const Duration(milliseconds: 800),
              opacity: username == null ? 0.0 : 1.0,
              child: Text(
                username ?? '',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
                key: ValueKey<String>(username ?? ''),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
