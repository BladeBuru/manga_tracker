import 'package:flutter/material.dart';
import 'package:dashbook/dashbook.dart';
import 'package:mangatracker/stories/auth_button_story.dart';



void main() {
  final dashbook = Dashbook();
  addAuthButtonStory(dashbook);

  runApp(dashbook);
}
