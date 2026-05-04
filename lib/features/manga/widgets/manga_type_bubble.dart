import 'package:flutter/material.dart';
import 'package:mangatracker/core/theme/app_radius.dart';

class MangaType extends StatelessWidget {
  final String type;

  const MangaType({
    super.key,
    required this.type,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 5),
      child: Container(
        height: 10,
        decoration: BoxDecoration(
          borderRadius: AppRadius.circularLg,
          color: Colors.white,
        ),
        child: Padding(
          padding: const EdgeInsets.only(top: 3, bottom: 4, right: 5, left: 5),
          child: Text(
            type,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 12.0,
              color: Colors.black,
            ),
          ),
        ),
      ),
    );
  }
}
