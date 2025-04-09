import 'dart:math';

class UserHelper {
  static final callnames = <String>[
    'Handsome Human',
    'Mysterious User',
    'Breathtaking Rockstar',
    'Immortal Warrior',
    'Shadow Legend',
    'Light Guide',
    'Brave Soldier',
    'Intrepid Reader',
    'Wise Sensei',
    'Fearless Explorer',
    'Radiant Spirit',
    'Eternal Wanderer',
    'Enigmatic Trailblazer',
    'Joyful Voyager',
    'Infinite Optimist',
    'Heartwarming Enchanter',
    'Soulful Wonder',
    'Harmony Creator',
    'Unstoppable Delighter',
    'Smile Weaver',
    'Happiness Catalyst',
    'Jovial Magician',
    'Joyful Harmonist',
    'Cheerful Nomad'
  ];

  static String getRandomCallname() {
    int callnameIndex = Random().nextInt(callnames.length);
    return callnames[callnameIndex];
  }
}
