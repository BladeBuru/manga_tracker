import 'package:flutter/material.dart';

class ErrorNotifier {
  void showErrorSnackBar(String errorMsg, BuildContext context) {
    var snackBar = SnackBar(
      behavior: SnackBarBehavior.floating,
      backgroundColor: Colors.transparent,
      elevation: 0,
      content: Container(
        padding: const EdgeInsets.all(16),
        decoration: const BoxDecoration(
          color: Color.fromARGB(255, 229, 40, 40),
          borderRadius: BorderRadius.all(Radius.circular(20)),
        ),
        child: Text(
          errorMsg,
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );

    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }
}
