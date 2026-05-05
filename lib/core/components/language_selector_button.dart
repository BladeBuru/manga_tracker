import 'package:flutter/material.dart';
import 'package:mangatracker/core/service_locator/service_locator.dart';
import 'package:mangatracker/core/services/language_service.dart';
import 'package:mangatracker/core/theme/app_radius.dart';
import 'package:mangatracker/l10n/app_localizations.dart';

/// Widget réutilisable pour afficher un bouton de sélection de langue avec un drapeau
class LanguageSelectorButton extends StatelessWidget {
  const LanguageSelectorButton({super.key});

  static Widget _getFlagIcon(String languageCode) {
    String assetPath;
    switch (languageCode) {
      case 'fr':
        assetPath = 'assets/images/flags/fr.png';
        break;
      case 'en':
        assetPath = 'assets/images/flags/uk.png';
        break;
      case 'de':
        assetPath = 'assets/images/flags/de.png';
        break;
      case 'ja':
        assetPath = 'assets/images/flags/jp.png';
        break;
      case 'ko':
        assetPath = 'assets/images/flags/kr.png';
        break;
      case 'pt':
        assetPath = 'assets/images/flags/pt.png';
        break;
      case 'es':
        assetPath = 'assets/images/flags/sp.png';
        break;
      default:
        return const SizedBox.shrink();
    }
    
    return ClipRRect(
      borderRadius: AppRadius.circularXs,
      child: Image.asset(
        assetPath,
        width: 24,
        height: 18,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            width: 24,
            height: 18,
            decoration: BoxDecoration(
              borderRadius: AppRadius.circularXs,
              color: Colors.grey.withValues(alpha: 0.3),
              border: Border.all(color: Colors.grey.withValues(alpha: 0.3), width: 0.5),
            ),
            child: const Icon(Icons.flag, size: 12, color: Colors.grey),
          );
        },
      ),
    );
  }

  /// Méthode statique pour afficher le sélecteur de langue (utilisable depuis n'importe où)
  static Future<void> showLanguageSelector(
    BuildContext context, {
    void Function(Locale)? onLanguageChanged,
  }) async {
    final l10n = AppLocalizations.of(context);
    LanguageService languageService;
    try {
      languageService = getIt<LanguageService>();
    } catch (e) {
      languageService = await getIt.getAsync<LanguageService>();
    }
    final currentLocale = languageService.getCurrentLocale();
    final supportedLocales = languageService.getSupportedLocales();

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.xxxl),
        ),
        // Responsive : 85% de la largeur sur mobile/tablette, max 560 sur web
        // (sinon le dialog prenait toute la largeur écran et rendait moche).
        child: LayoutBuilder(
          builder: (context, constraints) {
            final screenWidth = MediaQuery.of(context).size.width;
            final dialogWidth = screenWidth >= 700
                ? 560.0
                : screenWidth * 0.85;
            return ConstrainedBox(
              constraints: BoxConstraints(maxWidth: dialogWidth),
              child: Container(
                width: dialogWidth,
                padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                l10n?.selectLanguage ?? 'Sélectionner la langue',
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 16),
              ...supportedLocales.map((locale) {
                final isSelected = locale.languageCode == currentLocale.languageCode;
                return Container(
                  margin: const EdgeInsets.symmetric(vertical: 6),
                  decoration: BoxDecoration(
                    color: isSelected 
                        ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.08)
                        : Colors.transparent,
                    borderRadius: AppRadius.circularXl,
                    border: Border.all(
                      color: isSelected 
                          ? Theme.of(context).colorScheme.primary
                          : Colors.grey.withValues(alpha: 0.2),
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: InkWell(
                    onTap: () async {
                      await languageService.setLanguage(locale);
                      if (context.mounted) {
                        Navigator.of(context).pop();
                        onLanguageChanged?.call(locale);
                      }
                    },
                    borderRadius: AppRadius.circularXl,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      child: Row(
                        children: [
                          _getFlagIcon(locale.languageCode),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Text(
                              languageService.getLanguageName(locale, context),
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                                color: isSelected 
                                    ? Theme.of(context).colorScheme.primary
                                    : null,
                              ),
                            ),
                          ),
                          if (isSelected)
                            Icon(
                              Icons.check_circle,
                              color: Theme.of(context).colorScheme.primary,
                              size: 20,
                            ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(
                  l10n?.cancel ?? 'Annuler',
                  style: TextStyle(
                    fontSize: 14,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
            ],
          ),
        ),
            );
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<LanguageService>(
      future: () async {
        try {
          return getIt<LanguageService>();
        } catch (e) {
          return await getIt.getAsync<LanguageService>();
        }
      }(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const SizedBox.shrink();
        }
        
        final languageService = snapshot.data!;
        final currentLocale = languageService.getCurrentLocale();
        
        return IconButton(
          icon: _getFlagIcon(currentLocale.languageCode),
          onPressed: () => LanguageSelectorButton.showLanguageSelector(context),
          tooltip: AppLocalizations.of(context)?.selectLanguage ?? 'Sélectionner la langue',
        );
      },
    );
  }
}

