import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mangatracker/features/manga/helpers/detail_hero_layout.dart';

void main() {
  test('grand écran : 340 px comme avant', () {
    final hero = DetailHeroLayout.of(
      const MediaQueryData(size: Size(412, 915)),
    );
    expect(hero.height, 340);
    expect(hero.showChrome, isTrue);
  });

  test('petit téléphone : au plus 42 % de la hauteur', () {
    final hero = DetailHeroLayout.of(
      const MediaQueryData(size: Size(320, 568)),
    );
    expect(hero.height, closeTo(568 * 0.42, 0.01));
  });

  test("clavier ouvert : ni image ni barre d'actions", () {
    final hero = DetailHeroLayout.of(
      const MediaQueryData(
        size: Size(360, 640),
        viewInsets: EdgeInsets.only(bottom: 280),
      ),
    );
    expect(hero.showChrome, isFalse);
  });

  test("titre sous la barre d'état et la barre d'application", () {
    final hero = DetailHeroLayout.of(
      const MediaQueryData(
        size: Size(360, 780),
        padding: EdgeInsets.only(top: 48),
      ),
    );
    expect(hero.titleTop, greaterThanOrEqualTo(48 + kToolbarHeight));
  });
}
