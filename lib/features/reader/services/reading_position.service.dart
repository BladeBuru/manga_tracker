import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:mangatracker/core/network/http_service.dart';
import 'package:mangatracker/core/network/network_compat.dart';
import 'package:mangatracker/core/network/uri_builder.dart';
import 'package:mangatracker/core/service_locator/service_locator.dart';
import 'package:mangatracker/features/reader/dto/reading_position.dto.dart';
import 'package:mangatracker/features/reader/utils/reading_position_calculator.dart';

/// Synchronisation serveur de la position de lecture — le « marque-page »
/// qui suit l'utilisateur d'un appareil à l'autre.
///
/// ## Ce service ne doit JAMAIS gêner la lecture
///
/// Il envoie un pourcentage de progression pendant que l'utilisateur lit :
/// aucun de ses échecs ne doit remonter jusqu'à lui. Toutes les méthodes
/// **avalent** leurs erreurs, n'affichent rien, ne relancent rien. Perdre une
/// position, c'est rouvrir un chapitre quelques écrans trop haut ; faire
/// échouer la lecture pour ça n'aurait aucun sens.
///
/// ## Débit
///
/// Le lecteur mesure sa position toutes les 5 s. L'envoyer à chaque mesure
/// ferait 12 requêtes par minute et par manga, pour un plafond serveur de
/// 60/min/utilisateur : deux mangas ouverts en parallèle suffiraient à
/// déclencher des 429. On limite donc à **un envoi toutes les
/// [defaultThrottle] par manga**, complété par un envoi **immédiat** aux deux
/// seuls moments qui comptent vraiment : la sortie du lecteur et le passage
/// en arrière-plan ([flush]).
///
/// ## Hors ligne
///
/// Aucune mise en file d'attente façon `SyncService` : une position n'est pas
/// une action à rejouer, seule la **dernière** compte. Le service garde donc
/// exactement une position en attente **par manga** ([_pending]), écrasée à
/// chaque mesure. Vingt minutes de lecture dans le métro produisent une seule
/// requête au retour du réseau, pas deux cents.
class ReadingPositionService {
  ReadingPositionService({
    HttpService? httpService,
    Duration throttle = defaultThrottle,
    DateTime Function()? clock,
  })  : _httpOverride = httpService,
        _throttle = throttle,
        _now = clock ?? DateTime.now;

  /// Intervalle minimal entre deux envois pour un même manga.
  static const Duration defaultThrottle = Duration(seconds: 10);

  final HttpService? _httpOverride;
  final Duration _throttle;
  final DateTime Function() _now;

  /// Résolu à l'appel, jamais à la construction : le service est enregistré en
  /// `registerLazySingleton` sans `dependsOn` (cf. régression d'écran blanc
  /// v0.12.1 sur un `dependsOn` prématuré).
  HttpService get _http => _httpOverride ?? getIt<HttpService>();

  /// Dernière position mesurée et pas encore confirmée par le serveur, par
  /// manga. Une seule entrée par manga : la position d'il y a dix minutes
  /// n'intéresse personne.
  final Map<int, ReadingPositionDto> _pending = {};

  /// Dernière position **acceptée** par le serveur, par manga : évite de
  /// réenvoyer à l'identique quand l'utilisateur ne bouge plus (lecture en
  /// pause, page laissée ouverte).
  final Map<int, ReadingPositionDto> _confirmed = {};

  /// Horodatage du dernier envoi tenté, par manga — base du throttle.
  final Map<int, DateTime> _lastSentAt = {};

  /// Mangas dont une requête est en vol : deux PUT concurrents pour le même
  /// manga pourraient arriver dans le désordre et réécrire une position
  /// périmée.
  final Set<int> _inFlight = {};

  /// Enregistre une position de lecture, sous throttle.
  ///
  /// Ne fait rien de bloquant : l'appelant peut l'attendre ou non, elle ne
  /// lève jamais. Si l'envoi n'est pas encore permis, la position est
  /// simplement mémorisée — le prochain tick du lecteur ou le [flush] de
  /// sortie l'emportera.
  Future<void> savePosition(int muId, int chapter, double positionPercent) {
    final sample = _normalize(muId, chapter, positionPercent);
    if (sample == null) return Future<void>.value();

    _pending[muId] = sample;

    final last = _lastSentAt[muId];
    if (last != null && _now().difference(last) < _throttle) {
      return Future<void>.value(); // trop tôt : on garde pour plus tard
    }
    return _send(muId);
  }

  /// Envoi immédiat de la position en attente, throttle ignoré.
  ///
  /// À appeler à la sortie du lecteur et au passage en arrière-plan : ce sont
  /// les deux instants où l'utilisateur risque de basculer sur un autre
  /// appareil, donc les seuls où le retard se voit.
  Future<void> flush(int muId) {
    if (!_pending.containsKey(muId)) return Future<void>.value();
    return _send(muId);
  }

