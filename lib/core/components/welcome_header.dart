import 'package:flutter/material.dart';
import 'package:mangatracker/l10n/app_localizations.dart';

class WelcomeHeader extends StatelessWidget {
  final String? username;

  const WelcomeHeader({super.key, this.username});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Row(
      children: [
        const CircleAvatar(
          radius: 20,
          backgroundColor: Colors.transparent,
          child: ClipOval(child: Image(image: AssetImage('assets/images/mask_logo.png'))),
        ),
        const SizedBox(width: 10),
        // Expanded + une ligne : un nom affiché peut faire 80 caractères,
        // il est tronqué au lieu de déborder.
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppLocalizations.of(context)?.homeGreeting ?? 'Bonjour,',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: textTheme.bodySmall,
              ),
              AnimatedOpacity(
                duration: const Duration(milliseconds: 800),
                opacity: username == null ? 0.0 : 1.0,
                child: Text(
                  username ?? '',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  key: ValueKey<String>(username ?? ''),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
