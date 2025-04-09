import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AuthButton extends StatefulWidget {
  final String text;
  final Function()? onTap;

  const AuthButton({super.key, required this.text, required this.onTap});

  @override
  State<AuthButton> createState() => _AuthButtonState();
}

class _AuthButtonState extends State<AuthButton> {
  Color backgroundColor = Colors.white54;
  Color boundaryColor = Colors.red.shade400;
  Color txtColor = Colors.red.shade400;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 30),
      child: ClipRRect(
        borderRadius: const BorderRadius.all(Radius.circular(30)),
        child: Material(
          child: InkWell(
            highlightColor: Colors.orange.withOpacity(0.3),
            splashColor: Colors.red.withOpacity(0.5),
            onTap: callBtnAction,
            child: Ink(
              padding: const EdgeInsets.all(25),
              decoration: BoxDecoration(
                color: backgroundColor,
                borderRadius: const BorderRadius.all(Radius.circular(30)),
                border: Border.all(width: 2.5, color: boundaryColor),
              ),
              child: Center(
                child: Text(
                  widget.text,
                  style: TextStyle(
                      color: txtColor,
                      fontSize: 16,
                      fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  callBtnAction() {
    HapticFeedback.lightImpact();
    widget.onTap!();
  }
}