  /// Oublie toute position en attente pour [muId].
  ///
  /// Appelée quand un chapitre vient d'être validé comme terminé : sans ça, le
  /// tick suivant réenverrait une position au milieu d'un chapitre que le
  /// serveur vient justement de clore, et la lecture reprendrait au milieu
  /// d'un chapitre déjà lu.
  void forget(int muId) {
    _pending.remove(muId);
    _confirmed.remove(muId);
    _lastSentAt.remove(muId);
  }

  /// Position en cours côté serveur, ou `null` : `204` (aucune position),
  /// réponse inattendue, corps illisible, ou serveur injoignable. Ne lève
  /// jamais — l'appelant ouvre alors le chapitre suivant, comme avant.
  Future<ReadingPositionDto?> fetchPosition(int muId) async {
    try {
      final res = await _http.getWithAuthTokens(
        buildApiUri('/library/$muId/reading-position'),
      );
      if (res.statusCode == HttpStatus.noContent) return null;
      if (res.statusCode != HttpStatus.ok) return null;
      if (res.body.trim().isEmpty) return null;

      final decoded = jsonDecode(res.body);
      if (decoded is! Map<String, dynamic>) return null;
      return ReadingPositionDto.fromJson(decoded);
    } catch (e) {
      debugPrint('ReadingPositionService: position distante illisible ($e)');
      return null;
    }
  }

  /// Position en attente d'envoi pour [muId] — exposée pour que la reprise
  /// puisse préférer une mesure toute fraîche à ce que le serveur connaît.
  ReadingPositionDto? pendingFor(int muId) => _pending[muId];

  Future<void> _send(int muId) async {
    final sample = _pending[muId];
    if (sample == null) return;
    if (_inFlight.contains(muId)) return;

    // Rien n'a bougé depuis le dernier envoi accepté : ne pas consommer le
    // quota serveur pour réécrire la même ligne.
    if (_confirmed[muId] == sample) {
      _pending.remove(muId);
      return;
    }

    _inFlight.add(muId);
    _lastSentAt[muId] = _now();
    try {
      final res = await _http.putWithAuthTokens(
        buildApiUri('/library/reading-position'),
        headers: {HttpHeaders.contentTypeHeader: 'application/json'},
        body: jsonEncode({
          'muId': muId,
          'chapter': sample.chapter,
          'positionPercent': sample.positionPercent,
        }),
      );
      _handleResponse(muId, sample, res.statusCode);
    } catch (e) {
      // Réseau coupé, session expirée, serveur muet : la position reste en
      // attente et repartira au prochain tick ou au prochain flush.
      debugPrint('ReadingPositionService: envoi différé ($e)');
    } finally {
      _inFlight.remove(muId);
    }
  }

  void _handleResponse(int muId, ReadingPositionDto sample, int statusCode) {
    switch (statusCode) {
      case HttpStatus.ok:
      case HttpStatus.noContent:
        // Seule la position réellement envoyée est retirée : si l'utilisateur
        // a défilé pendant la requête, la mesure plus récente reste en
        // attente.
        if (_pending[muId] == sample) _pending.remove(muId);
        _confirmed[muId] = sample;

      case HttpStatus.badRequest:
      case HttpStatus.notFound:
        // Hors bornes, ou manga absent de la bibliothèque : réessayer
        // produirait la même réponse indéfiniment.
        _pending.remove(muId);
        debugPrint('ReadingPositionService: position refusée ($statusCode), '
            'abandon pour le manga $muId');

      case HttpStatus.tooManyRequests:
        // Quota atteint : on garde la position et on laisse passer une
        // fenêtre de throttle complète avant de retenter.
        debugPrint('ReadingPositionService: quota atteint, nouvel essai '
            'dans ${_throttle.inSeconds} s');

      default:
        // 5xx et autres : on garde, ça repartira tout seul.
        debugPrint('ReadingPositionService: réponse $statusCode, position '
            'conservée pour un nouvel essai');
    }
  }

  /// Refuse en amont ce que le serveur refuserait (400) : un chapitre négatif
  /// ou un pourcentage hors bornes ne mérite pas un aller-retour réseau.
  ReadingPositionDto? _normalize(int muId, int chapter, double positionPercent) {
    if (muId <= 0 || chapter < 0) return null;
    if (!positionPercent.isFinite) return null;
    if (positionPercent < 0 || positionPercent > 100) return null;
    return ReadingPositionDto(
      chapter: chapter,
      positionPercent: ReadingPositionCalculator.round(positionPercent),
    );
  }

  /// Vide l'état en mémoire — déconnexion, changement de compte.
  ///
  /// Sans ça, la position de l'utilisateur précédent partirait sur le compte
  /// du suivant à la première requête réussie, sur un appareil partagé.
  void clear() {
    _pending.clear();
    _confirmed.clear();
    _lastSentAt.clear();
    _inFlight.clear();
  }
}
