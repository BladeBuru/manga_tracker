import 'package:mangatracker/core/service_locator/service_locator.dart';
import 'package:mangatracker/features/auth/exceptions/invalid_credentials.exception.dart';
import 'package:mangatracker/features/home/widgets/homepage_manga_list.dart';
import 'package:mangatracker/features/profile/dto/user_information.dto.dart';
import 'package:mangatracker/features/profile/services/user.service.dart';

import '../../auth/services/auth.service.dart';
import '../../auth/views/login.view.dart';
import '../../manga/services/manga.service.dart';
import '../../manga/dto/manga_quick_view.dto.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../manga/widgets/manga_card.dart';
import '../../../core/errors/error_notifier.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final MangaService mangaService = getIt<MangaService>();
  final UserService userService = getIt<UserService>();
  final AuthService authService = getIt<AuthService>();
  final ErrorNotifier errorNotification = ErrorNotifier();
  String? displayUsername;
  bool hasAlreadyBeenRedirected = false;

  UserInformationDto? user;
  late Future<List<MangaQuickViewDto>> trendingMangas;
  late Future<List<MangaQuickViewDto>> popularMangas;
  late Future<List<MangaQuickViewDto>> newMangas;

  @override
  void initState() {
    super.initState();
    loadResources();
  }

  void loadResources() {
    trendingMangas = mangaService.getTrendingMangas().catchError((err) {
      _errorHandler();
      return List<MangaQuickViewDto>.empty();
    }, test: (err) => err is InvalidCredentialsException);

    popularMangas = mangaService.getPopularMangas().catchError((err) {
      _errorHandler();
      return List<MangaQuickViewDto>.empty();
    }, test: (err) => err is InvalidCredentialsException);

    newMangas = mangaService.getNewMangas().catchError((err) {
      _errorHandler();
      return List<MangaQuickViewDto>.empty();
    }, test: (err) => err is InvalidCredentialsException);

    userService.getUserInformation().then((value) {
      setState(() {
        user = value;
        displayUsername = value.username;
      });
    }).catchError((err) {
      _errorHandler();
    }, test: (err) => err is InvalidCredentialsException);
  }

  void _errorHandler() {
    if (!hasAlreadyBeenRedirected && context.mounted) {
      authService.logout();
      redirectToLoginPage();
      errorNotification.showErrorSnackBar('Expired session', context);
      setState(() {
        hasAlreadyBeenRedirected = true;
      });
    }
  }

  void redirectToLoginPage() {
    Navigator.push(
        context, MaterialPageRoute(builder: (context) => const LoginView()));
  }

  get border => null;

  final Color themePage = const Color(0xffe0234f);

  int indexButtonBar = 0;

  late Widget childWidget = HomepageMangaList(mangas: trendingMangas);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(25.0),
          child: Column(children: [
            //Espace
            const SizedBox(height: 20),

            //PP et Texte
            Row(
              children: [
                const CircleAvatar(
                  minRadius: 20.0,
                  maxRadius: 20.0,
                  backgroundImage: AssetImage('assets/images/mask_logo.png'),
                  backgroundColor: Colors.transparent,
                ),
                const SizedBox(width: 10),
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(
                    'Hello,',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                  AnimatedOpacity(
                    duration: const Duration(milliseconds: 800),
                    opacity: displayUsername == null ? 0.0 : 1.0,
                    child: Text(
                      displayUsername == null ? '' : displayUsername!,
                      textAlign: TextAlign.left,
                      style: GoogleFonts.poppins(
                        fontSize: 22,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xff1f1f39),
                      ),
                      key: ValueKey<String>(
                          displayUsername == null ? '' : displayUsername!),
                    ),
                  ),
                ])
              ],
            ),

            // Trending Mangas
            SizedBox(
              child: Row(
                children: [
                  const SizedBox(
                    height: 50,
                  ),
                  Text('Trending Manga',
                      style: GoogleFonts.poppins(
                          fontSize: 14.0,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xff1f1f39))),
                  const Spacer(),
                  const Icon(Icons.add_circle_outline)
                ],
              ),
            ),
            //Espace
            const SizedBox(height: 1),

            //Carousel
            SizedBox(
              height: 200,
              child: FutureBuilder<List<MangaQuickViewDto>>(
                future: trendingMangas,
                builder: (context, snapshot) {
                  if (snapshot.hasData) {
                    final mangaList = snapshot.data!;
                    return ListView.builder(
                      itemCount: mangaList.length,
                      scrollDirection: Axis.horizontal,
                      itemBuilder: (context, index) {
                        final manga = mangaList[index];
                        return MangaCard(
                            muId: manga.muId.toString(),
                            mangaTitle: manga.title,
                            mangaAuthor: manga.year.toString(),
                            largeImgPath: manga.largeCoverUrl,
                            rating: manga.rating);
                      },
                    );
                  } else if (snapshot.hasError) {
                    return Text('Error: ${snapshot.error}');
                  } else {
                    return const SizedBox(
                      height: 200.0,
                      width: 200.0,
                      child: Center(
                        child: CircularProgressIndicator(),
                      ),
                    );
                  }
                },
              ),
            ),
            SizedBox(
              height: 80,
              child: Row(
                children: [
                  ButtonBar(
                    children: [
                      ElevatedButton(
                          onPressed: () {
                            setState(() {
                              indexButtonBar = 0;
                              loadChildWidget(indexButtonBar);
                            });
                          },
                          style: ButtonStyle(
                            backgroundColor: indexButtonBar == 0
                                ? MaterialStateProperty.all<Color>(themePage)
                                : MaterialStateProperty.all<Color>(
                                    Colors.white),
                            shape: MaterialStateProperty.all<
                                RoundedRectangleBorder>(RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                  18.0), // changer la forme du bouton
                            )),
                          ),
                          child: indexButtonBar == 0
                              ? const Text('All',
                                  style: TextStyle(color: Colors.white))
                              : const Text('All',
                                  style: TextStyle(color: Color(0xff858597)))),
                      ElevatedButton(
                          onPressed: () {
                            setState(() {
                              indexButtonBar = 1;
                              loadChildWidget(indexButtonBar);
                            });
                          },
                          style: ButtonStyle(
                            backgroundColor: indexButtonBar == 1
                                ? MaterialStateProperty.all<Color>(themePage)
                                : MaterialStateProperty.all<Color>(
                                    Colors.white),
                            shape: MaterialStateProperty.all<
                                RoundedRectangleBorder>(RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                  18.0), // changer la forme du bouton
                            )),
                          ),
                          child: indexButtonBar == 1
                              ? const Text('Popular',
                                  style: TextStyle(color: Colors.white))
                              : const Text('Popular',
                                  style: TextStyle(color: Color(0xff858597)))),
                      ElevatedButton(
                          onPressed: () {
                            setState(() {
                              indexButtonBar = 2;
                              loadChildWidget(indexButtonBar);
                            });
                          },
                          style: ButtonStyle(
                            backgroundColor: indexButtonBar == 2
                                ? MaterialStateProperty.all<Color>(themePage)
                                : MaterialStateProperty.all<Color>(
                                    Colors.white),
                            shape: MaterialStateProperty.all<
                                RoundedRectangleBorder>(RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                  18.0), // changer la forme du bouton
                            )),
                          ),
                          child: indexButtonBar == 2
                              ? const Text('New',
                                  style: TextStyle(color: Colors.white))
                              : const Text('New',
                                  style: TextStyle(color: Color(0xff858597)))),
                    ],
                  )
                ],
              ),
            ),
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 290,
                    child: childWidget,
                  ),
                ),
              ],
            )
          ]),
        ),
      ),
    );
  }

  loadChildWidget(indexButtonBar) {
    if (indexButtonBar == 0) {
      childWidget = HomepageMangaList(mangas: trendingMangas);
    } else if (indexButtonBar == 1) {
      childWidget = HomepageMangaList(mangas: popularMangas);
    } else if (indexButtonBar == 2) {
      childWidget = HomepageMangaList(mangas: newMangas);
    } else {
      childWidget =
          const Text('Sorry, we\'re currently unable to load this section :/');
    }
  }
}
