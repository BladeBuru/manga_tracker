import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

/// Service pour traduire automatiquement les textes (descriptions, changelogs)
class TranslationService {
  static const String _cachePrefix = 'translated_';
  static const Duration _cacheDuration = Duration(days: 30);
  
  // LibreTranslate (gratuit, open source)
  static const String _libreTranslateUrl = 'https://libretranslate.com/translate';
  
  // MyMemory API (gratuit avec limites)
  static const String _myMemoryUrl = 'https://api.mymemory.translated.net/get';
  
  // Google Translate (non officiel mais gratuit, peut gérer de longs textes)
  static const String _googleTranslateUrl = 'https://translate.googleapis.com/translate_a/single';
  
  /// Détecte la langue d'un texte (méthode publique pour utilisation externe)
  Future<String?> detectLanguage(String text) async {
    return _detectLanguage(text);
  }
  
  /// Détecte la langue d'un texte (méthode interne)
  Future<String?> _detectLanguage(String text) async {
    if (text.isEmpty) return null;
    
    // D'abord, essayer la détection simple (plus rapide et fiable pour l'anglais/français)
    final simpleDetection = _simpleLanguageDetection(text);
    if (simpleDetection != null) {
      return simpleDetection;
    }
    
    try {
      // Utiliser LibreTranslate pour détecter la langue si la détection simple échoue
      final response = await http.post(
        Uri.parse('https://libretranslate.com/detect'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'q': text.substring(0, text.length > 500 ? 500 : text.length)}),
      ).timeout(const Duration(seconds: 5));
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is List && data.isNotEmpty) {
          final detectedLang = data[0]['language'] as String?;
          return detectedLang;
        }
      }
    } catch (e) {
      // Erreur silencieuse
    }
    
    // Dernier recours: retourner la détection simple même si incertaine
    return simpleDetection;
  }
  
  /// Détection simple basée sur les mots et caractères
  String? _simpleLanguageDetection(String text) {
    if (text.isEmpty) return null;
    
    final lowerText = text.toLowerCase();
    final words = lowerText.split(RegExp(r'[\s\p{P}]+')).where((w) => w.isNotEmpty).toList();
    
    // Mots anglais communs
    const englishCommonWords = {
      'the', 'and', 'or', 'is', 'are', 'was', 'were', 'in', 'on', 'at', 'to', 'for', 'of', 'with', 'by',
      'after', 'before', 'years', 'year', 'mutated', 'beasts', 'beast', 'ravaged', 'world', 'humanity',
      'began', 'lose', 'ground', 'only', 'martial', 'this', 'that', 'these', 'those', 'a', 'an'
    };
    
    // Mots français communs
    const frenchCommonWords = {
      'le', 'la', 'les', 'un', 'une', 'des', 'est', 'sont', 'était', 'étaient', 'dans', 'sur', 'pour',
      'avec', 'après', 'avant', 'années', 'année', 'muté', 'bêtes', 'bête', 'ravagé', 'monde', 'humanité',
      'commencé', 'perdre', 'terrain', 'seulement', 'martial', 'ce', 'cette', 'ces', 'de', 'du'
    };
    
    // PRIORITÉ 1: Vérifier le début du texte (les premiers mots sont souvent révélateurs)
    final firstWords = words.take(20).toSet();
    final hasEnglishStart = firstWords.intersection(englishCommonWords).isNotEmpty;
    final hasFrenchStart = firstWords.intersection(frenchCommonWords).isNotEmpty;
    
    // Si le début contient des mots anglais et pas de mots français, c'est très probablement de l'anglais
    if (hasEnglishStart && !hasFrenchStart) {
      return 'en';
    }
    
    // PRIORITÉ 2: Compter les occurrences de mots anglais vs français dans tout le texte
    int englishMatches = 0;
    int frenchMatches = 0;
    
    for (final word in words) {
      if (englishCommonWords.contains(word)) {
        englishMatches++;
      }
      if (frenchCommonWords.contains(word)) {
        frenchMatches++;
      }
    }
    
    // Si beaucoup plus de mots anglais que français, c'est de l'anglais
    if (englishMatches >= 3 && englishMatches > frenchMatches) {
      return 'en';
    }
    
    // Si beaucoup plus de mots français que anglais, c'est du français
    if (frenchMatches >= 3 && frenchMatches > englishMatches * 2) {
      return 'fr';
    }
    
    // PRIORITÉ 3: Vérifier les caractères spéciaux français
    final hasFrenchChars = text.contains('à') || text.contains('â') || text.contains('ä') ||
                          text.contains('é') || text.contains('è') || text.contains('ê') ||
                          text.contains('ë') || text.contains('ï') || text.contains('î') ||
                          text.contains('ô') || text.contains('ù') || text.contains('û') ||
                          text.contains('ü') || text.contains('ÿ') || text.contains('ç');
    
    // Si on trouve des caractères français et peu de mots anglais, c'est du français
    if (hasFrenchChars && englishMatches < 2) {
      return 'fr';
    }
    
    // Si on trouve des patterns anglais typiques sans caractères français, c'est de l'anglais
    if (hasEnglishStart && !hasFrenchChars && englishMatches >= 2) {
      return 'en';
    }
    
    // Dernier recours: si le texte commence par des mots anglais typiques sans mots français
    if (hasEnglishStart && !hasFrenchStart) {
      return 'en';
    }
    
    return null;
  }
  
  /// Traduit un texte vers la langue cible
  Future<String?> translateText(String text, String targetLanguage) async {
    if (text.isEmpty) {
      return text;
    }
    
    // Vérifier le cache
    final cached = await _getCachedTranslation(text, targetLanguage);
    if (cached != null) {
      return cached;
    }
    
    // Mapper les codes de langue (on essaie avec 'auto' pour la source)
    final targetCode = _mapLanguageCode(targetLanguage);
    
    // Limite de caractères pour LibreTranslate (5000 caractères)
    const maxChunkSize = 4000; // Utiliser 4000 pour être sûr avec LibreTranslate
    String? translated;
    
    // Google Translate peut gérer de longs textes directement, l'utiliser en priorité
    translated = await _translateWithGoogleTranslate(text, targetCode);
    
    // Si Google Translate échoue, essayer LibreTranslate (mais nécessite une clé API maintenant)
    if (translated == null) {
      if (text.length <= maxChunkSize) {
        translated = await _translateWithLibreTranslate(text, 'auto', targetCode);
      } else {
        translated = await _translateLongText(text, targetCode);
      }
    }
    
    // Si toujours échec, utiliser MyMemory par chunks (dernier recours)
    if (translated == null) {
      translated = await _translateLongTextWithMyMemory(text, targetCode);
    }
    
    // Mettre en cache le résultat (même si null)
    if (translated != null && translated != text) {
      await _cacheTranslation(text, targetLanguage, translated);
      return translated;
    }
    
    // Si toutes les traductions échouent, retourner le texte original
    return text;
  }
  
  /// Traduit un texte long avec MyMemory (limite 500 caractères par chunk)
  Future<String?> _translateLongTextWithMyMemory(String text, String targetCode) async {
    const chunkSize = 450; // Utiliser 450 pour être sûr avec MyMemory (limite 500)
    final chunks = <String>[];
    
    // Découper le texte en chunks
    int start = 0;
    while (start < text.length) {
      int end = start + chunkSize;
      
      if (end >= text.length) {
        chunks.add(text.substring(start));
        break;
      }
      
      // Chercher un point, point d'exclamation ou point d'interrogation pour couper proprement
      final lastPeriod = text.lastIndexOf('.', end);
      final lastExclamation = text.lastIndexOf('!', end);
      final lastQuestion = text.lastIndexOf('?', end);
      final lastNewline = text.lastIndexOf('\n', end);
      final lastSpace = text.lastIndexOf(' ', end);
      
      final cutPoint = [
        if (lastPeriod > start) lastPeriod + 1,
        if (lastExclamation > start) lastExclamation + 1,
        if (lastQuestion > start) lastQuestion + 1,
        if (lastNewline > start) lastNewline + 1,
        if (lastSpace > start) lastSpace + 1,
        end
      ].reduce((a, b) => a > b ? a : b);
      
      chunks.add(text.substring(start, cutPoint));
      start = cutPoint;
    }
    
    // Traduire chaque chunk avec MyMemory
    final translatedChunks = <String>[];
    for (int i = 0; i < chunks.length; i++) {
      String? translatedChunk = await _translateWithMyMemory(chunks[i], 'en', targetCode);
      
      if (translatedChunk != null) {
        translatedChunks.add(translatedChunk);
      } else {
        // Si la traduction échoue, garder le chunk original
        translatedChunks.add(chunks[i]);
      }
      
      // Pause entre les chunks pour éviter de surcharger l'API (rate limiting)
      if (i < chunks.length - 1) {
        await Future.delayed(const Duration(seconds: 2)); // Augmenter à 2 secondes pour éviter 429
      }
    }
    
    // Recombiner tous les chunks traduits
    return translatedChunks.join(' ');
  }
  
  /// Traduit un texte long en le découpant en chunks
  Future<String?> _translateLongText(String text, String targetCode) async {
    const chunkSize = 4000;
    final chunks = <String>[];
    
    // Découper le texte en chunks en respectant les limites de phrases
    int start = 0;
    while (start < text.length) {
      int end = start + chunkSize;
      
      if (end >= text.length) {
        // Dernier chunk
        chunks.add(text.substring(start));
        break;
      }
      
      // Chercher un point, point d'exclamation ou point d'interrogation pour couper proprement
      final lastPeriod = text.lastIndexOf('.', end);
      final lastExclamation = text.lastIndexOf('!', end);
      final lastQuestion = text.lastIndexOf('?', end);
      final lastNewline = text.lastIndexOf('\n', end);
      
      final cutPoint = [
        if (lastPeriod > start) lastPeriod + 1,
        if (lastExclamation > start) lastExclamation + 1,
        if (lastQuestion > start) lastQuestion + 1,
        if (lastNewline > start) lastNewline + 1,
        end
      ].reduce((a, b) => a > b ? a : b);
      
      chunks.add(text.substring(start, cutPoint));
      start = cutPoint;
    }
    
    // Traduire chaque chunk
    final translatedChunks = <String>[];
    for (int i = 0; i < chunks.length; i++) {
      String? translatedChunk = await _translateWithLibreTranslate(chunks[i], 'auto', targetCode);
      
      if (translatedChunk == null) {
        // Si LibreTranslate échoue, essayer MyMemory mais seulement pour les petits chunks
        if (chunks[i].length <= 450) {
          translatedChunk = await _translateWithMyMemory(chunks[i], 'en', targetCode);
        } else {
          // Découper le chunk en sous-chunks pour MyMemory
          final subChunks = <String>[];
          int subStart = 0;
          while (subStart < chunks[i].length) {
            int subEnd = subStart + 450;
            if (subEnd >= chunks[i].length) {
              subChunks.add(chunks[i].substring(subStart));
              break;
            }
            final lastSpace = chunks[i].lastIndexOf(' ', subEnd);
            final cutPoint = lastSpace > subStart ? lastSpace + 1 : subEnd;
            subChunks.add(chunks[i].substring(subStart, cutPoint));
            subStart = cutPoint;
          }
          
          final subTranslated = <String>[];
          for (final subChunk in subChunks) {
            final subTrans = await _translateWithMyMemory(subChunk, 'en', targetCode);
            subTranslated.add(subTrans ?? subChunk);
            await Future.delayed(const Duration(milliseconds: 300));
          }
          translatedChunk = subTranslated.join(' ');
        }
      }
      
      if (translatedChunk != null) {
        translatedChunks.add(translatedChunk);
      } else {
        // Si la traduction échoue, garder le chunk original
        translatedChunks.add(chunks[i]);
      }
      
      // Pause entre les chunks pour éviter de surcharger l'API (rate limiting)
      if (i < chunks.length - 1) {
        await Future.delayed(const Duration(seconds: 2)); // Augmenter à 2 secondes pour éviter 429
      }
    }
    
    // Recombiner tous les chunks traduits
    return translatedChunks.join(' ');
  }
  
  /// Traduit avec LibreTranslate
  Future<String?> _translateWithLibreTranslate(String text, String source, String target) async {
    try {
      final response = await http.post(
        Uri.parse(_libreTranslateUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'q': text,
          'source': source,
          'target': target,
          'format': 'text',
        }),
      ).timeout(const Duration(seconds: 15));
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final translated = data['translatedText'] as String?;
        if (translated != null) {
          return translated;
        }
      }
    } catch (e) {
      // Erreur silencieuse
    }
    return null;
  }
  
  /// Traduit avec MyMemory
  Future<String?> _translateWithMyMemory(String text, String source, String target) async {
    try {
      // MyMemory limite à 500 caractères
      final textToTranslate = text.length > 500 ? text.substring(0, 500) : text;
      
      final response = await http.get(
        Uri.parse('$_myMemoryUrl?q=${Uri.encodeComponent(textToTranslate)}&langpair=$source|$target'),
      ).timeout(const Duration(seconds: 15));
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['responseStatus'] == 200) {
          final translated = data['responseData']?['translatedText'] as String?;
          return translated;
        } else {
          if (data['responseStatus'] == 429) {
            await Future.delayed(const Duration(seconds: 5));
            // Réessayer une fois
            return await _translateWithMyMemory(text, source, target);
          }
        }
      } else if (response.statusCode == 429) {
        await Future.delayed(const Duration(seconds: 5));
        // Réessayer une fois
        return await _translateWithMyMemory(text, source, target);
      }
    } catch (e) {
      // Erreur silencieuse
    }
    return null;
  }
  
  /// Traduit avec Google Translate (non officiel mais gratuit, peut gérer de longs textes)
  Future<String?> _translateWithGoogleTranslate(String text, String targetCode) async {
    try {
      // Google Translate non officiel peut gérer de longs textes
      final url = Uri.parse('$_googleTranslateUrl?client=gtx&sl=auto&tl=$targetCode&dt=t&q=${Uri.encodeComponent(text)}');
      final response = await http.get(url).timeout(const Duration(seconds: 20));
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is List && data.isNotEmpty && data[0] is List) {
          final translatedParts = <String>[];
          for (final part in data[0] as List) {
            if (part is List && part.isNotEmpty && part[0] is String) {
              translatedParts.add(part[0] as String);
            }
          }
          final translated = translatedParts.join('');
          if (translated.isNotEmpty && translated != text) {
            return translated;
          }
        }
      }
    } catch (e) {
      // Erreur silencieuse
    }
    return null;
  }
  
  
  /// Mappe les codes de langue vers les codes supportés par les APIs
  String _mapLanguageCode(String language) {
    final langMap = {
      'fr': 'fr',
      'en': 'en',
      'de': 'de',
      'es': 'es',
      'pt': 'pt',
      'ja': 'ja',
      'ko': 'ko',
      'french': 'fr',
      'english': 'en',
      'german': 'de',
      'spanish': 'es',
      'portuguese': 'pt',
      'japanese': 'ja',
      'korean': 'ko',
    };
    
    return langMap[language.toLowerCase()] ?? 'en';
  }
  
  /// Supprime le cache d'une traduction spécifique
  Future<void> clearCachedTranslation(String text, String targetLanguage) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheKey = '${_cachePrefix}${_hashText(text)}_$targetLanguage';
      await prefs.remove(cacheKey);
    } catch (e) {
      // Erreur silencieuse
    }
  }
  
  /// Récupère une traduction de changelog depuis le cache (par version et note)
  Future<String?> getCachedChangelogTranslation(String version, String note, String targetLanguage) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheKey = '${_cachePrefix}changelog_${version}_${_hashText(note)}_$targetLanguage';
      final cachedData = prefs.getString(cacheKey);
      
      if (cachedData != null) {
        final data = jsonDecode(cachedData) as Map<String, dynamic>;
        final timestamp = DateTime.parse(data['timestamp'] as String);
        final cachedText = data['text'] as String;
        
        if (DateTime.now().difference(timestamp) < _cacheDuration) {
          return cachedText;
        } else {
          await prefs.remove(cacheKey);
        }
      }
    } catch (e) {
      // Erreur silencieuse
    }
    return null;
  }
  
  /// Met en cache une traduction de changelog (par version et note)
  Future<void> cacheChangelogTranslation(String version, String note, String targetLanguage, String translated) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheKey = '${_cachePrefix}changelog_${version}_${_hashText(note)}_$targetLanguage';
      final data = jsonEncode({
        'text': translated,
        'timestamp': DateTime.now().toIso8601String(),
      });
      await prefs.setString(cacheKey, data);
    } catch (e) {
      // Erreur silencieuse
    }
  }
  
  /// Récupère une traduction depuis le cache
  Future<String?> _getCachedTranslation(String text, String targetLanguage) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheKey = '${_cachePrefix}${_hashText(text)}_$targetLanguage';
      final cachedData = prefs.getString(cacheKey);
      
      if (cachedData != null) {
        final data = jsonDecode(cachedData) as Map<String, dynamic>;
        final timestamp = DateTime.parse(data['timestamp'] as String);
        final cachedText = data['text'] as String;
        
        if (DateTime.now().difference(timestamp) < _cacheDuration) {
          return cachedText;
        } else {
          // Cache expiré, le supprimer
          await prefs.remove(cacheKey);
        }
      }
    } catch (e) {
      // Erreur silencieuse
    }
    return null;
  }
  
  /// Met en cache une traduction
  Future<void> _cacheTranslation(String originalText, String targetLanguage, String translatedText) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheKey = '${_cachePrefix}${_hashText(originalText)}_$targetLanguage';
      final data = jsonEncode({
        'text': translatedText,
        'timestamp': DateTime.now().toIso8601String(),
      });
      await prefs.setString(cacheKey, data);
    } catch (e) {
      // Erreur silencieuse
    }
  }
  
  /// Génère un hash simple pour le texte (pour la clé de cache)
  String _hashText(String text) {
    return text.hashCode.toString();
  }
  
  /// Nettoie le cache des traductions expirées
  Future<void> cleanExpiredCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys().where((key) => key.startsWith(_cachePrefix));
      
      for (final key in keys) {
        final cachedData = prefs.getString(key);
        if (cachedData != null) {
          try {
            final data = jsonDecode(cachedData) as Map<String, dynamic>;
            final timestamp = DateTime.parse(data['timestamp'] as String);
            
            if (DateTime.now().difference(timestamp) >= _cacheDuration) {
              await prefs.remove(key);
            }
          } catch (e) {
            // Données corrompues, supprimer
            await prefs.remove(key);
          }
        }
      }
    } catch (e) {
      // Erreur silencieuse
    }
  }
}

