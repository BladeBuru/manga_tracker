/// Politique d'enregistrement des chapitres lus — **classe pure**.
///
/// Aucun import Flutter, aucun GetIt, aucun accès réseau : toute la décision
/// « quel chapitre enregistrer, et faut-il demander à l'utilisateur ? » vit
/// ici et se teste directement
/// (`test/features/reader/chapter_commit_policy_test.dart`).
///
/// ## Sémantique (NON-NÉGOCIABLE)
///
/// « Chapitres lus » = **dernier chapitre TERMINÉ**.
///
/// - **Arriver sur un chapitre ne le marque JAMAIS comme lu.** C'était le bug
///   de la v0.8.0 (commit `cc586a0`) : le passage N → N+1 enregistrait N *et*
///   N+1, si bien que l'utilisateur voyait « progression du chapitre 134 »
///   alors qu'il venait tout juste de l'ouvrir — un chapitre d'avance en
///   permanence.
/// - Un chapitre n'est réputé terminé que si :
///   1. l'utilisateur l'a quitté vers son successeur immédiat
///      ([ChapterTransition.nextChapter]), ou
///   2. l'utilisateur l'affirme explicitement (modale de saut ou modale de
///      fin de lecture).
///
/// La vue applique la décision ; elle ne la prend pas.
library;

/// Transition de chapitre observée par le lecteur.
///
/// Reflet pur de `ChapterChangeType` (`webview_navigation_service.dart`), qui
/// dépend, lui, de la WebView. La conversion se fait dans la vue.
enum ChapterTransition {
  /// Premier chapitre identifié depuis l'URL.
  firstDetected,

  /// Passage naturel au chapitre suivant (N → N+1).
  nextChapter,

  /// Saut vers l'avant (N → M avec M > N+1).
  jumpForward,

  /// Retour en arrière (N → M avec M < N).
  jumpBackward,

  /// Même chapitre (rechargement, ancre, paramètre d'URL...).
  noChange,
}

/// Ce que le lecteur doit faire après une transition de chapitre.
class ChapterChangeDecision {
  const ChapterChangeDecision({
    this.commitChapter,
    this.askUserToCommitChapter,
    this.initializeChapter,
    this.releaseScrollOfChapter,
  });

  /// Décision « ne rien faire du tout ».
  static const ChapterChangeDecision none = ChapterChangeDecision();

  /// Chapitre à enregistrer immédiatement, sans rien demander : il est
  /// **terminé** (l'utilisateur l'a quitté vers son successeur immédiat).
  /// `null` = aucun enregistrement automatique.
  final int? commitChapter;

  /// Chapitre à proposer à l'enregistrement via une modale. La vue
  /// n'enregistre que si l'utilisateur répond « oui ».
  /// `null` = aucune question à poser.
  final int? askUserToCommitChapter;

  /// Chapitre d'arrivée qui devient le chapitre courant.
  /// `null` = le chapitre courant ne change pas.
  final int? initializeChapter;

  /// Chapitre quitté dont la position de défilement doit être sauvegardée
  /// puis effacée (on ne le relira pas là où on l'avait laissé).
  /// `null` = rien à faire côté défilement.
  final int? releaseScrollOfChapter;

  /// `true` si cette décision n'enregistre rien et ne propose rien.
  bool get commitsNothing =>
      commitChapter == null && askUserToCommitChapter == null;

  @override
  bool operator ==(Object other) =>
      other is ChapterChangeDecision &&
      other.commitChapter == commitChapter &&
      other.askUserToCommitChapter == askUserToCommitChapter &&
      other.initializeChapter == initializeChapter &&
      other.releaseScrollOfChapter == releaseScrollOfChapter;

  @override
  int get hashCode => Object.hash(
        commitChapter,
        askUserToCommitChapter,
        initializeChapter,
        releaseScrollOfChapter,
      );

  @override
  String toString() => 'ChapterChangeDecision(commit: $commitChapter, '
      'ask: $askUserToCommitChapter, init: $initializeChapter, '
      'releaseScroll: $releaseScrollOfChapter)';
}

/// Ce que le lecteur doit faire quand l'utilisateur le quitte.
class ReaderExitDecision {
  const ReaderExitDecision._(this.askUserToCommitChapter);

  /// Sortir sans rien demander ni rien enregistrer.
  static const ReaderExitDecision leaveSilently = ReaderExitDecision._(null);

