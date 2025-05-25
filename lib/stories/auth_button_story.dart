import 'package:dashbook/dashbook.dart';
import 'package:flutter/material.dart';

import '../core/components/auth_button.dart';
import '../core/theme/app_theme.dart';

void addAuthButtonStory(Dashbook dashbook) {
  dashbook.storiesOf('Core/AuthButton')
      .add('Default', (ctx) => MaterialApp(
    theme: AppTheme.light,
    home: Scaffold(
      body: Center(
        child: SizedBox(
          width: 300, // Limite de largeur
          height: 100,
          child: AuthButton(
            text: 'Se connecter',
            onTap: () => debugPrint("AuthButton tapped"),
          ),
        ),
      ),
    ),
  ))
      .add('Long text', (ctx) => MaterialApp(
    theme: AppTheme.light,
    home: Scaffold(
      body: Center(
        child: SizedBox(
          height: 100,
          child: AuthButton(
            text: 'Connexion avec un très long texte',
            onTap: () => debugPrint("Tapped"),
          ),
        ),
      ),
    ),
  ));
}
