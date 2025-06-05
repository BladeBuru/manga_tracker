import 'package:dashbook/dashbook.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:mangatracker/core/components/welcome_header.dart';

void addWelcomeHeaderStory(Dashbook dashbook) {
  dashbook.storiesOf('Core/WelcomeHeader')
      .add('Avec nom d’utilisateur', (ctx) => Center(
    child: Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      width: 400,
      child: WelcomeHeader(username: 'Fabien'),
    ),
  ))
      .add('Sans nom', (ctx) => Center(
    child: Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      width: 400,
      child: const WelcomeHeader(username: null),
    ),
  ));
}
