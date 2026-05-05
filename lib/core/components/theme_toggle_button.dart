import 'package:flutter/material.dart';
import 'package:mangatracker/core/service_locator/service_locator.dart';
import 'package:mangatracker/core/services/theme_service.dart';

/// Bouton compact pour basculer rapidement entre thème clair / sombre /
/// système. Pensé pour la barre d'actions des pages publiques (login,
/// register, mot de passe oublié) où il n'y a pas accès au profil pour
/// changer de thème.
///
/// Affichage : icône cyclable (soleil → lune → auto → soleil...).
class ThemeToggleButton extends StatefulWidget {
  const ThemeToggleButton({super.key});

  @override
  State<ThemeToggleButton> createState() => _ThemeToggleButtonState();
}

class _ThemeToggleButtonState extends State<ThemeToggleButton> {
  ThemeService? _service;
  ThemeMode? _mode;

  @override
  void initState() {
    super.initState();
    _loadService();
  }

  Future<void> _loadService() async {
    try {
      final svc = await getIt.getAsync<ThemeService>();
      if (!mounted) return;
      setState(() {
        _service = svc;
        _mode = svc.getCurrentThemeMode();
      });
    } catch (_) {
      // Service indisponible : on ne montre pas le bouton.
    }
  }

  IconData _iconFor(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return Icons.light_mode_outlined;
      case ThemeMode.dark:
        return Icons.dark_mode_outlined;
      case ThemeMode.system:
        return Icons.brightness_auto_outlined;
    }
  }

  ThemeMode _next(ThemeMode current) {
    switch (current) {
      case ThemeMode.system:
        return ThemeMode.light;
      case ThemeMode.light:
        return ThemeMode.dark;
      case ThemeMode.dark:
        return ThemeMode.system;
    }
  }

  Future<void> _cycle() async {
    final svc = _service;
    if (svc == null) return;
    final next = _next(_mode ?? ThemeMode.system);
    await svc.setThemeMode(next);
    if (!mounted) return;
    setState(() => _mode = next);
  }

  @override
  Widget build(BuildContext context) {
    if (_service == null || _mode == null) {
      return const SizedBox(width: 48, height: 48);
    }
    return IconButton(
      onPressed: _cycle,
      icon: Icon(_iconFor(_mode!)),
      tooltip: switch (_mode!) {
        ThemeMode.light => 'Thème clair',
        ThemeMode.dark => 'Thème sombre',
        ThemeMode.system => 'Thème système',
      },
    );
  }
}
