import 'package:flutter/material.dart';
import 'detail_bloc_view.dart';

/// Wrapper pour utiliser DetailBlocView avec l'interface existante
class Detail extends StatelessWidget {
  final String muId;
  final String mangaTitle;
  final String? coverPath;

  const Detail({
    super.key,
    required this.muId,
    required this.mangaTitle,
    this.coverPath,
  });

  @override
  Widget build(BuildContext context) {
    return DetailBlocView(
      muId: int.parse(muId),
      mangaTitle: mangaTitle,
      coverPath: coverPath,
    );
  }
}