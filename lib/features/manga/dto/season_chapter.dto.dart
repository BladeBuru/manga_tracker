class SeasonChapter {
  final String season;
  final int chapters;

  const SeasonChapter({required this.season, required this.chapters});

  factory SeasonChapter.fromJson(Map<String, dynamic> json) {
    return SeasonChapter(
      season: json['season'],
      chapters: json['chapters'],
    );
  }
}
