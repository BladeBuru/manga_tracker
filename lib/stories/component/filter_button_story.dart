import 'package:dashbook/dashbook.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../core/components/filter_button.dart';
void addFilterButtonStory(Dashbook dashbook) {
  dashbook.storiesOf('Components/FilterButton')
      .add('Sélectionné', (ctx) => Center(
    child: Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: FilterButton(
        label: 'Tous',
        selected: true,
        onPressed: () => debugPrint('Clicked Tous'),
      ),
    ),
  ))
      .add('Non-sélectionné', (ctx) => Center(
    child: Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: FilterButton(
        label: 'Populaires',
        selected: false,
        onPressed: () => debugPrint('Clicked Populaires'),
      ),
    ),
  ));
}
