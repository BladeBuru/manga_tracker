import 'package:flutter/material.dart';

class IntputTexteField extends StatelessWidget {
  final TextEditingController controller;
  final String textField;
  final bool obscureText;
  final String? Function(String?)? validator;

  const IntputTexteField(
      {super.key,
      required this.controller,
      required this.textField,
      required this.obscureText,
      required this.validator});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 30.0),
      child: TextFormField(
        controller: controller,
        obscureText: obscureText,
        decoration: InputDecoration(
          enabledBorder: const OutlineInputBorder(
              borderSide: BorderSide(color: Colors.white),
              borderRadius: BorderRadius.all(Radius.circular(10))),
          focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(color: Colors.grey.shade400),
              borderRadius: const BorderRadius.all(Radius.circular(10))),
          fillColor: Colors.grey[100],
          filled: true,
          hintText: textField,
          hintStyle: TextStyle(color: Colors.grey[400]),
          errorMaxLines: 3,
        ),
        validator: validator,
      ),
    );
  }
}
