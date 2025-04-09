import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class RowChapter extends StatelessWidget {
  final String line;
  final String chapter;
  final bool lock;

  const RowChapter({
    super.key,
    required this.line,
    required this.chapter,
    required this.lock,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(
          top: 10.0, bottom: 10.0, right: 10.0, left: 10.0),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            SizedBox(
              height: 60,
              width: 80,
              child: Align(
                alignment: Alignment.center,
                child: Text(line,
                    style: GoogleFonts.poppins(
                      textStyle: const TextStyle(fontSize: 22),
                      fontWeight: FontWeight.w500,
                      fontStyle: FontStyle.normal,
                      color: Colors.grey,
                    )),
              ),
            ),
            Expanded(
              child: SizedBox(
                height: 60,
                child: Align(
                  alignment: Alignment.topLeft,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 20, left: 30),
                    child: Text('Chapter $chapter'),
                  ),
                ),
              ),
            ),
            SizedBox(
              height: 60,
              width: 50,
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: lock == true
                    ? Container(
                        height: 5,
                        width: 5,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Color.fromARGB(150, 224, 35, 79),
                        ),
                        child: const Icon(
                          Icons.lock,
                          color: Colors.white,
                          size: 17,
                        ))
                    : Container(
                        height: 5,
                        width: 5,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Color.fromARGB(255, 224, 35, 79),
                        ),
                        child: const Icon(
                          Icons.auto_stories_outlined,
                          color: Colors.white,
                          size: 17,
                        )),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