  /// Demander « Avez-vous fini le chapitre N ? » avant de sortir.
  const ReaderExitDecision.askIfFinished(int chapter) : this._(chapter);

  /// Chapitre concerné par la question, `null` si aucune question.
  final int? askUserToCommitChapter;

  /// `true` si une modale doit s'afficher avant de quitter.
  bool get shouldAsk => askUserToCommitChapter != null;

  @override
  bool operator ==(Object other) =>
      other is ReaderExitDecision &&
      other.askUserToCommitChapter == askUserToCommitChapter;

  @override
  int get hashCode => askUserToCommitChapter.hashCode;

  @override
  String toString() =>
      'ReaderExitDecision(ask: ${askUserToCommitChapter ?? "aucune"})';
}

/// Décide quels chapitres sont enregistrés comme lus, et quand demander.
class ChapterCommitPolicy {
  const ChapterCommitPolicy();

  /// Décision consécutive à une transition détectée dans le lecteur.
  ///
  /// [newChapter] est le chapitre d'**arrivée** — il n'est jamais enregistré,
  /// quelle que soit la transition.
  ChapterChangeDecision onTransition({
    required ChapterTransition transition,
    required int newChapter,
    int? previousChapter,
  }) {
    switch (transition) {
      case ChapterTransition.firstDetected:
        // Ouvrir un chapitre ne prouve rien : on se contente de le suivre.
        return ChapterChangeDecision(initializeChapter: newChapter);

      case ChapterTransition.nextChapter:
        // Seule transition qui prouve une lecture terminée : l'utilisateur a
        // atteint le successeur immédiat, donc il a fini le précédent.
        // Le chapitre d'arrivée, lui, vient seulement d'être ouvert.
        return ChapterChangeDecision(
          commitChapter: previousChapter,
          initializeChapter: newChapter,
          releaseScrollOfChapter: previousChapter,
        );

      case ChapterTransition.jumpForward:
        // On a sauté des chapitres : rien n'est prouvé, on demande. La
        // question porte sur le chapitre QUITTÉ (cohérent avec le texte de la
        // modale « Vous passez du chapitre {prev} au {next}. Marquer {prev}
        // comme lu ? »).
        return ChapterChangeDecision(
          askUserToCommitChapter: previousChapter,
          initializeChapter: newChapter,
          releaseScrollOfChapter: previousChapter,
        );

      case ChapterTransition.jumpBackward:
        // Relecture d'un chapitre antérieur : aucun enregistrement.
        return ChapterChangeDecision(
          initializeChapter: newChapter,
          releaseScrollOfChapter: previousChapter,
        );

      case ChapterTransition.noChange:
        return ChapterChangeDecision.none;
    }
  }

  /// Décision quand l'utilisateur quitte le lecteur.
  ///
  /// On ne demande que si le chapitre courant n'est pas déjà enregistré ET
  /// que l'utilisateur est proche de la fin : sinon la question serait du
  /// bruit (il vient d'ouvrir le chapitre, ou il l'a déjà validé).
  ///
  /// [isNearEnd] `false` couvre aussi le cas « mesure impossible » : on
  /// préfère un faux négatif (pas de question) à un faux « chapitre fini ».
  ReaderExitDecision onExit({
    required int? currentChapter,
    required int lastCommitted,
    required bool isNearEnd,
  }) {
    final chapter = currentChapter;
    if (chapter == null) return ReaderExitDecision.leaveSilently;
    if (!shouldCommit(chapter, lastCommitted)) {
      return ReaderExitDecision.leaveSilently;
    }
    if (!isNearEnd) return ReaderExitDecision.leaveSilently;
    return ReaderExitDecision.askIfFinished(chapter);
  }

  /// Traduit la réponse d'une modale en chapitre à enregistrer.
  ///
  /// Seul un « oui » franc enregistre : `null` (modale fermée d'un geste) et
  /// « non » ne valident rien.
  int? resolveAnswer({required bool? answer, required int? chapter}) {
    if (answer != true) return null;
    return chapter;
  }

  /// Un chapitre n'est enregistré que s'il fait avancer la progression.
  ///
  /// Le pointeur de progression est monotone : il ne recule jamais, même si
  /// l'utilisateur relit un chapitre antérieur.
  bool shouldCommit(int chapter, int lastCommitted) => chapter > lastCommitted;
}
