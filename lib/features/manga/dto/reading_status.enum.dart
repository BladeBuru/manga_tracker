enum ReadingStatus {
  reading,
  readLater,
  caughtUp,
  completed,
}

extension ReadingStatusExtension on ReadingStatus {
  String get label {
    switch (this) {
      case ReadingStatus.reading:
        return 'En cours';
      case ReadingStatus.readLater:
        return 'À lire plus tard';
      case ReadingStatus.caughtUp:
        return 'À jour';
      case ReadingStatus.completed:
        return 'Terminé';
    }
  }

  String get value => toString().split('.').last;

  String get display {
    switch (this) {
      case ReadingStatus.reading:
        return '📖 En cours';
      case ReadingStatus.readLater:
        return '📥 À lire plus tard';
      case ReadingStatus.caughtUp:
        return '✅ À jour';
      case ReadingStatus.completed:
        return '🏁 Terminé';
    }
  }

  static ReadingStatus fromValue(String value) {
    return ReadingStatus.values.firstWhere(
          (e) => e.value == value,
      orElse: () => ReadingStatus.readLater,
    );
  }
}
