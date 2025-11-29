import 'package:path/path.dart' as path;

/// Statut d'un téléchargement de chapitre
enum DownloadStatus {
  downloading,
  completed,
  failed,
  paused,
}

/// Modèle représentant un chapitre téléchargé
class DownloadedChapter {
  final int muId;
  final int chapterNumber;
  final DateTime downloadDate;
  final int imageCount;
  final List<String> imagePaths;
  final String? htmlPath; // Chemin vers le fichier HTML téléchargé
  final DownloadStatus status;
  final String? errorMessage;
  final double? scrollPosition; // Position de scroll sauvegardée (en pixels)
  final double? zoomLevel; // Niveau de zoom préféré (par défaut ~1.28)

  const DownloadedChapter({
    required this.muId,
    required this.chapterNumber,
    required this.downloadDate,
    required this.imageCount,
    required this.imagePaths,
    this.htmlPath,
    this.status = DownloadStatus.completed,
    this.errorMessage,
    this.scrollPosition,
    this.zoomLevel,
  });

  /// Chemin du dossier contenant les images du chapitre
  String get folderPath {
    if (htmlPath != null) {
      return path.dirname(htmlPath!);
    }
    return imagePaths.isNotEmpty ? path.dirname(imagePaths.first) : '';
  }

  /// Chemin du fichier de métadonnées
  String get metadataPath {
    return path.join(folderPath, 'metadata.json');
  }

  Map<String, dynamic> toJson() {
    return {
      'muId': muId,
      'chapterNumber': chapterNumber,
      'downloadDate': downloadDate.toIso8601String(),
      'imageCount': imageCount,
      'imagePaths': imagePaths,
      'htmlPath': htmlPath,
      'status': status.name,
      'errorMessage': errorMessage,
      'scrollPosition': scrollPosition,
      'zoomLevel': zoomLevel,
    };
  }

  factory DownloadedChapter.fromJson(Map<String, dynamic> json) {
    return DownloadedChapter(
      muId: json['muId'] as int,
      chapterNumber: json['chapterNumber'] as int,
      downloadDate: DateTime.parse(json['downloadDate'] as String),
      imageCount: json['imageCount'] as int,
      imagePaths: (json['imagePaths'] as List).cast<String>(),
      htmlPath: json['htmlPath'] as String?,
      status: DownloadStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => DownloadStatus.completed,
      ),
      errorMessage: json['errorMessage'] as String?,
      scrollPosition: json['scrollPosition'] as double?,
      zoomLevel: json['zoomLevel'] as double?,
    );
  }

  DownloadedChapter copyWith({
    int? muId,
    int? chapterNumber,
    DateTime? downloadDate,
    int? imageCount,
    List<String>? imagePaths,
    String? htmlPath,
    DownloadStatus? status,
    String? errorMessage,
    double? scrollPosition,
    double? zoomLevel,
  }) {
    return DownloadedChapter(
      muId: muId ?? this.muId,
      chapterNumber: chapterNumber ?? this.chapterNumber,
      downloadDate: downloadDate ?? this.downloadDate,
      imageCount: imageCount ?? this.imageCount,
      imagePaths: imagePaths ?? this.imagePaths,
      htmlPath: htmlPath ?? this.htmlPath,
      status: status ?? this.status,
      errorMessage: errorMessage ?? this.errorMessage,
      scrollPosition: scrollPosition ?? this.scrollPosition,
      zoomLevel: zoomLevel ?? this.zoomLevel,
    );
  }
}

