import 'package:flutter/material.dart';
import 'package:dashbook/dashbook.dart';
import 'package:mangatracker/stories/component/auth_button_story.dart';
import 'package:mangatracker/stories/component/password_fields_strory.dart';
import 'package:mangatracker/stories/errors/notifier_story.dart';



void main() {
  final dashbook = Dashbook();
  addAuthButtonStory(dashbook);
  addPasswordFieldsStory(dashbook);
  addNotifierServiceStory(dashbook);

  runApp(dashbook);
}
