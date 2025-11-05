import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mangatracker/l10n/app_localizations.dart';

class RowChapter extends StatelessWidget {
  final String line;
  final String chapter;
  final bool read;
  final num? readCount;
  final VoidCallback? onTap;
  final bool enabled;


  const RowChapter({
    super.key,
    required this.line,
    required this.chapter,
    required this.read,
    this.readCount,
    this.onTap,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: enabled ? 1.0 : 0.5,
      child: Padding(
        padding: const EdgeInsets.only(
            top: 7.0, bottom: 7.0, right: 10.0, left: 10.0),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              SizedBox(
                height: 50,
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
                  height: 50,
                  child: Align(
                    alignment: Alignment.topLeft,
                    child: Padding(
                      padding: const EdgeInsets.only(top: 15, left: 30),
                      child: Builder(
                        builder: (context) {
                          final l10n = AppLocalizations.of(context);
                          return Text('${l10n?.chapter ?? "Chapter"} $chapter');
                        },
                      ),
                    ),
                  ),
                ),
              ),
              SizedBox(
                height: 50,
                width: 50,
                child: Padding(
                  padding: const EdgeInsets.all(8),
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
      ),
    );
  }
}
