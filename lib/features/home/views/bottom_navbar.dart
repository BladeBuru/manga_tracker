import 'home_page.dart';
import '../../profile/views/profile.dart';
import 'package:mangatracker/features/search/views/search.dart';
import 'package:flutter/material.dart';

import '../../library/views/library.view.dart';

class BottomNavbar extends StatefulWidget {
  const BottomNavbar({Key? key}) : super(key: key);

  @override
  State<BottomNavbar> createState() => BottomNavbarState();
}

class BottomNavbarState extends State<BottomNavbar> {
  final PageController pageCont = PageController(initialPage: 0);
  int currntIndex = 0;

  final Color selectedColor = const Color(0xffe0234f);
  final Color unselectedColor = const Color(0xffb8b8d2);

  @override
  void dispose() {
    pageCont.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: PageView(
        onPageChanged: (index) {
          setState(() => currntIndex = index);
        },
        controller: pageCont,
        children: const <Widget>[
          HomePage(),
          LibraryView(),
          Search(),
          Profile(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: currntIndex,
        onTap: (index) {
          setState(() {
            currntIndex = index;
          });
          pageCont.jumpToPage(currntIndex);
        },
        selectedFontSize: 15,
        selectedIconTheme: IconThemeData(color: selectedColor, size: 30),
        selectedItemColor: selectedColor,
        unselectedIconTheme: IconThemeData(
          color: unselectedColor,
        ),
        unselectedItemColor: unselectedColor,
        items: <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(
              Icons.home,
              color: currntIndex == 0 ? selectedColor : unselectedColor,
            ),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(
              Icons.book,
              color: currntIndex == 1 ? selectedColor : unselectedColor,
            ),
            label: 'Library',
          ),
          BottomNavigationBarItem(
            icon: Icon(
              Icons.search,
              color: currntIndex == 2 ? selectedColor : unselectedColor,
            ),
            label: 'Search',
          ),
          BottomNavigationBarItem(
            icon: Icon(
              Icons.person,
              color: currntIndex == 3 ? selectedColor : unselectedColor,
            ),
            label: 'Account',
          ),
        ],
      ),
    );
  }
}
