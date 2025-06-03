import 'package:dashbook/dashbook.dart';
import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../features/auth/widgets/square_tile.dart';

void addSquareTileStory(Dashbook dashbook) {
  dashbook.storiesOf('Auth/SquareTile')

  // 🔳 Variante classique carrée
      .add('Carré', (_) {
    return MaterialApp(
      theme: AppTheme.light,
      home: Scaffold(
        appBar: AppBar(title: const Text("SquareTile - Carré")),
        body: Center(
          child: SquareTile(
            imagePath: 'assets/images/google_logo.png',
            onTap: () => debugPrint('Carré : Google tap'),
            isRounded: false,
          ),
        ),
      ),
    );
  })

  // ⚪ Variante ronde
      .add('Rond', (_) {
    return MaterialApp(
      theme: AppTheme.light,
      home: Scaffold(
        appBar: AppBar(title: const Text("SquareTile - Rond")),
        body: Center(
          child: SquareTile(
            imagePath: 'assets/images/apple_logo.png',
            onTap: () => debugPrint('Rond : Apple tap'),
            isRounded: true,
          ),
        ),
      ),
    );
  })
  // ⚪ Variante ronde
      .add('Rond', (_) {
    return MaterialApp(
      theme: AppTheme.light,
      home: Scaffold(
        appBar: AppBar(title: const Text("SquareTile - Rond")),
        body: Center(
          child: SquareTile(
            imagePath: 'assets/images/mask_logo.png',
            onTap: () => debugPrint('Rond :Logo tap'),
            isRounded: true,
            size: 100,
          ),
        ),
      ),
    );
  })

  // 🎛️ Test de taille personnalisée
      .add('Taille personnalisée', (_) {
    return MaterialApp(
      theme: AppTheme.light,
      home: Scaffold(
        appBar: AppBar(title: const Text("SquareTile - Taille personnalisée")),
        body: Center(
          child: SquareTile(
            imagePath: 'assets/images/google_logo.png',
            size: 80,
            onTap: () => debugPrint('Taille 80 tap'),
            isRounded: true,
          ),
        ),
      ),
    );
  })

  // 🔁 Grille de plusieurs logos
      .add('Grille logos sociaux', (_) {
    return MaterialApp(
      theme: AppTheme.light,
      home: Scaffold(
        appBar: AppBar(title: const Text("SquareTile - Grille")),
        body: Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SquareTile(
                imagePath: 'assets/images/google_logo.png',
                onTap: () => debugPrint('Google tap'),
              ),
              const SizedBox(width: 20),
              SquareTile(
                imagePath: 'assets/images/apple_logo.png',
                onTap: () => debugPrint('Apple tap'),
                isRounded: true,
              ),
            ],
          ),
        ),
      ),
    );
  });
}
