import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mangatracker/features/manga/services/custom_selectors.service.dart';
import 'package:mangatracker/core/notifier/notifier.dart';
import 'package:mangatracker/core/service_locator/service_locator.dart';
import 'package:mangatracker/l10n/app_localizations.dart';
import 'package:url_launcher/url_launcher.dart';

class CustomSelectorsPage extends StatefulWidget {
  const CustomSelectorsPage({super.key});

  @override
  State<CustomSelectorsPage> createState() => _CustomSelectorsPageState();
}

class _CustomSelectorsPageState extends State<CustomSelectorsPage> {
  final _service = CustomSelectorsService();
  final _notifier = getIt<Notifier>();
  List<CustomSelector> _selectors = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSelectors();
  }

  Future<void> _loadSelectors() async {
    setState(() => _isLoading = true);
    final selectors = await _service.loadSelectors();
    setState(() {
      _selectors = selectors;
      _isLoading = false;
    });
  }

  Future<void> _addSelector() async {
    final l10n = AppLocalizations.of(context);
    final domainController = TextEditingController();
    final selectorController = TextEditingController();
    final descriptionController = TextEditingController();
    SelectorType selectedType =
        SelectorType.urlPattern; // Par défaut : Pattern d'URL

    final result = await showDialog<bool>(
      context: context,
      builder:
          (ctx) => StatefulBuilder(
            builder: (context, setState) {
              return AlertDialog(
                title: Row(
                  children: [
                    const Icon(Icons.code, color: Colors.blue),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        l10n?.addCustomSelector ?? 'Ajouter un sélecteur',
                      ),
                    ),
                  ],
                ),
                content: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (selectedType != SelectorType.urlPattern)
                        TextField(
                          controller: domainController,
                          decoration: InputDecoration(
                            labelText:
                                l10n?.selectorDomainLabel ??
                                'Domaine (ex: exemple.com)',
                            hintText: 'exemple.com',
                            border: const OutlineInputBorder(),
                            prefixIcon: const Icon(Icons.language),
                          ),
                        ),
                      if (selectedType != SelectorType.urlPattern)
                        const SizedBox(height: 16),
                      TextField(
                        controller: selectorController,
                        decoration: InputDecoration(
                          labelText:
                              selectedType == SelectorType.urlPattern
                                  ? (l10n?.selectorUrlPatternLabel ??
                                      'Pattern d\'URL (regex)')
                                  : (l10n?.selectorCssLabel ?? 'Sélecteur CSS'),
                          hintText:
                              selectedType == SelectorType.urlPattern
                                  ? '/chapter-(\\d+)/'
                                  : '.ad-banner, #ad-container',
                          border: const OutlineInputBorder(),
                          prefixIcon: const Icon(Icons.code),
                          helperText:
                              selectedType == SelectorType.urlPattern
                                  ? (l10n?.selectorUrlPatternHint ??
                                      'Exemple : /chapter-(\\d+)/ pour détecter /chapter-22')
                                  : null,
                        ),
                        maxLines:
                            selectedType == SelectorType.urlPattern ? 2 : 3,
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<SelectorType>(
                        value: selectedType,
                        decoration: InputDecoration(
                          labelText:
                              l10n?.selectorTypeLabel ?? 'Type de sélecteur',
                          border: const OutlineInputBorder(),
                          prefixIcon: const Icon(Icons.category),
                        ),
                        items: [
                          DropdownMenuItem(
                            value: SelectorType.urlPattern,
                            child: Text(
                              l10n?.selectorTypeUrlPattern ?? 'Pattern d\'URL',
                            ),
                          ),
                          DropdownMenuItem(
                            value: SelectorType.adBlocker,
                            child: Text(
                              l10n?.selectorTypeAdBlocker ??
                                  'Bloqueur de publicités',
                            ),
                          ),
                          DropdownMenuItem(
                            value: SelectorType.chapterContent,
                            child: Text(
                              l10n?.selectorTypeChapterContent ??
                                  'Contenu du chapitre',
                            ),
                          ),
                        ],
                        onChanged: (value) {
                          if (value != null) {
                            setState(() => selectedType = value);
                          }
                        },
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: descriptionController,
                        decoration: InputDecoration(
                          labelText:
                              l10n?.selectorDescriptionLabel ??
                              'Description (optionnel)',
                          hintText:
                              l10n?.selectorDescriptionHint ??
                              'Description du sélecteur',
                          border: const OutlineInputBorder(),
                          prefixIcon: const Icon(Icons.description),
                        ),
                        maxLines: 2,
                      ),
                      const SizedBox(height: 16),
                      // Section d'exemples
                      ExpansionTile(
                        leading: const Icon(
                          Icons.lightbulb_outline,
                          color: Colors.amber,
                        ),
                        title: Text(l10n?.selectorExamples ?? 'Exemples'),
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (selectedType == SelectorType.adBlocker) ...[
                                  Text(
                                    l10n?.selectorExamplesAdBlocker ??
                                        'Exemples pour bloquer des publicités :',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  _buildExampleItem(
                                    context,
                                    l10n?.selectorExampleAd1 ??
                                        'Bannière publicitaire',
                                    '.ad-banner, .ad-container',
                                    'Bloque les éléments avec les classes ad-banner ou ad-container',
                                  ),
                                  _buildExampleItem(
                                    context,
                                    l10n?.selectorExampleAd2 ??
                                        'Publicité par ID',
                                    '#advertisement, #ad-wrapper',
                                    'Bloque les éléments avec les IDs advertisement ou ad-wrapper',
                                  ),
                                  _buildExampleItem(
                                    context,
                                    l10n?.selectorExampleAd3 ??
                                        'Iframe publicitaire',
                                    'iframe[src*="ads"], iframe[src*="doubleclick"]',
                                    'Bloque les iframes contenant "ads" ou "doubleclick" dans leur src',
                                  ),
                                  _buildExampleItem(
                                    context,
                                    l10n?.selectorExampleAd4 ??
                                        'Script publicitaire',
                                    'script[src*="advertising"], script[id*="ad"]',
                                    'Bloque les scripts de publicité',
                                  ),
                                ] else if (selectedType ==
                                    SelectorType.urlPattern) ...[
                                  Text(
                                    l10n?.selectorExamplesUrlPattern ??
                                        'Exemples de patterns d\'URL :',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  // Exemple principal : Pattern /chapter-22
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Colors.green.withValues(
                                        alpha: 0.1,
                                      ),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: Colors.green.withValues(
                                          alpha: 0.5,
                                        ),
                                        width: 2,
                                      ),
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            const Icon(
                                              Icons.star,
                                              color: Colors.green,
                                              size: 20,
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              l10n?.selectorExampleUrlPattern ??
                                                  'Exemple : /chapter-22',
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 14,
                                                color: Colors.green,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 12),
                                        Text(
                                          l10n?.selectorExampleUrlPatternExplanation ??
                                              'Si votre site utilise "/chapter-22" dans l\'URL et que le système ne le détecte pas automatiquement :',
                                          style: const TextStyle(fontSize: 11),
                                        ),
                                        const SizedBox(height: 8),
                                        Container(
                                          padding: const EdgeInsets.all(10),
                                          decoration: BoxDecoration(
                                            color: Colors.blue.withValues(
                                              alpha: 0.1,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              6,
                                            ),
                                            border: Border.all(
                                              color: Colors.blue.withValues(
                                                alpha: 0.3,
                                              ),
                                            ),
                                          ),
                                          child: Row(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              const Icon(
                                                Icons.info_outline,
                                                color: Colors.blue,
                                                size: 20,
                                              ),
                                              const SizedBox(width: 8),
                                              Expanded(
                                                child: Text(
                                                  l10n?.selectorUrlPatternGlobal ??
                                                      'ℹ️ Le pattern sera appliqué à TOUS les sites. Pas besoin de spécifier un domaine.',
                                                  style: const TextStyle(
                                                    fontSize: 11,
                                                    height: 1.4,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        _buildFieldExample(
                                          context,
                                          l10n?.selectorUrlPatternLabel ??
                                              'Pattern d\'URL',
                                          '/chapter-(\\d+)/',
                                          l10n?.selectorUrlPatternExampleDesc ??
                                              'Utilisez une expression régulière (regex) avec (\\d+) pour capturer le numéro du chapitre.\n\n'
                                                  'Ce pattern sera appliqué à TOUS les sites.\n\n'
                                                  'Exemples de patterns :\n'
                                                  '• /chapter-(\\d+)/ → détecte /chapter-22\n'
                                                  '• /chapppter-(\\d+)/ → détecte /chapppter-22 (avec 3 p)\n'
                                                  '• /manga/chapter-(\\d+)/ → détecte /manga/chapter-22\n'
                                                  '• /episode-(\\d+)/ → détecte /episode-22',
                                        ),
                                      ],
                                    ),
                                  ),
                                ] else ...[
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Colors.green.withValues(
                                        alpha: 0.1,
                                      ),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: Colors.green.withValues(
                                          alpha: 0.5,
                                        ),
                                        width: 2,
                                      ),
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            const Icon(
                                              Icons.star,
                                              color: Colors.green,
                                              size: 20,
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              l10n?.selectorExampleChapter5 ??
                                                  'Format manga/chapitre-22',
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 14,
                                                color: Colors.green,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 12),
                                        Text(
                                          l10n?.selectorExampleChapter5Explanation ??
                                              'Exemple concret : Si votre URL est "monsite.com/manga/chapitre-22"',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 12,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Container(
                                          padding: const EdgeInsets.all(10),
                                          decoration: BoxDecoration(
                                            color: Colors.blue.withValues(
                                              alpha: 0.1,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              6,
                                            ),
                                            border: Border.all(
                                              color: Colors.blue.withValues(
                                                alpha: 0.3,
                                              ),
                                            ),
                                          ),
                                          child: Row(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              const Icon(
                                                Icons.check_circle,
                                                color: Colors.blue,
                                                size: 20,
                                              ),
                                              const SizedBox(width: 8),
                                              Expanded(
                                                child: Text(
                                                  l10n?.selectorUrlFormatDetected ??
                                                      '✅ BONNE NOUVELLE : Le format "/manga/chapitre-22" dans l\'URL est déjà détecté automatiquement par le système !\n\n'
                                                          'Vous n\'avez PAS besoin d\'ajouter un sélecteur CSS si votre site utilise uniquement ce format dans l\'URL.',
                                                  style: const TextStyle(
                                                    fontSize: 11,
                                                    height: 1.4,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(height: 12),
                                        Text(
                                          l10n?.selectorWhenNeeded ??
                                              'Quand ajouter un sélecteur CSS ?',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 12,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        // Exemple pratique étape par étape
                                        Container(
                                          padding: const EdgeInsets.all(12),
                                          decoration: BoxDecoration(
                                            color: Colors.orange.withValues(
                                              alpha: 0.1,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                            border: Border.all(
                                              color: Colors.orange.withValues(
                                                alpha: 0.3,
                                              ),
                                            ),
                                          ),
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                children: [
                                                  const Icon(
                                                    Icons.school,
                                                    color: Colors.orange,
                                                    size: 18,
                                                  ),
                                                  const SizedBox(width: 6),
                                                  Text(
                                                    l10n?.selectorPracticalExample ??
                                                        'Exemple pratique :',
                                                    style: const TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      fontSize: 12,
                                                      color: Colors.orange,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 10),
                                              Text(
                                                l10n?.selectorExampleScenario ??
                                                    'Cas : Votre site utilise "/chapppter-22" (avec 3 p) au lieu de "/chapter-22"',
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 11,
                                                ),
                                              ),
                                              const SizedBox(height: 8),
                                              _buildStepExample(
                                                context,
                                                '1',
                                                l10n?.selectorStep1 ??
                                                    'Ouvrez la page du chapitre dans votre navigateur',
                                                'https://monsite.com/manga/chapppter-22',
                                              ),
                                              _buildStepExample(
                                                context,
                                                '2',
                                                l10n?.selectorStep2 ??
                                                    'Appuyez sur F12 pour ouvrir les outils de développement',
                                                '',
                                              ),
                                              _buildStepExample(
                                                context,
                                                '3',
                                                l10n?.selectorStep3 ??
                                                    'Cliquez sur l\'icône "Inspecter" (ou Ctrl+Shift+C)',
                                                '',
                                              ),
                                              _buildStepExample(
                                                context,
                                                '4',
                                                l10n?.selectorStep4 ??
                                                    'Cliquez sur le conteneur qui contient les images du chapitre',
                                                '',
                                              ),
                                              _buildStepExample(
                                                context,
                                                '5',
                                                l10n?.selectorStep5 ??
                                                    'Dans le code HTML, trouvez la classe ou l\'ID du conteneur',
                                                'Exemple : <div class="manga-content"> ou <div id="chapter-images">',
                                              ),
                                              const SizedBox(height: 8),
                                              Container(
                                                padding: const EdgeInsets.all(
                                                  10,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: Colors.green
                                                      .withValues(alpha: 0.1),
                                                  borderRadius:
                                                      BorderRadius.circular(6),
                                                  border: Border.all(
                                                    color: Colors.green
                                                        .withValues(alpha: 0.3),
                                                  ),
                                                ),
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      l10n?.selectorFillForm ??
                                                          'Remplissez le formulaire :',
                                                      style: const TextStyle(
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        fontSize: 11,
                                                      ),
                                                    ),
                                                    const SizedBox(height: 6),
                                                    _buildFormFieldExample(
                                                      context,
                                                      l10n?.selectorDomainLabel ??
                                                          'Domaine',
                                                      'monsite.com',
                                                    ),
                                                    const SizedBox(height: 6),
                                                    _buildFormFieldExample(
                                                      context,
                                                      l10n?.selectorCssLabel ??
                                                          'Sélecteur CSS',
                                                      '.manga-content',
                                                      isCode: true,
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(height: 12),
                                        _buildFieldExample(
                                          context,
                                          l10n?.selectorDomainLabel ??
                                              'Domaine',
                                          'monsite.com',
                                          l10n?.selectorDomainExampleDesc ??
                                              'Mettez uniquement le nom de domaine (sans http://, sans www, sans le chemin /manga/chapitre-22)',
                                        ),
                                        const SizedBox(height: 8),
                                        _buildFieldExample(
                                          context,
                                          l10n?.selectorCssLabel ??
                                              'Sélecteur CSS',
                                          '.manga-content, [data-chapter], .manga-chapter',
                                          l10n?.selectorCssWhenNeededDesc ??
                                              '⚠️ UNIQUEMENT si votre site a besoin d\'un sélecteur spécifique pour identifier le contenu HTML de la page.\n\n'
                                                  'Si le système détecte déjà bien votre chapitre via l\'URL, vous n\'avez PAS besoin d\'ajouter un sélecteur CSS.\n\n'
                                                  'Ajoutez un sélecteur CSS SEULEMENT si :\n'
                                                  '• Le système ne détecte pas correctement le contenu du chapitre\n'
                                                  '• Vous voulez bloquer des publicités spécifiques à ce site\n'
                                                  '• Le site utilise des classes/IDs particuliers pour le contenu\n\n'
                                                  'Pour trouver le sélecteur : Ouvrez la page (F12 → Inspecter), trouvez le conteneur des images du chapitre, '
                                                  'et utilisez sa classe ou ID (ex: .manga-content, #chapter-images)',
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    l10n?.selectorOtherExamples ??
                                        'Autres exemples courants :',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  _buildExampleItem(
                                    context,
                                    l10n?.selectorExampleChapter1 ??
                                        'Conteneur de chapitre',
                                    '.chapter-content, .chapter-images',
                                    'Identifie le conteneur principal du chapitre',
                                  ),
                                  _buildExampleItem(
                                    context,
                                    l10n?.selectorExampleChapter2 ??
                                        'Lecteur de manga',
                                    '.manga-reader, .reader-content',
                                    'Identifie la zone de lecture',
                                  ),
                                  _buildExampleItem(
                                    context,
                                    l10n?.selectorExampleChapter3 ??
                                        'Images du chapitre',
                                    '.chapter-content img, .reading-content img',
                                    'Identifie les images du chapitre',
                                  ),
                                  _buildExampleItem(
                                    context,
                                    l10n?.selectorExampleChapter4 ??
                                        'Contenu de lecture',
                                    '[class*="chapter"], [id*="chapter"]',
                                    'Identifie les éléments contenant "chapter" dans leur classe ou ID',
                                  ),
                                ],
                                const SizedBox(height: 12),
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.blue.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: Colors.blue.withValues(alpha: 0.3),
                                    ),
                                  ),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Icon(
                                        Icons.info_outline,
                                        color: Colors.blue,
                                        size: 20,
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          l10n?.selectorExamplesHint ??
                                              'Astuce : Utilisez les outils de développement de votre navigateur (F12) pour inspecter les éléments et trouver les sélecteurs CSS appropriés.',
                                          style: const TextStyle(fontSize: 12),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx, false),
                    child: Text(l10n?.cancel ?? 'Annuler'),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      if (selectedType == SelectorType.urlPattern) {
                        // Pour les patterns d'URL, seul le pattern est requis
                        if (selectorController.text.trim().isEmpty) {
                          _notifier.error(
                            l10n?.selectorRequiredFields ??
                                'Le pattern est requis',
                          );
                          return;
                        }
                      } else {
                        // Pour les autres types, domaine et sélecteur sont requis
                        if (domainController.text.trim().isEmpty ||
                            selectorController.text.trim().isEmpty) {
                          _notifier.error(
                            l10n?.selectorRequiredFields ??
                                'Tous les champs sont requis',
                          );
                          return;
                        }
                      }
                      Navigator.pop(ctx, true);
                    },
                    child: Text(l10n?.validate ?? 'Valider'),
                  ),
                ],
              );
            },
          ),
    );

    if (result == true) {
      final selector = CustomSelector(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        domain:
            selectedType == SelectorType.urlPattern
                ? '*' // Domaine générique pour les patterns d'URL
                : domainController.text.trim(),
        selector: selectorController.text.trim(),
        type: selectedType,
        description:
            descriptionController.text.trim().isEmpty
                ? null
                : descriptionController.text.trim(),
      );

      await _service.addSelector(selector);
      await _loadSelectors();
      _notifier.success(l10n?.selectorAdded ?? 'Sélecteur ajouté');
    }
  }

  Future<void> _deleteSelector(CustomSelector selector) async {
    final l10n = AppLocalizations.of(context);
    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: Text(l10n?.deleteSelector ?? 'Supprimer le sélecteur'),
            content: Text(
              l10n?.deleteSelectorConfirm ??
                  'Êtes-vous sûr de vouloir supprimer ce sélecteur ?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: Text(l10n?.cancel ?? 'Annuler'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade700,
                  foregroundColor: Colors.white,
                ),
                onPressed: () => Navigator.pop(ctx, true),
                child: Text(l10n?.delete ?? 'Supprimer'),
              ),
            ],
          ),
    );

    if (confirm == true) {
      await _service.removeSelector(selector.id);
      await _loadSelectors();
      _notifier.success(l10n?.selectorDeleted ?? 'Sélecteur supprimé');
    }
  }

  Future<void> _exportSelectors() async {
    final l10n = AppLocalizations.of(context);
    final json = await _service.exportSelectors();
    await Clipboard.setData(ClipboardData(text: json));
    _notifier.success(
      l10n?.selectorsExported ?? 'Sélecteurs exportés dans le presse-papiers',
    );
  }

  Future<void> _importSelectors() async {
    final l10n = AppLocalizations.of(context);
    final jsonController = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: Text(l10n?.importSelectors ?? 'Importer des sélecteurs'),
            content: TextField(
              controller: jsonController,
              decoration: InputDecoration(
                labelText: l10n?.selectorsJsonLabel ?? 'JSON des sélecteurs',
                hintText: '[{"id": "...", "domain": "...", ...}]',
                border: const OutlineInputBorder(),
              ),
              maxLines: 10,
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: Text(l10n?.cancel ?? 'Annuler'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: Text(l10n?.import ?? 'Importer'),
              ),
            ],
          ),
    );

    if (result == true) {
      final count = await _service.importSelectors(jsonController.text);
      await _loadSelectors();
      final l10n = AppLocalizations.of(context);
      _notifier.success(
        l10n?.selectorsImported(count.toString()) ??
            '$count sélecteur(s) importé(s)',
      );
    }
  }

  Future<void> _shareSelectors() async {
    final l10n = AppLocalizations.of(context);
    final json = await _service.exportSelectors();
    await _service.storeExportedSelectors(json);

    // Ouvrir Discord pour partager
    final uri = Uri.parse('https://discord.gg/X6sBgFY7');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
      _notifier.info(
        l10n?.selectorsReadyToShare ??
            'Sélecteurs prêts à être partagés ! Collez le JSON dans Discord.',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n?.customSelectors ?? 'Sélecteurs personnalisés'),
        actions: [
          IconButton(
            icon: const Icon(Icons.upload_file),
            tooltip: l10n?.importSelectors ?? 'Importer',
            onPressed: _importSelectors,
          ),
          IconButton(
            icon: const Icon(Icons.download),
            tooltip: l10n?.exportSelectors ?? 'Exporter',
            onPressed: _exportSelectors,
          ),
          IconButton(
            icon: const Icon(Icons.share),
            tooltip: l10n?.shareSelectors ?? 'Partager',
            onPressed: _shareSelectors,
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, layoutConstraints) {
          final horizontalPadding = layoutConstraints.maxWidth >= 600 ? 24.0 : 0.0;
          final content = _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _selectors.isEmpty
              ? Builder(
                builder: (context) {
                  final mutedColor = Theme.of(
                    context,
                  ).colorScheme.onSurface.withValues(alpha: 0.6);
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.code_off, size: 64, color: mutedColor),
                        const SizedBox(height: 16),
                        Text(
                          l10n?.noCustomSelectors ??
                              'Aucun sélecteur personnalisé',
                          style: TextStyle(fontSize: 18, color: mutedColor),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          l10n?.addFirstSelector ??
                              'Ajoutez votre premier sélecteur pour commencer',
                          style: TextStyle(color: mutedColor),
                        ),
                      ],
                    ),
                  );
                },
              )
              : ListView.builder(
                padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                itemCount: _selectors.length,
                itemBuilder: (context, index) {
                  final selector = _selectors[index];
                  return Card(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: ListTile(
                      leading: Icon(
                        selector.type == SelectorType.urlPattern
                            ? Icons.link
                            : selector.type == SelectorType.adBlocker
                            ? Icons.block
                            : Icons.book,
                        color:
                            selector.type == SelectorType.urlPattern
                                ? Colors.green
                                : selector.type == SelectorType.adBlocker
                                ? Colors.red
                                : Colors.blue,
                      ),
                      title: Text(
                        selector.type == SelectorType.urlPattern
                            ? (l10n?.selectorUrlPatternGlobal ??
                                'Pattern global')
                            : selector.domain,
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            selector.selector,
                            style: const TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 12,
                            ),
                          ),
                          if (selector.description != null)
                            Text(
                              selector.description!,
                              style: TextStyle(
                                fontSize: 11,
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurface.withValues(alpha: 0.6),
                              ),
                            ),
                          const SizedBox(height: 4),
                          Chip(
                            label: Text(
                              selector.type == SelectorType.urlPattern
                                  ? l10n?.selectorTypeUrlPattern ??
                                      'Pattern URL'
                                  : selector.type == SelectorType.adBlocker
                                  ? l10n?.selectorTypeAdBlocker ??
                                      'Bloqueur de pub'
                                  : l10n?.selectorTypeChapterContent ??
                                      'Contenu',
                              style: const TextStyle(fontSize: 10),
                            ),
                            visualDensity: VisualDensity.compact,
                          ),
                        ],
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete_outline),
                        color: Colors.red.shade700,
                        tooltip: l10n?.deleteSelector ?? 'Supprimer',
                        onPressed: () => _deleteSelector(selector),
                      ),
                    ),
                  );
                },
              );
          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 700),
              child: content,
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addSelector,
        icon: const Icon(Icons.add),
        label: Text(l10n?.addCustomSelector ?? 'Ajouter'),
      ),
    );
  }

  Widget _buildStepExample(
    BuildContext context,
    String stepNumber,
    String instruction,
    String example,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: Colors.orange,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                stepNumber,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(instruction, style: const TextStyle(fontSize: 11)),
                if (example.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black87,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      example,
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 10,
                        color: Colors.lightGreenAccent,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormFieldExample(
    BuildContext context,
    String label,
    String value, {
    bool isCode = false,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 80,
          child: Text(
            '$label :',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        ),
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color:
                  isCode
                      ? Colors.black87
                      : Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(
                color: Theme.of(
                  context,
                ).colorScheme.outline.withValues(alpha: 0.2),
              ),
            ),
            child: Text(
              value,
              style: TextStyle(
                fontFamily: isCode ? 'monospace' : null,
                fontSize: 10,
                color:
                    isCode
                        ? Colors.lightGreenAccent
                        : Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFieldExample(
    BuildContext context,
    String fieldName,
    String exampleValue,
    String explanation,
  ) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Theme.of(
          context,
        ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.label,
                size: 16,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 6),
              Text(
                fieldName,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.black87,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              exampleValue,
              style: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 11,
                color: Colors.lightGreenAccent,
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            explanation,
            style: TextStyle(
              fontSize: 10,
              color: Theme.of(
                context,
              ).colorScheme.onSurface.withValues(alpha: 0.8),
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExampleItem(
    BuildContext context,
    String title,
    String selector,
    String description,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Theme.of(
            context,
          ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.black87,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                selector,
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 12,
                  color: Colors.lightGreenAccent,
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              description,
              style: TextStyle(
                fontSize: 11,
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
