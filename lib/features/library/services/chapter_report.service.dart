import 'dart:convert';

import 'package:mangatracker/core/network/http_service.dart';
import 'package:mangatracker/core/network/network_compat.dart';
import 'package:mangatracker/core/network/uri_builder.dart';
import 'package:mangatracker/core/service_locator/service_locator.dart';

/// Résultat du signalement (réponse 201 de l'API).
class ChapterReportResult {
  final int reportedTotal;
  final int effectiveTotalChapters;
  final bool consolidated;

  const ChapterReportResult({
    required this.reportedTotal,
    required this.effectiveTotalChapters,
    required this.consolidated,
  });

  factory ChapterReportResult.fromJson(Map<String, dynamic> json) {
    return ChapterReportResult(
      reportedTotal: int.tryParse(json['reportedTotal'].toString()) ?? 0,
      effectiveTotalChapters:
          int.tryParse(json['effectiveTotalChapters'].toString()) ?? 0,
      consolidated: json['consolidated'] as bool? ?? false,
    );
  }
}

/// Causes d'échec typées du signalement.
enum ChapterReportFailure {
  /// 400 — bornes : le total doit être > total actuel et ≤ total + 200.
  invalidTotal,

  /// 404 — le manga n'est pas dans la bibliothèque de l'utilisateur.
  notInLibrary,

  /// 429 — throttle serveur (10 signalements / heure).
  throttled,

  /// Tout autre code HTTP inattendu.
  unknown,
}

class ChapterReportException implements Exception {
  final ChapterReportFailure failure;
  final int statusCode;

  const ChapterReportException(this.failure, this.statusCode);

  @override
  String toString() => 'ChapterReportException($failure, HTTP $statusCode)';
}

/// Service « Signaler plus de chapitres » (chantier A).
///
/// PAS de queue offline : le CTA est désactivé hors ligne (un signalement
/// rejoué plus tard pourrait dépasser les bornes serveur entre-temps).
class ChapterReportService {
  final HttpService _http;

  ChapterReportService({HttpService? httpService})
      : _http = httpService ?? getIt<HttpService>();

  /// POST /library/:muId/report-chapters — 201 attendu.
  ///
  /// Lève [ChapterReportException] typée sur 400 (bornes), 404 (hors
  /// bibliothèque), 429 (throttle) ; les erreurs réseau (SocketException…)
  /// remontent telles quelles au caller.
  Future<ChapterReportResult> reportMoreChapters(
      int muId, int reportedTotal) async {
    final res = await _http.postWithAuthTokens(
      buildApiUri('/library/$muId/report-chapters'),
      headers: {HttpHeaders.contentTypeHeader: 'application/json'},
      body: jsonEncode({'reportedTotal': reportedTotal}),
    );

    switch (res.statusCode) {
      case HttpStatus.created:
        return ChapterReportResult.fromJson(
          jsonDecode(res.body) as Map<String, dynamic>,
        );
      case HttpStatus.badRequest:
        throw const ChapterReportException(
            ChapterReportFailure.invalidTotal, HttpStatus.badRequest);
      case HttpStatus.notFound:
        throw const ChapterReportException(
            ChapterReportFailure.notInLibrary, HttpStatus.notFound);
      case HttpStatus.tooManyRequests:
        throw const ChapterReportException(
            ChapterReportFailure.throttled, HttpStatus.tooManyRequests);
      default:
        throw ChapterReportException(
            ChapterReportFailure.unknown, res.statusCode);
    }
  }
}
