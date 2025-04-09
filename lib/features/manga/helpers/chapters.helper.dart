class ChaptersHelper {
  static List<dynamic> buildChapterList(num? totalNumberOfChapters) {
    totalNumberOfChapters ??= 0;

    return [
      ['01', '144', true],
      ['02', '145', true],
      ['03', '146', true],
      ['04', '147', true],
      ['05', '148', true],
      ['06', '149', false],
      ['07', '150', false],
      ['08', '151', false],
      ['09', '152', false],
      ['10', '153', false],
      ['11', '154', false],
      ['12', '155', false],
    ];
  }
}
