import '../dto/season_chapter.dto.dart';

/// Helper pour calculer les sections de chapitres
class ChapterSection {
  final String title;
  final int startChapter;
  final int endChapter;
  final List<int> chapterNumbers;

  const ChapterSection({
    required this.title,
    required this.startChapter,
    required this.endChapter,
    required this.chapterNumbers,
  });
}

class ChapterSectionHelper {
  /// Calcule les sections de chapitres en fonction des saisons ou crée des sections de 100
  static List<ChapterSection> calculateSections({
    required int totalChapters,
    List<SeasonChapter>? seasonChapters,
    List<SeasonChapter>? bonusChapters,
  }) {
    final sections = <ChapterSection>[];

    // Cas 1: Avec saisons
    if (seasonChapters != null && seasonChapters.isNotEmpty) {
      int currentChapter = 1;
      
      for (int i = 0; i < seasonChapters.length; i++) {
        final season = seasonChapters[i];
        int chapterCount = season.chapters;
        
        // Pour la dernière saison principale, vérifier s'il manque des chapitres
        // (les bonus chapters ne sont pas inclus dans totalChapters)
        if (i == seasonChapters.length - 1) {
          // Calculer le total des saisons jusqu'à maintenant (y compris celle-ci)
          final totalFromSeasons = seasonChapters.fold<int>(
            0,
            (sum, s) => sum + s.chapters,
          );
          
          // Si le total des saisons est inférieur au total réel, ajouter les chapitres manquants à la dernière saison
          if (totalFromSeasons < totalChapters) {
            final missingChapters = totalChapters - totalFromSeasons;
            chapterCount += missingChapters;
          }
        }
        
        final endChapter = currentChapter + chapterCount - 1;
        final chapterNumbers = List.generate(
          chapterCount,
          (index) => currentChapter + index,
        ).reversed.toList(); // Ordre décroissant
        
        sections.add(ChapterSection(
          title: season.season,
          startChapter: currentChapter,
          endChapter: endChapter,
          chapterNumbers: chapterNumbers,
        ));
        
        currentChapter += chapterCount;
      }
      
      // Ajouter les bonus chapters (séparés des saisons principales)
      // Les bonus chapters sont numérotés à partir de totalChapters + 1
      if (bonusChapters != null && bonusChapters.isNotEmpty) {
        int bonusStartChapter = totalChapters + 1;
        
        for (final bonus in bonusChapters) {
          final bonusEndChapter = bonusStartChapter + bonus.chapters - 1;
          final chapterNumbers = List.generate(
            bonus.chapters,
            (index) => bonusStartChapter + index,
          ).reversed.toList();
          
          sections.add(ChapterSection(
            title: bonus.season,
            startChapter: bonusStartChapter,
            endChapter: bonusEndChapter,
            chapterNumbers: chapterNumbers,
          ));
          
          bonusStartChapter += bonus.chapters;
        }
      }
    }
    // Cas 2: Sans saisons mais >= 100 chapitres -> sections de 100
    else if (totalChapters >= 100) {
      for (int i = 0; i < totalChapters; i += 100) {
        final startChapter = i + 1;
        final endChapter = (i + 100 > totalChapters) ? totalChapters : i + 100;
        final chapterCount = endChapter - startChapter + 1;
        
        final chapterNumbers = List.generate(
          chapterCount,
          (index) => startChapter + index,
        ).reversed.toList();
        
        sections.add(ChapterSection(
          title: 'Chapitres $startChapter-$endChapter',
          startChapter: startChapter,
          endChapter: endChapter,
          chapterNumbers: chapterNumbers,
        ));
      }
    }
    // Cas 3: Sans saisons et < 100 chapitres -> pas de sections (affichage linéaire)
    
    return sections;
  }
  
  /// Trouve la section contenant un chapitre donné
  static String? findSectionForChapter(
    int chapterNumber,
    List<ChapterSection> sections,
  ) {
    for (final section in sections) {
      if (chapterNumber >= section.startChapter && 
          chapterNumber <= section.endChapter) {
        return section.title;
      }
    }
    return null;
  }
}

