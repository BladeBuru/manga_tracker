import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class RowChapter extends StatelessWidget {
  final String line;
  final String chapter;
  final bool read;
  final num? readCount;
  final VoidCallback? onTap;


  const RowChapter({
    super.key,
    required this.line,
    required this.chapter,
    required this.read,
    this.readCount,
    this.onTap,
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
                child: read
                    ? Container(
                        height: 5,
                        width: 5,
                        decoration:  BoxDecoration(
                          shape: BoxShape.circle,
                          color: Theme.of(context).colorScheme.primary.withAlpha(77)
                          ,
                        ),
                        child: const Icon(
                          Icons.check_box_outlined,
                          color: Colors.white,
                          size: 17,
                        ))
                    : Container(
                        height: 5,
                        width: 5,
                        decoration:  BoxDecoration(
                          shape: BoxShape.circle,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        child: const Icon(
                         Icons.check_box_outline_blank_outlined,
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
