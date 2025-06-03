import 'package:flutter/material.dart';
import 'package:dashbook/dashbook.dart';
import 'package:mangatracker/stories/component/Square_Title_story.dart';
import 'package:mangatracker/stories/component/auth_button_story.dart';
import 'package:mangatracker/stories/component/inpute_textfield_story.dart';
import 'package:mangatracker/stories/component/password_fields_strory.dart';
import 'package:mangatracker/stories/manga/manga_card_story.dart';
import 'package:mangatracker/stories/notifier/notifier_story.dart';



void main() {
  final dashbook = Dashbook();
  addAuthButtonStory(dashbook);
  addInputTextFieldStory(dashbook);
  addPasswordFieldsStory(dashbook);
  addNotifierServiceStory(dashbook);
  addSquareTileStory(dashbook);
  addMangaCardStory(dashbook);

  runApp(dashbook);
}
