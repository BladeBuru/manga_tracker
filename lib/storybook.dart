import 'package:flutter/material.dart';
import 'package:dashbook/dashbook.dart';
import 'package:mangatracker/stories/component/Square_Title_story.dart';
import 'package:mangatracker/stories/component/auth_button_story.dart';
import 'package:mangatracker/stories/component/filter_button_story.dart';
import 'package:mangatracker/stories/component/inpute_textfield_story.dart';
import 'package:mangatracker/stories/component/password_fields_strory.dart';
import 'package:mangatracker/stories/manga/Mang_row%20_story.dart';
import 'package:mangatracker/stories/manga/manga_card_story.dart';
import 'package:mangatracker/stories/notifier/notifier_story.dart';

import 'core/components/welcom_header_story.dart';



void main() {
  final dashbook = Dashbook();
  addAuthButtonStory(dashbook);
  addFilterButtonStory(dashbook);
  addWelcomeHeaderStory(dashbook);
  addInputTextFieldStory(dashbook);
  addPasswordFieldsStory(dashbook);
  addNotifierServiceStory(dashbook);
  addSquareTileStory(dashbook);
  addMangaCardStory(dashbook);
  addMangaRowStory(dashbook);

  runApp(dashbook);
}
