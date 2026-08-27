import 'package:flutter/material.dart';
import 'package:dashbook/dashbook.dart';
import 'package:mangatracker/stories/component/auth_button_story.dart';
import 'package:mangatracker/stories/component/filter_button_story.dart';
import 'package:mangatracker/stories/component/inpute_textfield_story.dart';
import 'package:mangatracker/stories/component/password_fields_story.dart';
import 'package:mangatracker/stories/component/square_tile_story.dart';
import 'package:mangatracker/stories/manga/manga_row_story.dart';
import 'package:mangatracker/stories/manga/manga_card_story.dart';
import 'package:mangatracker/stories/notifier/notifier_story.dart';

import 'stories/welcom_header_story.dart';



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
